import 'dart:isolate';
import 'dart:io';
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class PredictionService {
  static final PredictionService _instance = PredictionService._internal();
  factory PredictionService() => _instance;
  PredictionService._internal();

  Interpreter? _interpreter;

  Future<void> loadModel() async {
    try {
      _interpreter ??= await Interpreter.fromAsset('assets/plant_disease_model.tflite');
      debugPrint('Model loaded successfully');
    } catch (e) {
      debugPrint('Error loading model: $e');
    }
  }

  Future<Map<String, dynamic>> predict(XFile imageFile) async {
    if (_interpreter == null) {
      await loadModel();
      if (_interpreter == null) return <String, dynamic>{'index': 0, 'confidence': 0.0};
    }

    final Uint8List imageBytes = await imageFile.readAsBytes();
    final receivePort = ReceivePort();

    try {
      await Isolate.spawn(
        _isolateEntryPoint,
        {
          'sendPort': receivePort.sendPort,
          'interpreterAddress': _interpreter!.address,
          'imageBytes': imageBytes,
        },
      );

      final result = await receivePort.first as Map<String, dynamic>;
      return result;
    } catch (e) {
      debugPrint('Isolate spawn error: $e');
      return <String, dynamic>{'index': 0, 'confidence': 0.0};
    } finally {
      receivePort.close();
    }
  }

  Future<Map<String, dynamic>> predictImage(File image) async {
    debugPrint('--- Prediction Started ---');

    final output = await predict(XFile(image.path));

    if (output.isEmpty) {
      debugPrint('Prediction result is NULL. Check model loading!');
    } else {
      debugPrint('Result: $output');
    }

    return output;
  }

  static void _isolateEntryPoint(Map<String, dynamic> params) {
    final sendPort = params['sendPort'] as SendPort;
    try {
      final interpreter = Interpreter.fromAddress(params['interpreterAddress']);
      final imageBytes = params['imageBytes'] as Uint8List;
      final input = preprocessImage(imageBytes);
      final output = List.filled(1 * 6, 0.0).reshape([1, 6]);

      interpreter.run(input, output);

      final probabilities = List<double>.from(output[0]);
      var maxConfidence = -1.0;
      var maxIndex = 0;

      for (var i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxConfidence) {
          maxConfidence = probabilities[i];
          maxIndex = i;
        }
      }

      Isolate.exit(sendPort, <String, dynamic>{
        'index': maxIndex,
        'confidence': maxConfidence,
        'predictions': probabilities,
      });
    } catch (e) {
      debugPrint('Isolate prediction error: $e');
      Isolate.exit(sendPort, <String, dynamic>{'index': 0, 'confidence': 0.0});
    }
  }

  static List<List<List<List<double>>>> preprocessImage(Uint8List imageBytes) {
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Could not decode image');

    final resizedImage = img.copyResize(image, width: 224, height: 224);

    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (_) => List.generate(
          224,
          (_) => List.generate(3, (_) => 0.0),
        ),
      ),
    );

    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        final pixel = resizedImage.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }

    return input;
  }

  void dispose() {
    _interpreter?.close();
  }
}

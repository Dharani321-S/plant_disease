import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class PredictionService {
  late Interpreter _interpreter;

  // 🔹 Idhu kandippa irukanum, app-ah start pannum podhu idhai call pannanum
  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/plant_disease_model.tflite');
  }

  Future<int> predict(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(bytes);
      if (originalImage == null) throw Exception("Unable to decode image");

      img.Image resizedImage = img.copyResize(originalImage, width: 224, height: 224);

      var input = List.generate(1, (batch) => List.generate(224, (y) => List.generate(224, (x) {
        final pixel = resizedImage.getPixel(x, y);
        return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
      })));

      var output = List.generate(1, (index) => List.filled(5, 0.0));
      _interpreter.run(input, output);
      
      debugPrint("📊 Raw Output: ${output[0]}");

      double maxScore = -1.0;
      int predictedIndex = 0;
      for (int i = 0; i < output[0].length; i++) {
        if (output[0][i] > maxScore) {
          maxScore = output[0][i];
          predictedIndex = i;
        }
      }
      return predictedIndex;
    } catch (e) {
      debugPrint("❌ CNN Error: $e");
      return -1;
    }
  }

  void dispose() {}
}
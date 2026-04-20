import 'dart:io';
import 'package:tflite_v2/tflite_v2.dart';

class PredictionService {
  static Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/plant_disease_model_final.tflite",
      labels: "assets/labels.txt",
    );
  }

  static Future<List?> predictImage(File image) async {
    var result = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 6,
      threshold: 0.1,
    );
    return result;
  }
}
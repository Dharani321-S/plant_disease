import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class PredictionService {
  Future<void> loadModel() async {
    debugPrint('Prediction model is not loaded on web: tflite_flutter uses dart:ffi.');
  }

  Future<Map<String, dynamic>> predict(XFile imageFile) async {
    debugPrint('Prediction skipped on web for ${imageFile.name}.');
    return <String, dynamic>{'index': 0, 'confidence': 0.0};
  }

  void dispose() {}
}

import 'package:image_picker/image_picker.dart';

class PredictionService {
  Future<void> loadModel() async {}

  Future<Map<String, dynamic>> predict(XFile imageFile) async {
    return <String, dynamic>{'index': 0, 'confidence': 0.0};
  }

  void dispose() {}
}

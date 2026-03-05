import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class PredictionService {
  late Interpreter _interpreter;

  // 🔹 Load TFLite Model
  Future<void> loadModel() async {
    _interpreter =
        await Interpreter.fromAsset('assets/plant_disease_model.tflite');
  }

  // 🔹 Run Prediction
  Future<int> predict(File imageFile) async {
    // 1️⃣ Read image bytes
    final bytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception("Unable to decode image");
    }

    // 2️⃣ Resize image (CHANGE SIZE if your model is not 224x224)
    img.Image resizedImage =
        img.copyResize(originalImage, width: 224, height: 224);

    // 3️⃣ Convert image to input tensor (1, 224, 224, 3)
    var input = List.generate(
      1,
      (index) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            var pixel = resizedImage.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    // 4️⃣ Output tensor (CHANGE 38 if your class count is different)
    var output = List.generate(1, (index) => List.filled(38, 0.0));

    // 5️⃣ Run model
    _interpreter.run(input, output);

    // 6️⃣ Get highest probability index
    int predictedIndex =
        output[0].indexOf(output[0].reduce((a, b) => a > b ? a : b));

    return predictedIndex;
  }
}
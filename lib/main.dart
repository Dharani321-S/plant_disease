// Flutter core
import 'dart:io'; // 👈 This is the missing piece!
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Packages
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Local files
import 'prediction_service.dart';
// make sure this file exists

void main() {
  runApp(const PlantDiseaseApp());
}

class PlantDiseaseApp extends StatelessWidget {
  const PlantDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plant Disease Detector',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const SplashScreen(),
    );
  }
}

/* ---------------- SPLASH SCREEN ---------------- */

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.lightGreen],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Plant Disease AI",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- LOGIN PAGE ---------------- */



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController pinController = TextEditingController();
  late String savedPin;

  @override
  void initState() {
    super.initState();
    loadPin();
    fingerprintAuth();
  }

  // Load saved PIN from SharedPreferences
  Future<void> loadPin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    savedPin = prefs.getString('user_pin') ?? "1234"; // default PIN
  }

  // Fingerprint authentication
  Future<void> fingerprintAuth() async {
    try {
      bool canCheck = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();

      if (canCheck && isSupported) {
        bool success = await auth.authenticate(
          localizedReason: 'Authenticate to access Plant Disease App',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );
        if (success) goHome();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Biometric authentication failed")),
      );
    }
  }

  // PIN verification
  void verifyPin() {
    if (pinController.text == savedPin) {
      goHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect PIN")),
      );
    }
  }

  void goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "Unlock Plant Disease App",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter 4-digit PIN",
                hintStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.greenAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                counterText: "",
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: verifyPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "Unlock",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: fingerprintAuth,
              child: const Text(
                "Use Fingerprint",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- SCAN PAGE (CAMERA + GALLERY) ---------------- */

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  XFile? image; // ✅ declare properly
  final ImagePicker picker = ImagePicker();

  Future<void> pickFromCamera() async {
    final XFile? picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        image = XFile(picked.path);
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultPage(image: image!)),
      );
    }
  }

  Future<void> pickFromGallery() async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        image = XFile(picked.path);
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultPage(image: image!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Scan Plant Leaf",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 25),

                Container(
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(image!.path, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image, size: 100, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("No image selected"),
                          ],
                        ),
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Capture from Camera"),
                    onPressed: pickFromCamera,
                  ),
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo),
                    label: const Text("Select from Gallery"),
                    onPressed: pickFromGallery,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ResultPage extends StatefulWidget {
  final XFile image;

  const ResultPage({super.key, required this.image});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

// FIX 1: Changed 'on State' to 'extends State'
class _ResultPageState extends State<ResultPage> {
  PredictionService predictionService = PredictionService();
  late final FlutterTts flutterTts;

  final List<String> diseaseLabels = [
    "tomato_early_blight",
    "tomato_late_blight",
    "potato_early_blight",
    "potato_late_blight",
    "healthy"
  ];



  // FIX 2: Initialized with default values to prevent LateInitializationError
  String diseaseName = "கணக்கிடப்படுகிறது...";
  String treatmentText = "காத்திருக்கவும்...";
  bool isLoaded = false;
  late String predicted;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    predictionService.loadModel().then((_) {
    runPrediction();
  });

    initTTS();
  }

  Future<void> initTTS() async {
    await flutterTts.setLanguage("ta-IN");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.45);

    speakTamil();
  }
  Future<void> runPrediction() async {
  File imageFile = File(widget.image.path);

  int index = await predictionService.predict(imageFile);

  debugPrint("Prediction index: $index");
  
  if (mounted) {
    setState(() {
      predicted = diseaseLabels[index];
      diseaseName = diseaseData[predicted]!["name"]!;
      treatmentText = diseaseData[predicted]!["treatment"]!;
      isLoaded = true;
    });
  }
}

Future<void> speakTamil() async {
  if (isLoaded) {
    await flutterTts.speak("உங்கள் செடியில் $diseaseName நோய் உள்ளது. $treatmentText");
  }
}

@override
void dispose() {
  flutterTts.stop();
  super.dispose();
}

final Map<String, Map<String, String>> diseaseData = {
  "tomato_early_blight": {
    "name": "Tomato Early Blight",
    "treatment":
        "தக்காளி ஆரம்ப கரும்புள்ளி. Mancozeb அல்லது Chlorothalonil பூஞ்சைநாசினி தெளிக்கவும்."
  },
  "tomato_late_blight": {
    "name": "Tomato Late Blight",
    "treatment":
        "தக்காளி Late Blight. பாதிக்கப்பட்ட இலைகளை அகற்றி Metalaxyl தெளிக்கவும்."
  },
  "potato_early_blight": {
    "name": "Potato Early Blight",
    "treatment":
        "உருளைக்கிழங்கு Early Blight. Mancozeb அல்லது Copper fungicide தெளிக்கவும்."
  },
  "potato_late_blight": {
    "name": "Potato Late Blight",
    "treatment":
        "உருளைக்கிழங்கு Late Blight. Metalaxyl அல்லது Ridomil பயன்படுத்தவும்."
  },
  "healthy": {
    "name": "Healthy Leaf",
    "treatment":
        "இலை ஆரோக்கியமாக உள்ளது. வழக்கமான நீர்ப்பாசனம் மற்றும் உரம் பயன்படுத்தவும்."
  },
};  @override
  Widget build(BuildContext context) {
    double confidenceValue = 70;
    Color severityColor = getSeverityColor(confidenceValue);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Result & Treatment"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FIX 3: Handling Web vs Mobile Image display
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: kIsWeb
                  ? Image.network(
                      widget.image.path,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(widget.image.path),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 20),

            Text(
              "நோய்: $diseaseName",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Text(
              "நம்பகத்தன்மை: ${confidenceValue.toStringAsFixed(1)}%",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: severityColor, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: severityColor,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "பாதிப்பு நிலை: ${getSeverityTamil(confidenceValue)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  treatmentText,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4, // FIX 4: Changed 'lineHeight' to 'height'
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.volume_up, color: Colors.white),
              label: const Text(
                "குரலில் கேட்க",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: isLoaded ? speakTamil : null,
            ),
          ],
        ),
      ),
    );
  }
}

// --- HELPER FUNCTIONS ---

String getSeverityTamil(double confidence) {
  if (confidence >= 80) return "அதிக பாதிப்பு";
  if (confidence >= 50) return "மிதமான பாதிப்பு";
  return "குறைந்த பாதிப்பு";
}

Color getSeverityColor(double confidence) {
  if (confidence >= 80) return Colors.red;
  if (confidence >= 50) return Colors.orange;
  return Colors.green;
}

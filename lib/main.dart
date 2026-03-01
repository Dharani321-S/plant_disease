// Flutter core
import 'package:flutter/material.dart';

// Packages
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Local files
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
  const LoginPage({super.key}); // ⭐ Add this

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication auth = LocalAuthentication();
  final TextEditingController pinController = TextEditingController();
  String savedPin = "1234"; // default PIN

  @override
  void initState() {
    super.initState();
    loadPin();
    fingerprintAuth();
  }

  Future<void> loadPin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    savedPin = prefs.getString('user_pin') ?? "1234";
  }

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

      ("Fingerprint error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Biometric authentication failed")),
      );
    }
  }

  void verifyPin() {
    if (pinController.text == savedPin) {
      goHome();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Incorrect PIN")));
    }
  }

  void goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
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
            Icon(Icons.fingerprint, size: 100, color: Colors.green),
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

/* ---------------- HOME PAGE + MENU ---------------- */

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // dark theme
      appBar: AppBar(
        title: const Text("Plant Disease Detector"),
        backgroundColor: Colors.green, // green accent
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.black, // match dark theme
          child: ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.green),
                child: Text(
                  "Menu",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text(
                  "Scan Plant",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ScanPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.green),
                title: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  // Go back to login page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: const Center(
        child: Text(
          "Welcome 🌿\nUse menu to scan plant",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.green, // green text accent
            fontWeight: FontWeight.bold,
          ),
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

class _ResultPageState extends State<ResultPage> {
  final FlutterTts flutterTts = FlutterTts();

  late String diseaseName;
  late String treatmentText;

  // 🧠 Simple Prediction Logic (Temporary AI)
  String predictDisease(String path) {
    String lowerPath = path.toLowerCase();

    if (lowerPath.contains("banana")) {
      return "banana_leaf_spot";
    } else if (lowerPath.contains("tomato")) {
      return "tomato_leaf_blight";
    } else {
      return "unknown";
    }
  }

  // 💊 Treatment Map
  Map<String, Map<String, String>> diseaseData = {
    "banana_leaf_spot": {
      "name": "Banana Leaf Spot",
      "treatment":
          "வாழை இலை புள்ளி நோய் உள்ளது. பாதிக்கப்பட்ட இலைகளை அகற்றவும். பூஞ்சைநாசினி மருந்தை வாரத்திற்கு ஒரு முறை தெளிக்கவும்.",
    },
    "tomato_leaf_blight": {
      "name": "Tomato Leaf Blight",
      "treatment":
          "தக்காளி இலை கருகல் நோய் உள்ளது. Mancozeb போன்ற மருந்து பயன்படுத்தவும். அதிக நீர் பாய்ச்சுவதை தவிர்க்கவும்.",
    },
    "unknown": {
      "name": "Unknown Disease",
      "treatment":
          "நோய் சரியாக கண்டறிய முடியவில்லை. அருகிலுள்ள வேளாண்மை அலுவலகத்தை அணுகவும்.",
    },
  };

  @override
  void initState() {
    super.initState();

    flutterTts.setLanguage("ta-IN");
    flutterTts.setSpeechRate(0.45);

    String predicted = predictDisease(widget.image.path);

    diseaseName = diseaseData[predicted]!["name"]!;
    treatmentText = diseaseData[predicted]!["treatment"]!;

    speakTamil(); // 🔊 Auto speak when page opens
  }

  Future<void> speakTamil() async {
    await flutterTts.speak(treatmentText);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Result & Treatment"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.image.path,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 25),

            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Disease Detected: $diseaseName",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  treatmentText,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.volume_up),
              label: const Text("குரலில் கேட்க"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: speakTamil,
            ),
          ],
        ),
      ),
    );
  }
}

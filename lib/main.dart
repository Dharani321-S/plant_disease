import 'dart:io';
// ignore: unused_import
import 'dart:isolate';
import 'dart:ui';

// Packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:plant_disease/databasehelper.dart';
import 'package:plant_disease/language_data.dart'; 
import 'package:plant_disease/crop_schedule_page.dart';

import 'package:plant_disease/prediction_service.dart';
import 'package:plant_disease/weather_risk_service.dart';

// common constants and decorations
const LinearGradient kBackgroundGradient = LinearGradient(
  colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const BoxShadow kSoftShadow = BoxShadow(
  color: Colors.black26,
  blurRadius: 15,
  offset: Offset(0, 8),
);

/// A reusable glassmorphic card container with blur and soft shadow.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(30)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: const [kSoftShadow],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.12),
              borderRadius: borderRadius,
              // ignore: deprecated_member_use
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}





// 1. Top-level function for isolate - இது கிளாஸிற்கு வெளியே இருக்க வேண்டும்
// ignore: unused_element
Future<Map<String, dynamic>> _runPredictionInIsolate(String imagePath) async {
  await PredictionService.loadModel();
  final result = await PredictionService().predict(File(imagePath) as XFile);
  PredictionService().dispose(); 
  return result;
}

void main() {
  runApp(const PlantDiseaseApp());
}


class PlantDiseaseApp extends StatelessWidget {
  const PlantDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plant Disease Detection',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const LoginPage(),
    );
  }
}

/* ---------------- SPLASH SCREEN ---------------- */
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Fade-in animation controller
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Navigator.pushReplacement inside a clean logic
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: kBackgroundGradient,),
        child: FadeTransition(
          opacity: _animation,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glassmorphic Icon Container
              GlassCard(
                padding: EdgeInsets.all(25),
                child: Icon(Icons.eco_rounded, size: 80, color: Colors.white),
              ),
              SizedBox(height: 30),
              // Dynamic Title with Professional Typography
              Text(
                "Plant Disease AI",
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              SizedBox(height: 10),
              Text(
                "Your Expert in Plant Health",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // AnimationController dispose check
    super.dispose();
  }
}

/* ---------------- LOGIN PAGE ---------------- */
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController pinController;
  final LocalAuthentication auth = LocalAuthentication();
  bool _isBiometricAvailable = false;
  bool _isFirstTimeUser = true;

  @override
  void initState() {
    super.initState();
    pinController = TextEditingController();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool canCheck = await auth.canCheckBiometrics;
    setState(() {
      _isBiometricAvailable = canCheck;
      _isFirstTimeUser = prefs.getString('user_pin') == null;
    });
  }

  void loginSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ScanPage()),
    );
  }

  void handlePinAction() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isFirstTimeUser) {
      if (pinController.text.length == 4) {
        await prefs.setString('user_pin', pinController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN Set Successfully!"), backgroundColor: Colors.green));
        setState(() => _isFirstTimeUser = false);
        pinController.clear();
      } else {
        _showError("Please enter a 4-digit PIN");
      }
    } else {
      String? savedPin = prefs.getString('user_pin');
      if (pinController.text == savedPin) {
        if (!mounted) return;
        loginSuccess();
      } else {
        _showError("Incorrect PIN!");
        pinController.clear();
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  Future<void> fingerprintAuth() async {
  try {
    // The `options` parameter is not required on Android and
    // passing `biometricOnly` can trigger a PlatformException
    // on devices without biometrics. Use the simple form instead.
    bool authenticated = await auth.authenticate(
      localizedReason: 'Scan fingerprint to unlock',
    );

    if (authenticated && mounted) {
      loginSuccess();
    }
  } catch (e) {
    _showError("Authentication error: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 120),
            child: Column(
              children: [
                const Icon(Icons.security_rounded, size: 80, color: Colors.white),
                const SizedBox(height: 30),
                Text(_isFirstTimeUser ? "Set Your Secret PIN" : "Enter PIN to Unlock", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 50),
                _buildPinField(),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton(
                    onPressed: handlePinAction,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF1B5E20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: Text(_isFirstTimeUser ? "SET PIN" : "UNLOCK", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (!_isFirstTimeUser && _isBiometricAvailable) ...[
                   const SizedBox(height: 20),
                   IconButton(icon: const Icon(Icons.fingerprint, size: 50, color: Colors.white), onPressed: fingerprintAuth),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        // ignore: deprecated_member_use
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: TextField(
        controller: pinController,
        keyboardType: TextInputType.number,
        obscureText: true,
        inputFormatters: [LengthLimitingTextInputFormatter(4)],
        maxLength: 4,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 32, letterSpacing: 20),
        decoration: const InputDecoration(border: InputBorder.none, counterText: ""),
      ),
    );
  }
}


/* ---------------- SCAN PAGE ---------------- */
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ImagePicker picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 95, // Image details clarity-kaaga
      maxWidth: 1000,   // Model-ku anuppum munnadi details miss aagama irukka
    );
    if (picked != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: LanguageData.currentLang == "ta" ? 'இலையை மட்டும் செதுக்கவும்' : 'Crop Plant Leaf',
            toolbarColor: const Color(0xFF1B5E20),
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
        ],
      );

      if (croppedFile != null && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ResultPage(image: XFile(croppedFile.path))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(LanguageData.getText('app_title'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => setState(() => LanguageData.currentLang = (LanguageData.currentLang == "ta") ? "en" : "ta"),
            child: Text(LanguageData.currentLang == "ta" ? "English" : "தமிழ்", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 140),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                LanguageData.getText('scan_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const Spacer(),
            
            // Schedule Button
            _buildScheduleButton(context),
            
            const SizedBox(height: 25),
            
            // Cards Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModernCard(LanguageData.getText('camera'), Icons.camera_enhance_rounded, () => pickImage(ImageSource.camera)),
                _buildModernCard(LanguageData.getText('gallery'), Icons.photo_library_rounded, () => pickImage(ImageSource.gallery)),
              ],
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            kSoftShadow,
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: 160, // Adjusted width for better fit
              height: 185,
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
                // ignore: deprecated_member_use
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    // ignore: deprecated_member_use
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, size: 45, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropSchedulePage())),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(25),
            // ignore: deprecated_member_use
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded, color: Colors.white),
              const SizedBox(width: 15),
              Text(LanguageData.getText('crop_schedule'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------------- HISTORY SCREEN ---------------- */
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await DatabaseHelper.instance.queryAllHistory();
    setState(() => history = data);
  }

  @override
  Widget build(BuildContext context) {
    bool isTa = LanguageData.currentLang == "ta";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(LanguageData.getText('history'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: history.isEmpty
            ? Center(
                child: Text(isTa ? "வரலாறு எதுவும் இல்லை" : "No history found",
                    style: const TextStyle(color: Colors.white70, fontSize: 18)))
            : ListView.builder(
                padding: const EdgeInsets.only(top: 120, left: 20, right: 20, bottom: 20),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final item = history[index];
                  return _buildHistoryCard(item);
                },
              ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    // Safety Checks: Null values-ai handle panna variables
    String diseaseName = (item['disease_name'] ?? "Unknown").toString();
    String date = (item['date'] ?? "Unknown Date").toString();
    String imagePath = (item['imagePath'] ?? "").toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              // ignore: deprecated_member_use
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                // 1. Image Preview with Null/Empty Check
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: imagePath.isNotEmpty && File(imagePath).existsSync()
                      ? Image.file(File(imagePath), width: 80, height: 80, fit: BoxFit.cover)
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.white10,
                          child: const Icon(Icons.image_not_supported, color: Colors.white38),
                        ),
                ),
                const SizedBox(width: 15),

                // 2. Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diseaseName,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.white70, size: 14),
                          const SizedBox(width: 5),
                          Text(date,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. Delete Action
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
                    await DatabaseHelper.instance.deleteHistory(item['id']);
                    _loadHistory();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ---------------- RESULT PAGE ---------------- */


class ResultPage extends StatefulWidget {
  final XFile image;
  const ResultPage({super.key, required this.image});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late FlutterTts flutterTts;
  String diseaseName = "கணக்கிடப்படுகிறது...";
  String treatmentText = "காத்திருக்கவும்...";
  bool isLoaded = false;
  String predictedKey = "";
  double currentHumidity = 60.0;
  double confidenceScore = 0.0;
  String loadingMessage = "படத்தை ஏற்றுகிறது...";

  // 1. Updated Label List (Exactly matching your labels.txt)
  final List<String> diseaseLabels = [
    "Potato___Early_blight",
    "Potato___Late_blight",
    "Potato___healthy",
    "Tomato_Early_blight",
    "Tomato_Late_blight",
    "Tomato___healthy"
  ];

  // 2. Updated Data Map with all 6 classes
  final Map<String, Map<String, String>> diseaseData = {
    "Potato___Early_blight": {
      "name": "உருளை ஆரம்பக்கால கருகல்",
      "name_en": "Potato Early Blight",
      "severity": "Medium",
      "severity_en": "Medium",
      "treatment": "• பயிர் சுழற்சி முறையைப் பின்பற்றவும்.\n• பாதிக்கப்பட்ட இலைகளை அகற்றவும்.",
      "treatment_en": "• Follow crop rotation.\n• Remove infected leaves."
    },
    "Potato___Late_blight": {
      "name": "உருளை பிற்கால கருகல்",
      "name_en": "Potato Late Blight",
      "severity": "High",
      "severity_en": "High",
      "treatment": "• செம்பு பூஞ்சைக் கொல்லிகளைப் பயன்படுத்தவும்.\n• செடிகளுக்கு இடையே காற்று ஓட்டத்தை அதிகரிக்கவும்.",
      "treatment_en": "• Use copper fungicides.\n• Increase air circulation between plants."
    },
    "Potato___healthy": {
      "name": "ஆரோக்கியமான உருளை",
      "name_en": "Healthy Potato",
      "severity": "None",
      "severity_en": "None",
      "treatment": "• செடி ஆரோக்கியமாக உள்ளது. இயற்கை உரமிட்டு தொடர்ந்து பராமரிக்கவும்.",
      "treatment_en": "• Plant is healthy. Continue maintenance with organic fertilizers."
    },
    "Tomato_Early_blight": {
      "name": "தக்காளி முன் கருகல்",
      "name_en": "Tomato Early Blight",
      "severity": "Low",
      "severity_en": "Low",
      "treatment": "• செடியின் அடிப்பகுதியில் நீர் பாய்ச்சவும்.\n• பாதிக்கப்பட்ட கிளைகளை கத்தரிக்கவும்.",
      "treatment_en": "• Water at the base of the plant.\n• Prune infected branches."
    },
    "Tomato_Late_blight": {
      "name": "தக்காளி பின் கருகல்",
      "name_en": "Tomato Late Blight",
      "severity": "High",
      "severity_en": "High",
      "treatment": "• மேன்கோசெப் மருந்தைப் பயன்படுத்தவும்.\n• ஈரப்பதம் அதிகம் உள்ள போது கவனமாக இருக்கவும்.",
      "treatment_en": "• Use Mancozeb fungicide.\n• Be careful during high humidity."
    },
    "Tomato___healthy": {
      "name": "ஆரோக்கியமான தக்காளி",
      "name_en": "Healthy Tomato",
      "severity": "None",
      "severity_en": "None",
      "treatment": "• தக்காளி செடி நன்றாக வளர்ந்து வருகிறது.\n• போதுமான சூரிய ஒளி கிடைப்பதை உறுதி செய்யவும்.",
      "treatment_en": "• Tomato plant is growing well.\n• Ensure adequate sunlight."
    },
  };

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    initTTS();
    runPrediction();
  }

  Future<void> initTTS() async {
    // LanguageData.currentLang-ai use panni TTS language set pannukirom
    await flutterTts.setLanguage(LanguageData.currentLang == "ta" ? "ta-IN" : "en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> runPrediction() async {
    try {
      debugPrint("--- Prediction Started ---");
      setState(() => loadingMessage = "படத்தை செயலாக்குகிறது...");

      // PredictionService call panni results edukkirom
      final result = await PredictionService().predict(widget.image);

      if (mounted) {
        setState(() {
          confidenceScore = result['confidence'];
          
          // Accuracy 80% kuraivaa irunthaal reject panrom
          if (confidenceScore < 0.80) {
            predictedKey = "Low confidence";
            diseaseName = LanguageData.currentLang == "ta" ? "இலை கண்டறியப்படவில்லை" : "Leaf Not Detected";
            treatmentText = LanguageData.currentLang == "ta"
                ? "தயவுசெய்து செடியின் இலையை தெளிவாக படம் எடுக்கவும்."
                : "Please take a clear photo of a plant leaf.";
          } else {
            // Service-la irunthu vara label-ai direct-ah match panrom
            predictedKey = result['label'];
            var data = diseaseData[predictedKey] ?? diseaseData["Potato___healthy"]!;
            
            bool isTa = LanguageData.currentLang == "ta";
            diseaseName = data[isTa ? "name" : "name_en"]!;
            treatmentText = data[isTa ? "treatment" : "treatment_en"]!;
          }
          isLoaded = true;
        });

        // Good accuracy result-ai mattum save panrom
        if (confidenceScore >= 0.80 && predictedKey != "Low confidence") {
          await DatabaseHelper.instance.insertHistory(widget.image.path, diseaseName, treatmentText);
        }
        
        speakWithRisk();
      }
    } catch (e) {
      debugPrint("❌ Prediction Error: $e");
      setState(() {
        diseaseName = "Error";
        isLoaded = true;
      });
    }
  }

  Future<void> speakWithRisk() async {
    // Custom check for low confidence
    if (predictedKey == "Low confidence") {
      await flutterTts.speak(treatmentText);
      return;
    }
    
    String risk = WeatherRiskService.getRiskMessage(currentHumidity, predictedKey, LanguageData.currentLang);
    await flutterTts.speak("$diseaseName. $risk. $treatmentText");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(LanguageData.getText('result')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoaded 
            ? buildContent() 
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    Text(loadingMessage, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget buildSeverityBadge() {
    String severity = diseaseData[predictedKey]?['severity_en'] ?? "None";
    Color badgeColor;

    if (severity == "High") {
      badgeColor = Colors.redAccent;
    } else if (severity == "Medium") {
      badgeColor = Colors.orangeAccent;
    } else {
      badgeColor = Colors.lightBlueAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1.5),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget buildContent() {
    bool isTa = LanguageData.currentLang == "ta";

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 110),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.file(
                File(widget.image.path),
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
              // ignore: deprecated_member_use
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        diseaseName,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (predictedKey != "Low confidence")
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          buildSeverityBadge(),
                          const SizedBox(height: 8),
                          Text(
                            "${(confidenceScore * 100).toStringAsFixed(1)}% Accuracy",
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white24, thickness: 1),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Icon(Icons.water_drop, color: Colors.white70, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      "${isTa ? 'ஈரப்பதம்' : 'Humidity'}: ${currentHumidity.toInt()}%",
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Slider(
                  value: currentHumidity,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                  min: 0,
                  max: 100,
                  onChanged: (val) => setState(() => currentHumidity = val),
                ),
                const SizedBox(height: 15),
                Text(
                  isTa ? "பரிந்துரைக்கப்படும் தீர்வு:" : "Recommended Treatment:",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  treatmentText,
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: speakWithRisk,
              icon: const Icon(Icons.volume_up_rounded, size: 28),
              label: Text(
                LanguageData.getText('speak'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1B5E20),
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}

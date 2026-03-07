// Flutter core
// ignore_for_file: duplicate_ignore, deprecated_member_use

import 'dart:io';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

// Packages
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project Files
import 'package:plant_disease/databasehelper.dart';
import 'package:plant_disease/language_data.dart';         
import 'package:plant_disease/crop_schedule_page.dart';
import 'package:plant_disease/prediction_service.dart';

import 'weather_risk_service.dart';

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
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController pinController;
  final LocalAuthentication auth = LocalAuthentication();
  bool _isBiometricAvailable = false;
  bool _isFirstTimeUser = true; // 👈 PIN set pannirukkara-nu check panna

  @override
  void initState() {
    super.initState();
    pinController = TextEditingController();
    _checkUserStatus(); // User status check pandrom
  }

  // 1. Check if user has already set a PIN
  Future<void> _checkUserStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool canCheck = await auth.canCheckBiometrics;
    
    setState(() {
      _isBiometricAvailable = canCheck;
      // 'user_pin' null-ah irundha avanga innum set pannala-nu artham
      _isFirstTimeUser = prefs.getString('user_pin') == null;
    });
  }

  // 2. PIN Logic (Set or Verify)
  void handlePinAction() async {
    final prefs = await SharedPreferences.getInstance();

    if (_isFirstTimeUser) {
      // Setup New PIN
      if (pinController.text.length == 4) {
        await prefs.setString('user_pin', pinController.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PIN Set Successfully!"), backgroundColor: Colors.green),
        );
        setState(() => _isFirstTimeUser = false);
        pinController.clear();
      } else {
        _showError("Please enter a 4-digit PIN");
      }
    } else {
      // Verify Existing PIN
      String? savedPin = prefs.getString('user_pin');
      if (pinController.text == savedPin) {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ScanPage()));
      } else {
        _showError("Incorrect PIN!");
        pinController.clear();
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ... (Fingerprint logic same-ah vechukkalam) ...
  Future<void> fingerprintAuth() async {
     if (_isFirstTimeUser) {
       _showError("Set a PIN first to enable Biometrics!");
       return;
     }
     // ... rest of the auth code ...
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 120),
            child: Column(
              children: [
                // Icon Header
                const Icon(Icons.security_rounded, size: 80, color: Colors.white),
                const SizedBox(height: 30),

                // Dynamic Title based on status
                Text(
                  _isFirstTimeUser ? "Set Your Secret PIN" : "Enter PIN to Unlock",
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _isFirstTimeUser ? "Choose 4 digits to secure your garden" : "Your plants are waiting for you",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),

                const SizedBox(height: 50),

                // PIN Field
                _buildPinField(),

                const SizedBox(height: 40),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: handlePinAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1B5E20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(
                      _isFirstTimeUser ? "SET PIN" : "UNLOCK",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Biometrics (Only if not first time)
                if (!_isFirstTimeUser && _isBiometricAvailable) ...[
                   const SizedBox(height: 20),
                   IconButton(
                     icon: const Icon(Icons.fingerprint, size: 50, color: Colors.white),
                     onPressed: fingerprintAuth,
                   ),
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
  XFile? image;
  final ImagePicker picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? picked = await picker.pickImage(source: source);
    if (picked != null) {
      // ✂️ Image-ah crop panna porom (Idhu dhaan pudhu logic)
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square, // Model prediction-ku square dhaan best
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: LanguageData.currentLang == "ta" ? 'இலையை மட்டும் செதுக்கவும்' : 'Crop Plant Leaf',
            toolbarColor: const Color(0xFF1B5E20),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true, 
          ),
          IOSUiSettings(
            title: 'Crop Plant Leaf',
          ),
        ],
      );

      // Crop panni mudichadhukku apram, andha image-ah ResultPage-ku anupuraom
      if (croppedFile != null) {
        if (!mounted) return;
        setState(() => image = XFile(croppedFile.path)); // Path-ah update pannidunga
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => ResultPage(image: XFile(croppedFile.path)))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          LanguageData.getText('app_title'), 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => setState(() => LanguageData.currentLang = (LanguageData.currentLang == "ta") ? "en" : "ta"),
            child: Text(
              LanguageData.currentLang == "ta" ? "English" : "தமிழ்",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
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
            const SizedBox(height: 160), // Space for AppBar
            
            // Modern Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                LanguageData.getText('scan_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
              ),
            ),
            
            const Spacer(), // Push cards to center
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildScheduleButton(context),
            ),

            // Modern Dashboard Cards (Existing row)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModernCard(
                  LanguageData.getText('camera'), 
                  Icons.camera_enhance_rounded, 
                  () => pickImage(ImageSource.camera)
                ),
                _buildModernCard(
                  LanguageData.getText('gallery'), 
                  Icons.photo_library_rounded, 
                  () => pickImage(ImageSource.gallery)
                ),
              ],
            ),
            
            const Spacer(flex: 2), // Extra space at bottom
          ],
        ),
      ),
    );
  }

  // 👇 Glassmorphic Card UI Component
  Widget _buildModernCard(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Glass blur
          child: Container(
            width: 165,
            height: 190,
            decoration: BoxDecoration(
              // ignore: duplicate_ignore
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(30),
              // ignore: deprecated_member_use
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    // ignore: duplicate_ignore
                    // ignore: deprecated_member_use
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 45, color: Colors.white),
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildScheduleButton(BuildContext context) {
  return GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CropSchedulePage())),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
              const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 15),
              Text(
                LanguageData.getText('crop_schedule'), // 'பயிர் காலண்டர்' nu varum
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
            ],
          ),
        ),
      ),
    ),
  );
}
}



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
    setState(() {
      history = (data as List<Map<String, dynamic>>?) ?? [];
    });
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Image.file(File(item['image_path'] ?? ''), fit: BoxFit.cover),
          ),
        ),
        title: Text(item['disease_name'] ?? 'Unknown'),
        subtitle: Text(item['date'] ?? ''),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            await DatabaseHelper.instance.deleteHistory(item['id']);
            _loadHistory();
          },
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageData.getText('history')),
      ),
      body: history.isEmpty
          ? Center(
              child: Text(
                LanguageData.currentLang == "ta" ? "வரலாறு இல்லை" : "No history",
                style: const TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: history.length,
              itemBuilder: (context, index) => _buildHistoryCard(history[index]),
            ),
    );
  }
}

/* ---------------- RESULT PAGE (UPDATED) ---------------- */



/* ---------------- RESULT PAGE ---------------- */
/* ---------------- RESULT PAGE (UPDATED) ---------------- */

// Unga matha imports (DatabaseHelper, PredictionService) add pannikonga

// ...existing code...



class ResultPage extends StatefulWidget {
  final XFile image;
  const ResultPage({super.key, required this.image});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  PredictionService predictionService = PredictionService();
  late FlutterTts flutterTts;
  String diseaseName = "கணக்கிடப்படுகிறது...";
  String treatmentText = "காத்திருக்கவும்...";
  bool isLoaded = false;
  String predictedKey = "";
  double currentHumidity = 60.0; // Default humidity for offline check

  final List<String> diseaseLabels = [
    "Potato___Early_blight",
    "Potato___Late_blight",
    "Healthy",
    "Tomato___Early_blight",
    "Tomato___Late_blight",
  ];

  final Map<String, Map<String, String>> diseaseData = {
    "Tomato___Early_blight": {
      "name": "தக்காளி முன் கருகல்", "name_en": "Tomato Early Blight",
      "severity": "குறைவான பாதிப்பு", "severity_en": "Low",
      "treatment": "• பாதிக்கப்பட்ட இலைகளை அகற்றவும்.", "treatment_en": "• Remove infected leaves.",
      "prevention": "• செடிகளுக்கு இடையில் இடைவெளி விடவும்.", "prevention_en": "• Maintain spacing."
    },
    "Tomato___Late_blight": {
      "name": "தக்காளி பின் கருகல்", "name_en": "Tomato Late Blight",
      "severity": "அதிகமான பாதிப்பு", "severity_en": "High",
      "treatment": "• மேன்கோசெப் மருந்தைப் பயன்படுத்தவும்.", "treatment_en": "• Use Mancozeb.",
      "prevention": "• இலைகளில் நீர் படாமல் பார்த்துக் கொள்ளவும்.", "prevention_en": "• Avoid watering leaves."
    },
    "Potato___Early_blight": {
      "name": "உருளை ஆரம்பக்கால கருகல்", "name_en": "Potato Early Blight",
      "severity": "மிதமான பாதிப்பு", "severity_en": "Medium",
      "treatment": "• பயிர் சுழற்சி முறையைப் பின்பற்றவும்.", "treatment_en": "• Follow crop rotation.",
      "prevention": "• பொட்டாசியம் உரங்களைப் பயன்படுத்தவும்.", "prevention_en": "• Use potassium fertilizers."
    },
    "Potato___Late_blight": {
      "name": "உருளை பிற்கால கருகல்", "name_en": "Potato Late Blight",
      "severity": "அதிகமான பாதிப்பு", "severity_en": "High",
      "treatment": "• செம்பு பூஞ்சைக் கொல்லிகளைப் பயன்படுத்தவும்.", "treatment_en": "• Use copper fungicides.",
      "prevention": "• வயலில் தண்ணீர் தேங்காமல் பார்த்துக் கொள்ளவும்.", "prevention_en": "• Ensure field drainage."
    },
    "Healthy": {
      "name": "ஆரோக்கியமான செடி", "name_en": "Healthy Plant",
      "severity": "பாதிப்பு இல்லை", "severity_en": "None",
      "treatment": "• இயற்கை உரமிடுக.", "treatment_en": "• Use organic fertilizer.",
      "prevention": "• வேப்ப எண்ணெய் தெளிக்கவும்.", "prevention_en": "• Spray Neem oil."
    }
  };

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    initTTS();
    runPrediction();
  }

  Future<void> initTTS() async {
    await flutterTts.setLanguage(LanguageData.currentLang == "ta" ? "ta-IN" : "en-US");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
  }

  Future<void> runPrediction() async {
    await predictionService.loadModel();
    try {
      int index = await predictionService.predict(File(widget.image.path));
      if (mounted) {
        predictedKey = (index >= 0 && index < diseaseLabels.length) ? diseaseLabels[index] : "Healthy";
        diseaseName = diseaseData[predictedKey]![LanguageData.currentLang == "ta" ? "name" : "name_en"]!;
        treatmentText = diseaseData[predictedKey]![LanguageData.currentLang == "ta" ? "treatment" : "treatment_en"]!;
        
        await DatabaseHelper.instance.insertHistory(widget.image.path, diseaseName, treatmentText);
        setState(() => isLoaded = true);
        speakWithRisk();
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> speakWithRisk() async {
    if (isLoaded) {
      String risk = WeatherRiskService.getRiskMessage(currentHumidity, predictedKey, LanguageData.currentLang);
      await flutterTts.speak("$diseaseName. $risk. $treatmentText");
    }
  }

  Widget _buildSeverityBadge(String severity) {
    Color color = (severity.contains("High") || severity.contains("அதிகமான")) ? Colors.redAccent : 
                 (severity.contains("Medium") || severity.contains("மிதமான")) ? Colors.orangeAccent : Colors.lightGreenAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(severity, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  void _showAddGardenDialog() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(LanguageData.currentLang == "ta" ? "தோட்டத்தில் சேர்க்க" : "Add to My Garden"),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: LanguageData.currentLang == "ta" ? "செடியின் பெயர்" : "Plant Nickname"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(LanguageData.currentLang == "ta" ? "ரத்து" : "Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await DatabaseHelper.instance.addToGarden(nameController.text, widget.image.path, diseaseName);
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LanguageData.currentLang == "ta" ? "சேமிக்கப்பட்டது!" : "Saved!")));
              }
            },
            child: Text(LanguageData.currentLang == "ta" ? "சேமி" : "Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(LanguageData.getText('result'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: isLoaded ? _buildContent() : const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 110),
      child: Column(
        children: [
          // Image Preview
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20)]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Image.file(File(widget.image.path), height: 260, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 25),

          // Main Info Card
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.2))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(diseaseName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
                        _buildSeverityBadge(diseaseData[predictedKey]![LanguageData.currentLang == "ta" ? "severity" : "severity_en"]!),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 30),
                    
                    // Offline Weather Section
                    Row(
                      children: [
                        const Icon(Icons.water_drop_outlined, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          LanguageData.currentLang == "ta" ? "ஈரப்பதம் (Humidity): ${currentHumidity.round()}%" : "Humidity: ${currentHumidity.round()}%",
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: currentHumidity,
                      min: 0, max: 100,
                      activeColor: WeatherRiskService.getRiskColor(currentHumidity),
                      onChanged: (val) => setState(() => currentHumidity = val),
                    ),
                    Text(
                      WeatherRiskService.getRiskMessage(currentHumidity, predictedKey, LanguageData.currentLang),
                      style: TextStyle(color: WeatherRiskService.getRiskColor(currentHumidity), fontWeight: FontWeight.bold, fontSize: 13),
                    ),

                    const Divider(color: Colors.white24, height: 30),
                    
                    // Treatment Text
                    Text(LanguageData.getText('treatment'), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(treatmentText, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Bottom Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: speakWithRisk,
                  icon: const Icon(Icons.volume_up),
                  label: Text(LanguageData.getText('speak')),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.green.shade900, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                ),
              ),
              const SizedBox(width: 15),
              IconButton.filled(
                onPressed: _showAddGardenDialog,
                icon: const Icon(Icons.yard_outlined),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), padding: const EdgeInsets.all(15)),
              )
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    predictionService.dispose();
    super.dispose();
  }
}
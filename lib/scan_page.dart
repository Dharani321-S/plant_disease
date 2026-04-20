// ignore: unused_import
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
// Unga project path-ku etha maari mathikkonga
import 'package:plant_disease/main.dart'; 

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // 1. Camera Setup
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      try {
        await _controller!.initialize();
        if (!mounted) return;
        setState(() => _isCameraInitialized = true);
      } catch (e) {
        debugPrint("Camera Error: $e");
      }
    }
  }

  // 2. Image Processing Logic
  Future<void> _processImage(String path) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Align Leaf',
          toolbarColor: const Color(0xFF1B5E20),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
      ],
    );

    if (croppedFile != null && mounted) {
      // Direct-ah ResultPage-ku pogum
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(image: XFile(croppedFile.path)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // LIVE VIEW
          if (_isCameraInitialized && _controller != null)
            Positioned.fill(child: CameraPreview(_controller!))
          else
            const Center(child: CircularProgressIndicator(color: Colors.green)),

          // QR FRAME OVERLAY
          _buildScannerOverlay(),

          // BACK BUTTON
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // BOTTOM BUTTONS
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // GALLERY
                _buildSmallButton(Icons.photo_library, () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) _processImage(image.path);
                }),

                // MAIN SCAN BUTTON
                GestureDetector(
                  onTap: () async {
                    if (_controller != null && _controller!.value.isInitialized) {
                      final XFile photo = await _controller!.takePicture();
                      _processImage(photo.path);
                    }
                  },
                  child: Container(
                    height: 80, width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.white24,
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
                  ),
                ),

                // FLASH (Optional)
                _buildSmallButton(Icons.flash_on, () {
                  _controller?.setFlashMode(
                    _controller!.value.flashMode == FlashMode.torch ? FlashMode.off : FlashMode.torch
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Container(
        width: 250, height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.greenAccent, width: 3),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildSmallButton(IconData icon, VoidCallback onTap) {
    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.black54,
      child: IconButton(icon: Icon(icon, color: Colors.white), onPressed: onTap),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
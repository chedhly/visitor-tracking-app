import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

class CameraService {
  static CameraController? _controller;
  static bool _isInitialized = false;

  static Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
      );

      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  static Future<File?> captureImage() async {
    if (!_isInitialized || _controller == null) {
      await initializeCamera();
    }

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagePath = '${appDir.path}/plate_${DateTime.now().millisecondsSinceEpoch}.jpg';

      XFile picture = await _controller!.takePicture();
      File imageFile = File(picture.path);

      // Move file to our desired location
      await imageFile.copy(imagePath);
      return File(imagePath);
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  static void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }
}
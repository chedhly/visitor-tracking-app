import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

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
    try {
      // Use image picker for better compatibility across platforms
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String imagePath = '${appDir.path}/plate_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Copy to our desired location
        File imageFile = File(image.path);
        File savedFile = await imageFile.copy(imagePath);
        return savedFile;
      }
    } catch (e) {
      print('Error with image picker: $e');
      // Fallback to camera controller if available
      return await _captureWithController();
    }
    return null;
  }

  static Future<File?> _captureWithController() async {
    try {
      if (!_isInitialized || _controller == null) {
        await initializeCamera();
      }

      if (_controller != null && _isInitialized) {
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String imagePath = '${appDir.path}/plate_${DateTime.now().millisecondsSinceEpoch}.jpg';

        XFile picture = await _controller!.takePicture();
        File imageFile = File(picture.path);

        // Move file to our desired location
        await imageFile.copy(imagePath);
        return File(imagePath);
      }
    } catch (e) {
      print('Error capturing with controller: $e');
    }
    return null;
  }

  static void dispose() {
    _controller?.dispose();
    _isInitialized = false;
  }
}
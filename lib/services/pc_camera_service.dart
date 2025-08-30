import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

class PCCameraService {
  static CameraController? _controller;
  static List<CameraDescription>? _cameras;
  static bool _isInitialized = false;

  static Future<void> initializeCamera() async {
    try {
      _cameras = await availableCameras();
      
      if (_cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      // Find the best camera (prefer back camera, then front)
      CameraDescription selectedCamera = _cameras!.first;
      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      _isInitialized = true;
      print('PC Camera initialized successfully');
    } catch (e) {
      print('Camera initialization error: $e');
      _isInitialized = false;
      throw Exception('Failed to initialize camera: $e');
    }
  }

  static Future<File?> captureImageForPlateDetection() async {
    try {
      if (!_isInitialized || _controller == null) {
        await initializeCamera();
      }

      if (_controller == null || !_controller!.value.isInitialized) {
        throw Exception('Camera not initialized');
      }

      // Capture image
      XFile picture = await _controller!.takePicture();
      
      // Save to app directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagePath = '${appDir.path}/plates/plate_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Create directory if it doesn't exist
      final Directory plateDir = Directory('${appDir.path}/plates');
      if (!await plateDir.exists()) {
        await plateDir.create(recursive: true);
      }

      // Copy image to permanent location
      File imageFile = File(picture.path);
      File savedFile = await imageFile.copy(imagePath);
      
      print('Image captured and saved: $imagePath');
      return savedFile;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  static Widget buildCameraPreview() {
    if (!_isInitialized || _controller == null) {
      return Container(
        height: 300,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 50, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Camera not initialized',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 300,
      child: CameraPreview(_controller!),
    );
  }

  static Future<void> showCameraDialog(BuildContext context, Function(File) onImageCaptured) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => CameraDialog(onImageCaptured: onImageCaptured),
    );
  }

  static bool get isInitialized => _isInitialized;
  static CameraController? get controller => _controller;

  static void dispose() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }
}

class CameraDialog extends StatefulWidget {
  final Function(File) onImageCaptured;

  const CameraDialog({Key? key, required this.onImageCaptured}) : super(key: key);

  @override
  State<CameraDialog> createState() => _CameraDialogState();
}

class _CameraDialogState extends State<CameraDialog> {
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      await PCCameraService.initializeCamera();
      setState(() {});
    } catch (e) {
      print('Failed to initialize camera: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_isCapturing) return;
    
    setState(() {
      _isCapturing = true;
    });

    try {
      File? imageFile = await PCCameraService.captureImageForPlateDetection();
      if (imageFile != null) {
        widget.onImageCaptured(imageFile);
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'License Plate Detection',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            Expanded(
              child: PCCameraService.buildCameraPreview(),
            ),
            
            SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: _isCapturing ? null : _captureImage,
                  child: _isCapturing 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt),
                          SizedBox(width: 8),
                          Text('Capture'),
                        ],
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
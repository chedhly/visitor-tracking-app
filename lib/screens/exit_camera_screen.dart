import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import '../services/visitor_service.dart';

class ExitCameraScreen extends StatefulWidget {
  @override
  _ExitCameraScreenState createState() => _ExitCameraScreenState();
}

class _ExitCameraScreenState extends State<ExitCameraScreen> {
  CameraController? _controller;
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isProcessing = false;
  String _detectedPlate = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
      );

      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print('Camera error: $e');
    }
  }

  Future<void> _captureAndProcess() async {
    if (_controller == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      String plateNumber = '';
      for (TextBlock block in recognizedText.blocks) {
        final text = block.text.replaceAll(' ', '');
        if (_isTunisianPlate(text)) {
          plateNumber = text;
          break;
        }
      }

      if (plateNumber.isNotEmpty) {
        setState(() => _detectedPlate = plateNumber);
        await _recordExit(plateNumber);
      } else {
        _showError('No valid license plate detected');
      }
    } catch (e) {
      _showError('Error processing image: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  bool _isTunisianPlate(String text) {
    final pattern = RegExp(r'^\d{1,3}[تونس]+\d{1,4}$');
    return pattern.hasMatch(text) && text.contains('تونس');
  }

  Future<void> _recordExit(String plateNumber) async {
    try {
      final visitorService = Provider.of<VisitorService>(context, listen: false);
      await visitorService.recordExit(plateNumber);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehicle $plateNumber exited - Barrier Opening'),
          backgroundColor: Colors.blue,
        ),
      );

      await Future.delayed(Duration(seconds: 2));
      Navigator.of(context).pop();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vehicle Exit')),
      body: Column(
        children: [
          Expanded(
            child: _controller?.value.isInitialized == true
                ? CameraPreview(_controller!)
                : Center(child: CircularProgressIndicator()),
          ),
          if (_detectedPlate.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.blue,
              child: Text(
                'Detected: $_detectedPlate',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _captureAndProcess,
                icon: _isProcessing
                    ? CircularProgressIndicator(color: Colors.white)
                    : Icon(Icons.camera),
                label: Text('Capture & Recognize Plate'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

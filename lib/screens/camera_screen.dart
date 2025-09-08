import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../services/license_plate_recognition.dart';
import '../services/visitor_service.dart';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isProcessing = false;
  String? _detectedPlate;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Scan License Plate'),
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.flip_camera_ios),
            onPressed: _flipCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Scanning Overlay
          Positioned.fill(
            child: _buildScanningOverlay(),
          ),

          // Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Scanning Frame
        Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF2196F3), width: 3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Corner indicators
              Positioned(top: -3, left: -3, child: _buildCorner()),
              Positioned(top: -3, right: -3, child: _buildCorner()),
              Positioned(bottom: -3, left: -3, child: _buildCorner()),
              Positioned(bottom: -3, right: -3, child: _buildCorner()),
            ],
          ),
        ),

        SizedBox(height: 20),

        // Instructions
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Position the license plate within the frame',
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),

        // Detected Plate
        if (_detectedPlate != null) ...[
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF2196F3).withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Detected: $_detectedPlate',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCorner() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Color(0xFF2196F3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.black54,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Capture Button
          GestureDetector(
            onTap: _isProcessing ? null : _takePicture,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isProcessing ? Colors.grey : Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          // Manual Entry Button
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/manual-entry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white24,
              side: BorderSide(color: Colors.white),
            ),
            child: Text(
              'Manual Entry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_controller == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _controller!.takePicture();
      final plateNumber = await LicensePlateRecognition.recognizePlate(image.path);

      if (plateNumber != null) {
        setState(() {
          _detectedPlate = plateNumber;
        });

        _showConfirmationDialog(plateNumber);
      } else {
        _showNoPlateDetectedDialog();
      }
    } catch (e) {
      _showErrorDialog('Failed to capture image. Please try again.');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showConfirmationDialog(String plateNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('License Plate Detected'),
        content: Text('Detected: $plateNumber\n\nIs this correct?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _detectedPlate = null;
              });
            },
            child: Text('Retake'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmEntry(plateNumber);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showNoPlateDetectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('No Plate Detected'),
        content: Text('Could not detect a license plate. Please ensure the plate is clearly visible and try again, or use manual entry.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/manual-entry');
            },
            child: Text('Manual Entry'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmEntry(String plateNumber) async {
    try {
      await context.read<VisitorService>().recordEntry(plateNumber);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Entry Recorded'),
          content: Text('Vehicle $plateNumber entry recorded successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras!.length < 2) return;

    final currentIndex = _cameras!.indexOf(_controller!.description);
    final nextIndex = (currentIndex + 1) % _cameras!.length;

    await _controller!.dispose();
    _controller = CameraController(_cameras![nextIndex], ResolutionPreset.high);
    await _controller!.initialize();
    setState(() {});
  }
}

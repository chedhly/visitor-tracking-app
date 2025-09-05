import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:visitor_tracking_app/services/opencv_plate_service.dart';
import 'package:visitor_tracking_app/services/mysql_database.dart';
import 'package:visitor_tracking_app/services/notification_service.dart';

class CameraOpenALPRDialog extends StatefulWidget {
  const CameraOpenALPRDialog({Key? key}) : super(key: key);

  @override
  State<CameraOpenALPRDialog> createState() => _CameraOpenALPRDialogState();
}

class _CameraOpenALPRDialogState extends State<CameraOpenALPRDialog> {
  bool _isProcessing = false;
  String _statusMessage = 'Choose image source for license plate recognition';
  File? _selectedImage;
  List<PlateResult> _detectedPlates = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 600,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'License Plate Recognition',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Image preview or placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                )
                    : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Select an image to detect license plates',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Detection results
            if (_detectedPlates.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detected Plates (${_detectedPlates.length}):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    SizedBox(height: 8),
                    ..._detectedPlates.map((plate) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${plate.plateNumber} (${plate.confidence.toStringAsFixed(1)}%)',
                              style: TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _processPlateEntry(plate.plateNumber),
                            child: Text('Select'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            // Status message
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  if (_isProcessing)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (_isProcessing) SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _pickFromCamera,
                  icon: Icon(Icons.camera_alt),
                  label: Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _pickFromGallery,
                  icon: Icon(Icons.photo_library),
                  label: Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                if (_selectedImage != null)
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _recognizePlates,
                    icon: Icon(Icons.search),
                    label: Text('Recognize'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _statusMessage = 'Image captured. Click "Recognize" to detect plates.';
          _detectedPlates.clear();
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Camera error: $e';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _statusMessage = 'Image selected. Click "Recognize" to detect plates.';
          _detectedPlates.clear();
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Gallery error: $e';
      });
    }
  }

  Future<void> _recognizePlates() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing image with ALPR...';
    });

    try {
      // Preprocess image
      File processedImage = await OpenCVPlateService.preprocessImage(_selectedImage!);

      // Recognize plates
      List<PlateResult> results = await OpenCVPlateService.recognizePlate(processedImage);

      setState(() {
        _detectedPlates = results;
        _isProcessing = false;

        if (results.isEmpty) {
          _statusMessage = 'No license plates detected. Try a different image.';
        } else {
          _statusMessage = 'Found ${results.length} license plate(s). Select one to process entry.';
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Recognition failed: $e';
      });
    }
  }

  Future<void> _processPlateEntry(String plateNumber) async {
    try {
      setState(() {
        _isProcessing = true;
        _statusMessage = 'Processing vehicle entry...';
      });

      // Check if car is already inside
      final existingCars = await MySQLDatabaseHelper.getCarsByPlate(plateNumber);
      final carInside = existingCars.any((car) => car['status'] == 'inside');

      if (carInside) {
        // Process exit
        final carData = existingCars.firstWhere((car) => car['status'] == 'inside');
        DateTime exitTime = DateTime.now();
        DateTime entryTime = DateTime.parse(carData['entry_time']);
        Duration duration = exitTime.difference(entryTime);
        String durationStr = '${duration.inHours}h${duration.inMinutes.remainder(60)}m';

        await MySQLDatabaseHelper.updateCarExit(
          carData['id'],
          exitTime.toIso8601String(),
          durationStr,
        );

        NotificationService.showExitNotification(plateNumber, durationStr);

        setState(() {
          _statusMessage = 'Vehicle $plateNumber exited successfully!';
        });

        // Close dialog after success
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pop(true);
        });
      } else {
        // Process entry
        DateTime now = DateTime.now();
        await MySQLDatabaseHelper.insertCar({
          'plate_number': plateNumber,
          'entry_time': now.toIso8601String(),
          'image_path': _selectedImage?.path ?? '',
          'status': 'inside',
          'detection_method': 'camera',
          'confidence_score': _detectedPlates.isNotEmpty ? _detectedPlates.first.confidence : 100.0,
        });

        NotificationService.showEntryNotification(plateNumber);

        setState(() {
          _statusMessage = 'Vehicle $plateNumber entered successfully!';
        });

        // Close dialog after success
        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).pop(true);
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error processing entry: $e';
      });
    }
  }
}
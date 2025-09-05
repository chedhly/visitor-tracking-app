import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:visitor_tracking_app/services/mysql_database.dart';
import 'package:visitor_tracking_app/services/opencv_plate_service.dart';
import 'package:visitor_tracking_app/services/pc_camera_service.dart';
import 'package:visitor_tracking_app/services/notification_service.dart';

class EnhancedEntranceService {
  static final Map<String, Timer> _carTimers = {};

  static Future<void> processCarEntranceWithCamera(BuildContext context) async {
    try {
      print('Starting camera-based entrance processing...');
      if (!PCCameraService.isInitialized) {
        // Try to initialize camera
        await PCCameraService.initializeCamera();

        if (!PCCameraService.isInitialized) {
          _showErrorDialog(context, 'Camera not available. Please check camera permissions or use manual entry.');
          return;
        }
      }
      // Show camera dialog and capture image
      await PCCameraService.showCameraDialog(context, (File imageFile) async {
        await _processImageForPlateDetection(context, imageFile);
      });

    } catch (e) {
      print('Camera entrance error: $e');
      _showErrorDialog(context, 'Camera error: $e');
    }
  }

  static Future<void> _processImageForPlateDetection(BuildContext context, File imageFile) async {
    try {
      // Show processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Recognizing license plate with OpenALPR...'),
            ],
          ),
        ),
      );

      // Preprocess image for better recognition
      File processedImage = await OpenCVPlateService.preprocessImage(imageFile);

      // Recognize license plate using OpenALPR
      List<PlateResult> results = await OpenCVPlateService.recognizePlate(processedImage);

      // Close processing dialog
      Navigator.of(context).pop();

      if (results.isEmpty) {
        _showErrorDialog(context, 'Could not detect any license plate. Please ensure the plate is clearly visible and try again.');
        return;
      }

      // Get the best result (highest confidence)
      PlateResult bestResult = results.reduce((a, b) => a.confidence > b.confidence ? a : b);
      String plateNumber = bestResult.plateNumber;

      print('License plate detected: $plateNumber (confidence: ${bestResult.confidence.toStringAsFixed(2)}%)');

      // Validate confidence level
      if (bestResult.confidence < 80.0) {
        _showConfirmationDialog(context, plateNumber, bestResult.confidence, () async {
          await _processPlateEntry(plateNumber, imageFile);
        });
        return;
      }

      await _processPlateEntry(plateNumber, imageFile);
    } catch (e) {
      // Close processing dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      print('Plate recognition error: $e');
      _showErrorDialog(context, 'Error recognizing license plate: $e');
    }
  }

  static Future<void> _processPlateEntry(String plateNumber, File imageFile) async {
    try {
      // Check if car is already inside
      final existingCars = await MySQLDatabaseHelper.getCarsByPlate(plateNumber);
      final carInside = existingCars.any((car) => car['status'] == 'inside');

      if (carInside) {
        print('Car already inside, processing exit...');
        await _processCarExit(plateNumber);
        return;
      }

      // Process entry
      DateTime now = DateTime.now();
      await MySQLDatabaseHelper.insertCar({
        'plate_number': plateNumber,
        'entry_time': now.toIso8601String(),
        'image_path': imageFile.path,
        'status': 'inside',
      });

      print('Car entry recorded for: $plateNumber');
      _openBarrier();


      // Start monitoring for overstay
      _startOverstayMonitoring(plateNumber, now);

      NotificationService.showEntryNotification(plateNumber);
    } catch (e) {
      print('Plate entry processing error: $e');
      throw Exception('Failed to process plate entry: $e');
    }
  }

  static Future<void> _processCarExit(String plateNumber) async {
    try {
      final cars = await MySQLDatabaseHelper.getCarsByPlate(plateNumber);
      final carInside = cars.firstWhere(
            (car) => car['status'] == 'inside',
        orElse: () => <String, dynamic>{},
      );

      if (carInside.isNotEmpty) {
        DateTime exitTime = DateTime.now();
        DateTime entryTime = DateTime.parse(carInside['entry_time']);
        Duration duration = exitTime.difference(entryTime);
        String durationStr = '${duration.inHours}h${duration.inMinutes.remainder(60)}m';

        await MySQLDatabaseHelper.updateCarExit(
          carInside['id'],
          exitTime.toIso8601String(),
          durationStr,
        );

        // Cancel overstay monitoring for this car
        _carTimers[plateNumber]?.cancel();
        _carTimers.remove(plateNumber);

        print('Car $plateNumber exited after $durationStr');
        _openBarrier();

        NotificationService.showExitNotification(plateNumber, durationStr);
      }
    } catch (e) {
      print('Exit processing error: $e');
    }
  }

  static void _startOverstayMonitoring(String plateNumber, DateTime entryTime) async {
    final settings = await MySQLDatabaseHelper.getSettings();
    final maxStayHours = settings['max_stay_hours'] ?? 8;
    final maxStayMinutes = settings['max_stay_minutes'] ?? 0;
    final maxStayDuration = Duration(hours: maxStayHours, minutes: maxStayMinutes);

    // Cancel existing timer for this car
    _carTimers[plateNumber]?.cancel();

    // Set timer for overstay alert
    _carTimers[plateNumber] = Timer(maxStayDuration, () {
      _triggerOverstayAlert(plateNumber, maxStayDuration);
    });
  }

  static void _openBarrier() {
    print('🚧 Barrier opened for vehicle passage');
    // Here you would integrate with actual barrier hardware
    Future.delayed(Duration(seconds: 5), () {
      print('🚧 Barrier closed');
    });
  }

  static void _triggerOverstayAlert(String plateNumber, Duration duration) {
    print('🚨 OVERSTAY ALERT: Car $plateNumber has stayed for ${duration.inHours}h${duration.inMinutes.remainder(60)}m');
    NotificationService.showOverstayAlert(plateNumber, duration);
  }

  static void _showSuccessDialog(BuildContext context, String message, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Recognition Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  static void _showConfirmationDialog(BuildContext context, String plateNumber, double confidence, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirm Plate Number'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detected plate: $plateNumber'),
            Text('Confidence: ${confidence.toStringAsFixed(1)}%'),
            SizedBox(height: 16),
            Text('The confidence is below 80%. Do you want to proceed with this plate number?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  static void dispose() {
    for (var timer in _carTimers.values) {
      timer.cancel();
    }
    _carTimers.clear();
    PCCameraService.dispose();
  }
}
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:visitor_tracking_app/services/mysql_database.dart';
import 'package:visitor_tracking_app/services/tunisian_plate_detector.dart';
import 'package:visitor_tracking_app/services/pc_camera_service.dart';
import 'package:visitor_tracking_app/services/notification_service.dart';

class EnhancedEntranceService {
  static final Map<String, Timer> _carTimers = {};

  static Future<void> processCarEntranceWithCamera(BuildContext context) async {
    try {
      print('Starting camera-based entrance processing...');

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
              Text('Detecting Tunisian license plate...'),
            ],
          ),
        ),
      );

      // Detect Tunisian license plate
      String? plateNumber = await TunisianPlateDetector.detectTunisianPlate(imageFile);
      
      // Close processing dialog
      Navigator.of(context).pop();

      if (plateNumber == null) {
        _showErrorDialog(context, 'Could not detect a valid Tunisian license plate. Please ensure the plate is clearly visible and try again.');
        return;
      }

      print('Tunisian plate detected: $plateNumber');

      // Validate that it's a Tunisian plate
      if (!TunisianPlateDetector.isTunisianPlate(plateNumber)) {
        _showErrorDialog(context, 'Detected plate "$plateNumber" is not a valid Tunisian license plate format.');
        return;
      }

      // Check if car is already inside
      final existingCars = await MySQLDatabaseHelper.getCarsByPlate(plateNumber);
      final carInside = existingCars.any((car) => car['status'] == 'inside');

      if (carInside) {
        print('Car already inside, processing exit...');
        await _processCarExit(plateNumber);
        _showSuccessDialog(context, 'Vehicle $plateNumber exited successfully', 'Exit Recorded');
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

      _showSuccessDialog(context, 'Vehicle $plateNumber entered successfully', 'Entry Recorded');

      // Start monitoring for overstay
      _startOverstayMonitoring(plateNumber, now);

      NotificationService.showEntryNotification(plateNumber);
    } catch (e) {
      // Close processing dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      print('Plate detection error: $e');
      _showErrorDialog(context, 'Error processing license plate: $e');
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
            Text('Detection Error'),
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

  static void dispose() {
    for (var timer in _carTimers.values) {
      timer.cancel();
    }
    _carTimers.clear();
    PCCameraService.dispose();
  }
}
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:visitor_tracking_app/services/data base.dart';
import 'package:visitor_tracking_app/services/ALRP.dart';
import 'package:visitor_tracking_app/services/camera.dart';
import 'package:visitor_tracking_app/services/notification_service.dart';


class EntranceService {
  static final Map<String, Timer> _carTimers = {};

  static Future<void> processCarEntrance(BuildContext context) async {
    try {
      print('Processing car entrance...');

      File? imageFile = await CameraService.captureImage();
      if (imageFile == null) {
        print('Failed to capture image');
        _showErrorDialog(context, 'Failed to capture image. Please try again.');
        return;
      }

      print('Image captured, recognizing plate...');
      String? plateNumber = await ALPRService.recognizeLicensePlate(imageFile);
      if (plateNumber == null) {
        print('Failed to recognize plate number');
        _showErrorDialog(context, 'Could not recognize license plate. Please ensure the plate is clearly visible.');
        return;
      }

      print('Plate recognized: $plateNumber');

      // Check if car is already inside
      final existingCars = await RemoteDatabaseHelper.getCarsByPlate(plateNumber);
      final carInside = existingCars.any((car) => car['status'] == 'inside');

      if (carInside) {
        print('Car already inside, processing exit...');
        await _processCarExit(plateNumber);
        _showSuccessDialog(context, 'Vehicle $plateNumber exited successfully');
        return;
      }

      DateTime now = DateTime.now();
      await RemoteDatabaseHelper.insertCar({
        'plate_number': plateNumber,
        'entry_time': now.toIso8601String(),
        'image_path': imageFile.path,
        'status': 'inside',
      });

      print('Car entry recorded for: $plateNumber');
      _openBarrier();

      _showSuccessDialog(context, 'Vehicle $plateNumber entered successfully');

      // Start monitoring for overstay
      _startOverstayMonitoring(plateNumber, now);

      NotificationService.showEntryNotification(plateNumber);
    } catch (e) {
      print('Entrance Error: $e');
      _showErrorDialog(context, 'Error processing entrance. Please try again.');
    }
  }

  static Future<void> _processCarExit(String plateNumber) async {
    try {
      final cars = await RemoteDatabaseHelper.getCarsByPlate(plateNumber);
      final carInside = cars.firstWhere(
            (car) => car['status'] == 'inside',
        orElse: () => <String, dynamic>{},
      );

      if (carInside.isNotEmpty) {
        DateTime exitTime = DateTime.now();
        DateTime entryTime = DateTime.parse(carInside['entry_time']);
        Duration duration = exitTime.difference(entryTime);
        String durationStr = '${duration.inHours}h${duration.inMinutes.remainder(60)}m';

        await RemoteDatabaseHelper.updateCarExit(
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
    final settings = await RemoteDatabaseHelper.getSettings();
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
    print('Barrier opened');
    // Here you would integrate with actual barrier hardware
    Future.delayed(Duration(seconds: 5), () {
      print('Barrier closed');
    });
  }

  static void _triggerOverstayAlert(String plateNumber, Duration duration) {
    print('OVERSTAY ALERT: Car $plateNumber has stayed for ${duration.inHours}h${duration.inMinutes.remainder(60)}m');
    NotificationService.showOverstayAlert(plateNumber, duration);
  }

  static void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  static void dispose() {
    _exitMonitorTimer?.cancel();
    for (var timer in _carTimers.values) {
      timer.cancel();
    }
    _carTimers.clear();
  }
}
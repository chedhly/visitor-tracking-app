import 'package:flutter/material.dart';
import 'dart:io';
import 'package:visitor_tracking_app/services/data base.dart';
import 'package:visitor_tracking_app/services/ALRP.dart';
import 'package:visitor_tracking_app/services/camera.dart';


class EntranceService {
  static final RemoteDatabaseHelper dbHelper = RemoteDatabaseHelper();

  static Future<void> processCarEntrance(BuildContext context) async {
    try {
      File? imageFile = await CameraService.captureImage();
      if (imageFile == null) return;

      String? plateNumber = await ALPRService.recognizeLicensePlate(imageFile);
      if (plateNumber == null) return;

      DateTime now = DateTime.now();
      await RemoteDatabaseHelper.insertCar({
        'plate_number': plateNumber,
        'entry_time': now.toIso8601String(),
        'image_path': imageFile.path,
        'status': 'inside'
      });

      _openBarrier();

      // Get settings from remote server
      final settings = await RemoteDatabaseHelper.getSettings();
      final maxStayHours = settings['max_stay_hours'] ?? 8;
      final maxStayMinutes = settings['max_stay_minutes'] ?? 0;
      final maxStayDuration = Duration(hours: maxStayHours, minutes: maxStayMinutes);

      _monitorCarExit(plateNumber, now, maxStayDuration);
    } catch (e) {
      print('Entrance Error: $e');
    }
  }

  static void _openBarrier() {
    print('Barrier opened');
    Future.delayed(Duration(seconds: 5), () {
      print('Barrier closed');
    });
  }

  static void _monitorCarExit(String plateNumber, DateTime entryTime, Duration maxStayDuration) async {
    final randomExitTime = Duration(minutes: 30 + DateTime.now().second);

    await Future.delayed(randomExitTime, () async {
      try {
        DateTime exitTime = DateTime.now();
        Duration duration = exitTime.difference(entryTime);
        String durationStr = '${duration.inHours}h${duration.inMinutes.remainder(60)}m';

        // Get the car from database
        final cars = await RemoteDatabaseHelper.getCarsByPlate(plateNumber);
        final currentCar = cars.firstWhere(
              (car) => car['plate_number'] == plateNumber && car['exit_time'] == null,
          orElse: () => {},
        );

        if (currentCar.isNotEmpty) {
          await RemoteDatabaseHelper.updateCarExit(
              currentCar['id'],
              exitTime.toIso8601String(),
              durationStr
          );
        }

        bool isOverstay = duration.inHours >= maxStayDuration.inHours;

        if (isOverstay) {
          _triggerOverstayAlert(plateNumber, duration);
        }
      } catch (e) {
        print('Error monitoring car exit: $e');
      }
    });
  }

  static void _triggerOverstayAlert(String plateNumber, Duration duration) {
    print('OVERSTAY ALERT: Car $plateNumber has stayed for ${duration.inHours}h${duration.inMinutes.remainder(60)}m');
  }
}
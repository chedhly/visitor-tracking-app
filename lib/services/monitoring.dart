import 'package:flutter/material.dart';
import 'dart:async';
import 'package:visitor_tracking_app/services/data base.dart';
import 'package:visitor_tracking_app/services/entrance.dart';
import 'package:visitor_tracking_app/services/notification_service.dart';

class MonitoringService {
  static Timer? _monitoringTimer;
  static Timer? _overstayCheckTimer;
  static bool _isMonitoring = false;
  static BuildContext? _context;

  static void startMonitoring(BuildContext context) {
    if (_isMonitoring) return;

    _context = context;
    print('Starting car monitoring service...');
    _isMonitoring = true;

    // Check for cars every 30 seconds (simulated)
    _monitoringTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForCars();
    });

    // Check for overstay every 5 minutes
    _overstayCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkForOverstay();
    });
  }

  static void stopMonitoring() {
    print('Stopping car monitoring service...');
    _monitoringTimer?.cancel();
    _overstayCheckTimer?.cancel();
    _isMonitoring = false;
    _context = null;
  }

  static bool isMonitoring() {
    return _isMonitoring;
  }

  static Future<void> _checkForCars() async {
    if (_context == null) return;

    // print('Monitoring active - ${DateTime.now().toString().split('.')[0]}');

    // In a real implementation, this would interface with:
    // - Camera system
    // - Motion sensors
    // - Loop detectors
    // - Manual trigger buttons

    // For demo purposes, we simulate car detection
    // Remove this simulation in production
    // await _simulateCarDetection();
  }

  static Future<void> _simulateCarDetection() async {
    // This is just for testing - remove in production
    final random = DateTime.now().second;
    if (random < 3) { // 3/60 chance per check
      print('Car detected! Processing entrance...');
      await EntranceService.processCarEntrance(_context!);
    }
  }

  static Future<void> _checkForOverstay() async {
    try {
      final carsInside = await RemoteDatabaseHelper.getCarsInsideNow();
      final settings = await RemoteDatabaseHelper.getSettings();

      final maxStayHours = settings['max_stay_hours'] ?? 8;
      final maxStayMinutes = settings['max_stay_minutes'] ?? 0;
      final maxStayDuration = Duration(hours: maxStayHours, minutes: maxStayMinutes);

      for (var car in carsInside) {
        DateTime entryTime = DateTime.parse(car['entry_time']);
        Duration stayDuration = DateTime.now().difference(entryTime);

        if (stayDuration >= maxStayDuration) {
          NotificationService.showOverstayAlert(car['plate_number'], stayDuration);
        }
      }
    } catch (e) {
      print('Error checking overstay: $e');
    }
  }

  static Future<void> manualCarEntry(BuildContext context) async {
    await EntranceService.processCarEntrance(context);
  }

  static Future<List<Map<String, dynamic>>> getOverstayCars() async {
    try {
      final carsInside = await RemoteDatabaseHelper.getCarsInsideNow();
      final settings = await RemoteDatabaseHelper.getSettings();

      final maxStayHours = settings['max_stay_hours'] ?? 8;
      final maxStayMinutes = settings['max_stay_minutes'] ?? 0;
      final maxStayDuration = Duration(hours: maxStayHours, minutes: maxStayMinutes);

      return carsInside.where((car) {
        DateTime entryTime = DateTime.parse(car['entry_time']);
        Duration stayDuration = DateTime.now().difference(entryTime);
        return stayDuration >= maxStayDuration;
      }).toList();
    } catch (e) {
      print('Error getting overstay cars: $e');
      return [];
    }
  }
}
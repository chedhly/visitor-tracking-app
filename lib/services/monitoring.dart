import 'package:flutter/material.dart';
import 'dart:async';
import 'package:visitor_tracking_app/services/setting_provider.dart';
import 'package:provider/provider.dart';
import 'package:visitor_tracking_app/services/data base.dart';
import 'package:visitor_tracking_app/services/entrance.dart';

class MonitoringService {
  static Timer? _monitoringTimer;
  static bool _isMonitoring = false;
  static BuildContext? _context;

  static void startMonitoring(BuildContext context) {
    if (_isMonitoring) return;

    _context = context;
    print('Starting car monitoring service...');
    _isMonitoring = true;

    _monitoringTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkForCars();
    });
  }

  static void stopMonitoring() {
    print('Stopping car monitoring service...');
    _monitoringTimer?.cancel();
    _isMonitoring = false;
    _context = null;
  }

  static bool isMonitoring() {
    return _isMonitoring;
  }

  static Future<void> _checkForCars() async {
    if (_context == null) return;

    print('Checking for cars at ${DateTime.now().toString()}');

    // Simulate car detection (replace with actual camera/ALPR logic)
    final random = DateTime.now().second;
    if (random < 5) {
      print('Car detected! Processing entrance...');
      await EntranceService.processCarEntrance(_context!);
    }
  }

  static int checkOverstay(Duration stayDuration, BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final maxStayDuration = settingsProvider.maxStayDuration;

    return stayDuration.inHours >= maxStayDuration.inHours ? 1 : 0;
  }

  static Future<int> checkOverstayWithoutContext(Duration stayDuration) async {
    if (_context == null) return 0;

    final settingsProvider = Provider.of<SettingsProvider>(_context!, listen: false);
    final maxStayDuration = settingsProvider.maxStayDuration;

    return stayDuration.inHours >= maxStayDuration.inHours ? 1 : 0;
  }
}
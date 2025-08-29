import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static void showOverstayAlert(String plateNumber, Duration duration) {
    print('🚨 OVERSTAY ALERT: Vehicle $plateNumber has exceeded maximum stay time');
    print('Duration: ${duration.inHours}h${duration.inMinutes.remainder(60)}m');

    // Trigger system notification sound
    SystemSound.play(SystemSoundType.alert);

    // Vibrate if available
    HapticFeedback.heavyImpact();
  }

  static void showEntryNotification(String plateNumber) {
    print('✅ Vehicle entered: $plateNumber');
    HapticFeedback.lightImpact();
  }

  static void showExitNotification(String plateNumber, String duration) {
    print('🚗 Vehicle exited: $plateNumber (Duration: $duration)');
    HapticFeedback.lightImpact();
  }

  static void showErrorNotification(String message) {
    print('❌ Error: $message');
    SystemSound.play(SystemSoundType.click);
  }
}
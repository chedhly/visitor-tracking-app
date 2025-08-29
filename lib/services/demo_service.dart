import 'dart:io';
import 'dart:math';

class DemoService {
  static final List<String> _tunisianPlates = [
    '1234 TUNIS 567',
    '2345 ARIANA 678',
    '3456 SFAX 789',
    '4567 NABEUL 890',
    '5678 SOUSSE 123',
    '6789 MONASTIR 234',
    '7890 KAIROUAN 345',
    '8901 BIZERTE 456',
    '9012 GABES 567',
    '1357 TUNIS 890',
    '2468 ARIANA 123',
    '3579 SFAX 456',
  ];

  static String generateRandomTunisianPlate() {
    final random = Random();
    return _tunisianPlates[random.nextInt(_tunisianPlates.length)];
  }

  static Future<String?> simulatePlateRecognition(File imageFile) async {
    // Simulate API processing time
    await Future.delayed(Duration(seconds: 1 + Random().nextInt(3)));

    // Simulate 85% success rate
    if (Random().nextInt(100) < 85) {
      return generateRandomTunisianPlate();
    }

    return null; // Simulate recognition failure
  }

  static bool isDemoMode() {
    // Check if we're in demo mode (no real API key)
    return true; // Set to false when you have a real API key
  }
}
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class LicensePlateRecognition {
  static final _textRecognizer = TextRecognizer();

  static final List<RegExp> _tunisianPlatePatterns = [
    RegExp(r'\b\d{3}\s?[A-Z]{3}\s?\d{3}\b', caseSensitive: false),  // 123 TUN 456
    RegExp(r'\bTN\s?\d{6}\b', caseSensitive: false),                 // TN 123456
    RegExp(r'\b\d{6}\b'),                                            // 123456
    RegExp(r'\b\d{4}\s?TN\s?\d{2}\b', caseSensitive: false),        // 1234 TN 56
  ];

  static final List<String> _commonTunisianCodes = [
    'TUN', 'TN', 'TU', 'ARY', 'BEJ', 'BEN', 'BIZ', 'GAB', 'GAF', 'GBL',
    'JEN', 'KAI', 'KAS', 'KEB', 'KEF', 'MAH', 'MAN', 'MED', 'MON', 'NAB',
    'SFA', 'SID', 'SIL', 'SOU', 'TAT', 'TOZ', 'ZAG'
  ];

  static Future<String?> recognizePlate(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) return null;

      return _extractPlateFromText(recognizedText.text);
    } catch (e) {
      print('Error in plate recognition: $e');
      return null;
    }
  }

  static String? _extractPlateFromText(String text) {
    final cleanText = text.replaceAll(RegExp(r'[^\w\s]'), ' ').toUpperCase();

    // Try each pattern
    for (final pattern in _tunisianPlatePatterns) {
      final matches = pattern.allMatches(cleanText);
      for (final match in matches) {
        final plateText = match.group(0)!.trim();
        if (_isValidTunisianPlate(plateText)) {
          return _formatTunisianPlate(plateText);
        }
      }
    }

    // Try to construct plate from separate parts
    final words = cleanText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    for (int i = 0; i < words.length - 2; i++) {
      final part1 = words[i];
      final part2 = words[i + 1];
      final part3 = words[i + 2];

      if (_isNumeric(part1) &&
          _commonTunisianCodes.contains(part2) &&
          _isNumeric(part3)) {
        final constructedPlate = '$part1 $part2 $part3';
        if (_isValidTunisianPlate(constructedPlate)) {
          return _formatTunisianPlate(constructedPlate);
        }
      }
    }

    // Look for TN followed by 6 digits
    for (int i = 0; i < words.length - 1; i++) {
      if (words[i] == 'TN' && _isNumeric(words[i + 1]) && words[i + 1].length == 6) {
        return 'TN ${words[i + 1]}';
      }
    }

    // Look for standalone 6-digit numbers
    for (final word in words) {
      if (_isNumeric(word) && word.length == 6) {
        return word;
      }
    }

    return null;
  }

  static bool _isNumeric(String str) {
    return RegExp(r'^\d+$').hasMatch(str);
  }

  static bool _isValidTunisianPlate(String plate) {
    final cleanPlate = plate.replaceAll(RegExp(r'\s+'), ' ').trim();
    return _tunisianPlatePatterns.any((pattern) => pattern.hasMatch(cleanPlate));
  }

  static String _formatTunisianPlate(String plate) {
    final cleanPlate = plate.replaceAll(RegExp(r'\s+'), '').toUpperCase();

    // Format 123TUN456 -> 123 TUN 456
    final match1 = RegExp(r'^(\d{3})([A-Z]{2,3})(\d{3})$').firstMatch(cleanPlate);
    if (match1 != null) {
      return '${match1.group(1)} ${match1.group(2)} ${match1.group(3)}';
    }

    // Format TN123456 -> TN 123456
    final match2 = RegExp(r'^(TN)(\d{6})$').firstMatch(cleanPlate);
    if (match2 != null) {
      return '${match2.group(1)} ${match2.group(2)}';
    }

    // Format 1234TN56 -> 1234 TN 56
    final match3 = RegExp(r'^(\d{4})(TN)(\d{2})$').firstMatch(cleanPlate);
    if (match3 != null) {
      return '${match3.group(1)} ${match3.group(2)} ${match3.group(3)}';
    }

    return plate.toUpperCase();
  }

  static void dispose() {
    _textRecognizer.close();
  }
}

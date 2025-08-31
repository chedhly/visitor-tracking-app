import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class TunisianPlateDetector {
  // Tunisian license plate patterns
  static final List<RegExp> _tunisianPatterns = [
    // Standard format: 1234 TUN 567
    RegExp(r'^\d{1,4}\s*[A-Z]{2,6}\s*\d{1,3}$'),
    // Old format: TUN 1234
    RegExp(r'^[A-Z]{2,3}\s*\d{1,4}$'),
    // New format: 123 TUN 4567
    RegExp(r'^\d{1,3}\s*[A-Z]{2,6}\s*\d{1,4}$'),
  ];

  static final List<String> _tunisianRegions = [
    'TUNIS', 'ARIANA', 'SFAX', 'SOUSSE', 'NABEUL', 'MONASTIR',
    'KAIROUAN', 'BIZERTE', 'GABES', 'MEDENINE', 'TATAOUINE',
    'TOZEUR', 'KEBILI', 'GAFSA', 'KASSERINE', 'SIDI', 'JENDOUBA',
    'KEF', 'SILIANA', 'ZAGHOUAN', 'MANOUBA', 'BEN', 'AROUS'
  ];

  static Future<String?> detectTunisianPlate(File imageFile) async {
    try {
      // Read and process the image
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        print('Failed to decode image');
        return null;
      }

      // Preprocess image for better OCR
      img.Image processedImage = _preprocessImage(image);

      // Simulate OCR processing (in real implementation, you'd use actual OCR)
      String? detectedText = await _performOCR(processedImage);

      if (detectedText != null) {
        // Validate and format the detected text as Tunisian plate
        return _validateAndFormatTunisianPlate(detectedText);
      }

      return null;
    } catch (e) {
      print('Error in Tunisian plate detection: $e');
      return null;
    }
  }

  static img.Image _preprocessImage(img.Image image) {
    // Resize image for better processing
    img.Image resized = img.copyResize(image, width: 800);

    // Convert to grayscale
    img.Image grayscale = img.grayscale(resized);

    // Increase contrast
    img.Image contrasted = img.adjustColor(grayscale, contrast: 1.5);

    // Apply brightness adjustment
    img.Image brightened = img.adjustColor(contrasted, brightness: 1.2);

    return brightened;
  }

  static Future<String?> _performOCR(img.Image image) async {
    // This is a simplified simulation of OCR
    // In a real implementation, you would use:
    // - Google ML Kit Text Recognition
    // - Tesseract OCR
    // - Custom trained model for Tunisian plates

    // For demo purposes, simulate detection with random Tunisian plates
    await Future.delayed(Duration(seconds: 2)); // Simulate processing time

    List<String> simulatedPlates = [
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
    ];

    // Simulate 80% success rate
    if (DateTime.now().millisecond % 10 < 8) {
      return simulatedPlates[DateTime.now().millisecond % simulatedPlates.length];
    }

    return null;
  }

  static String? _validateAndFormatTunisianPlate(String detectedText) {
    // Clean the detected text
    String cleaned = detectedText.toUpperCase().trim();
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\s]'), '');

    // Check against Tunisian patterns
    for (RegExp pattern in _tunisianPatterns) {
      if (pattern.hasMatch(cleaned)) {
        // Check if it contains a valid Tunisian region
        bool hasValidRegion = _tunisianRegions.any((region) =>
            cleaned.contains(region));

        if (hasValidRegion) {
          return _formatPlateNumber(cleaned);
        }
      }
    }

    // Try to extract and format even if pattern doesn't match exactly
    return _tryExtractTunisianPlate(cleaned);
  }

  static String _formatPlateNumber(String plateText) {
    // Remove extra spaces and format properly
    List<String> parts = plateText.split(RegExp(r'\s+'));

    if (parts.length >= 3) {
      // Standard format: numbers + region + numbers
      return '${parts[0]} ${parts[1]} ${parts[2]}';
    } else if (parts.length == 2) {
      // Two parts format
      return '${parts[0]} ${parts[1]}';
    }

    return plateText;
  }

  static String? _tryExtractTunisianPlate(String text) {
    // Look for number-letter-number patterns
    RegExp numberLetterNumber = RegExp(r'(\d+)\s*([A-Z]+)\s*(\d+)');
    Match? match = numberLetterNumber.firstMatch(text);

    if (match != null) {
      String numbers1 = match.group(1)!;
      String letters = match.group(2)!;
      String numbers2 = match.group(3)!;

      // Check if letters contain a known Tunisian region
      bool hasValidRegion = _tunisianRegions.any((region) =>
      letters.contains(region) || region.contains(letters));

      if (hasValidRegion) {
        return '$numbers1 $letters $numbers2';
      }
    }

    return null;
  }

  static bool isTunisianPlate(String plateNumber) {
    String cleaned = plateNumber.toUpperCase().trim();

    // Check patterns
    for (RegExp pattern in _tunisianPatterns) {
      if (pattern.hasMatch(cleaned)) {
        return _tunisianRegions.any((region) => cleaned.contains(region));
      }
    }

    return false;
  }
}
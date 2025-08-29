import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:visitor_tracking_app/services/demo_service.dart';
import 'package:image/image.dart' as img;

class OpenALPRService {
  // Using PlateRecognizer API - free tier available (2500 lookups/month)
  static const String apiUrl = 'https://api.platerecognizer.com/v1/plate-reader/';
  static const String apiKey = 'YOUR_FREE_API_TOKEN'; // Get free token from platerecognizer.com
  static const String country = 'tn'; // Tunisia country code

  static Future<String?> recognizeLicensePlate(File imageFile) async {
    // Check if we're in demo mode
    if (DemoService.isDemoMode()) {
      print('Running in demo mode - using simulated plate recognition');
      return await DemoService.simulatePlateRecognition(imageFile);
    }

    try {
      final bytes = await imageFile.readAsBytes();

      // First try with PlateRecognizer (more reliable for Tunisian plates)
      return await recognizeWithPlateRecognizer(imageFile);
    } catch (e) {
      print('ALPR Error: $e');
      return null;
    }
  }

  static String _formatTunisianPlate(String rawPlate) {
    // Remove spaces and special characters
    String cleaned = rawPlate.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');

    // Tunisian plate format: NNNN TUNIS NNN or similar
    // Try to format it properly
    if (cleaned.length >= 7) {
      // Extract numbers and letters
      String numbers1 = cleaned.substring(0, 4);
      String letters = cleaned.substring(4, cleaned.length - 3);
      String numbers2 = cleaned.substring(cleaned.length - 3);

      return '$numbers1 ${letters.toUpperCase()} $numbers2';
    }

    return cleaned.toUpperCase();
  }

  // PlateRecognizer API - free tier: 2500 lookups/month
  static Future<String?> recognizeWithPlateRecognizer(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();

      // Optimize image for better recognition
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize and enhance image for better ALPR performance
      final resizedImage = img.copyResize(image, width: 1024);
      final enhancedImage = img.adjustColor(resizedImage, contrast: 1.2, brightness: 1.1);
      final processedBytes = img.encodeJpg(enhancedImage, quality: 90);

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers['Authorization'] = 'Token $apiKey';
      request.fields['regions'] = country;
      request.fields['camera_id'] = 'entrance_camera';

      request.files.add(http.MultipartFile.fromBytes(
        'upload',
        processedBytes,
        filename: 'plate.jpg',
      ));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        var jsonResponse = json.decode(responseData);

        if (jsonResponse['results'] != null && jsonResponse['results'].isNotEmpty) {
          var result = jsonResponse['results'][0];
          String plateNumber = result['plate'];
          double score = result['score']?.toDouble() ?? 0.0;

          // Only return if confidence is above threshold
          if (score > 0.7) {
            return _formatTunisianPlate(plateNumber);
          }
        }
      } else {
        print('PlateRecognizer API Error: ${response.statusCode}');
        print('Response: $responseData');
      }
    } catch (e) {
      print('PlateRecognizer Error: $e');
    }
    return null;
  }

  // Fallback offline recognition for demo purposes
  static Future<String?> recognizeOffline(File imageFile) async {
    return await DemoService.simulatePlateRecognition(imageFile);
  }
}
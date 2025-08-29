import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

class ALPRService {
  static const String apiUrl = 'https://api.platerecognizer.com/v1/plate-reader/';
  static const String apiKey = 'YOUR_API_KEY';

  static Future<String?> recognizeLicensePlate(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      final resizedImage = img.copyResize(image!, width: 800);
      final processedBytes = img.encodeJpg(resizedImage);
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers['Authorization'] = 'Token $apiKey';
      request.files.add(http.MultipartFile.fromBytes(
        'upload',
        processedBytes,
        filename: 'plate.jpg',
      ));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (jsonResponse['results'] != null && jsonResponse['results'].isNotEmpty) {
        return jsonResponse['results'][0]['plate'];
      }
    } catch (e) {
      print('ALPR Error: $e');
    }
    return null;
  }
}
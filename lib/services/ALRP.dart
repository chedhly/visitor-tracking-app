import 'dart:io';
import 'package:visitor_tracking_app/services/openalpr_service.dart';
import 'package:visitor_tracking_app/services/demo_service.dart';

class ALPRService {

  static Future<String?> recognizeLicensePlate(File imageFile) async {
    // Check if we're in demo mode first
    if (DemoService.isDemoMode()) {
      return await DemoService.simulatePlateRecognition(imageFile);
    }

    // Try PlateRecognizer first (free tier available)
    String? result = await OpenALPRService.recognizeLicensePlate(imageFile);

    // If PlateRecognizer fails, use offline demo recognition
    if (result == null) {
      print('API recognition failed, using offline demo mode');
      result = await DemoService.simulatePlateRecognition(imageFile);
    }

    return result;
  }
}
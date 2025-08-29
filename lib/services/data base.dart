import 'package:visitor_tracking_app/services/API.dart';

class RemoteDatabaseHelper {
  static Future<Map<String, dynamic>?> getUser(String email) async {
    try {
      final response = await ApiService.get('users?email=$email');
      return response;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getCars() async {
    try {
      final response = await ApiService.get('cars');
      return List<Map<String, dynamic>>.from(response['data']);
    } catch (e) {
      print('Error getting cars: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTodayCars() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await ApiService.get('cars?date=$today');
      return List<Map<String, dynamic>>.from(response['data']);
    } catch (e) {
      print('Error getting today\'s cars: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await ApiService.get('settings');
      return response;
    } catch (e) {
      print('Error getting settings: $e');
      return {};
    }
  }

  static Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      await ApiService.put('settings', settings);
    } catch (e) {
      print('Error updating settings: $e');
      throw Exception('Failed to update settings');
    }
  }

  static Future<String> calculateAverageDuration() async {
    try {
      final response = await ApiService.get('cars/average-duration');
      return response['average_duration'] ?? '0h0m';
    } catch (e) {
      print('Error calculating average duration: $e');
      return '0h0m';
    }
  }

  static Future<void> insertCar(Map<String, dynamic> carData) async {
    try {
      await ApiService.post('cars', carData);
    } catch (e) {
      print('Error inserting car: $e');
      throw Exception('Failed to insert car');
    }
  }
  static Future<bool> updateCarExit(int carId, String exitTime, String duration) async {
    try {
      await ApiService.put('cars/$carId', {
        'exit_time': exitTime,
        'duration': duration,
        'status': 'exited'
      });
      return true;
    } catch (e) {
      print('Error updating car exit: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getCarsByPlate(String plateNumber) async {
    try {
      final response = await ApiService.get('cars?plate_number=$plateNumber');
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    } catch (e) {
      print('Error getting cars by plate: $e');
      return [];
    }
  }
}
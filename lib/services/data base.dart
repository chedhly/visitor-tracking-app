import 'mysql_database.dart';


// For backward compatibility, create aliases
class RemoteDatabaseHelper {
  static Future<void> initializeDatabase() async {
    return MySQLDatabaseHelper.initializeDatabase();
  }

  static Future<Map<String, dynamic>?> getUser(String email) async {
    return MySQLDatabaseHelper.getUser(email);
  }

  static Future<void> insertCar(Map<String, dynamic> carData) async {
    return MySQLDatabaseHelper.insertCar(carData);
  }

  static Future<void> updateCarExit(int carId, String exitTime, String duration) async {
    return MySQLDatabaseHelper.updateCarExit(carId, exitTime, duration);
  }

  static Future<List<Map<String, dynamic>>> getCars() async {
    return MySQLDatabaseHelper.getCars();
  }

  static Future<List<Map<String, dynamic>>> getTodayCars() async {
    return MySQLDatabaseHelper.getTodayCars();
  }

  static Future<List<Map<String, dynamic>>> getCarsInsideNow() async {
    return MySQLDatabaseHelper.getCarsInsideNow();
  }

  static Future<List<Map<String, dynamic>>> getCarsByPlate(String plateNumber) async {
    return MySQLDatabaseHelper.getCarsByPlate(plateNumber);
  }

  static Future<Map<String, dynamic>> getSettings() async {
    return MySQLDatabaseHelper.getSettings();
  }

  static Future<void> updateSettings(Map<String, dynamic> settings) async {
    return MySQLDatabaseHelper.updateSettings(settings);
  }

  static Future<String> calculateAverageDuration() async {
    return MySQLDatabaseHelper.calculateAverageDuration();
  }
}
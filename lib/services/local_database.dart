import 'package:shared_preferences/shared_preferences.dart';

class LocalDatabaseHelper {
  static Map<String, dynamic> _cars = {};
  static Map<String, dynamic> _settings = {};
  static int _nextCarId = 1;

  static Future<void> initializeDatabase() async {
    try {
      await _loadData();
      await _initializeDefaultData();
      print('Local database initialized successfully');
    } catch (e) {
      print('Local database initialization error: $e');
    }
  }

  static Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load cars data
    final carsJson = prefs.getString('cars_data') ?? '{}';
    // Simple JSON parsing for demo
    _cars = {};

    // Load settings
    _settings = {
      'max_stay_hours': prefs.getInt('max_stay_hours') ?? 8,
      'max_stay_minutes': prefs.getInt('max_stay_minutes') ?? 0,
      'alert_method': prefs.getString('alert_method') ?? 'sound',
      'language': prefs.getString('language') ?? 'English',
      'theme': prefs.getString('theme') ?? 'light',
      'demo_mode': prefs.getBool('demo_mode') ?? true,
    };

    _nextCarId = prefs.getInt('next_car_id') ?? 1;
  }

  static Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save settings
    await prefs.setInt('max_stay_hours', _settings['max_stay_hours'] ?? 8);
    await prefs.setInt('max_stay_minutes', _settings['max_stay_minutes'] ?? 0);
    await prefs.setString('alert_method', _settings['alert_method'] ?? 'sound');
    await prefs.setString('language', _settings['language'] ?? 'English');
    await prefs.setString('theme', _settings['theme'] ?? 'light');
    await prefs.setBool('demo_mode', _settings['demo_mode'] ?? true);
    await prefs.setInt('next_car_id', _nextCarId);
  }

  static Future<void> _initializeDefaultData() async {
    // Add default user
    if (!_cars.containsKey('users')) {
      _cars['users'] = {
        '1': {
          'id': 1,
          'email': 'admin@draexlmaier.com',
          'password': 'admin123',
          'name': 'System Administrator',
        }
      };
    }

    // Initialize cars list if empty
    if (!_cars.containsKey('vehicles')) {
      _cars['vehicles'] = {};
    }

    await _saveData();
  }

  static Future<Map<String, dynamic>?> getUser(String email) async {
    try {
      final users = _cars['users'] as Map<String, dynamic>? ?? {};

      for (var userData in users.values) {
        if (userData['email'] == email) {
          return Map<String, dynamic>.from(userData);
        }
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  static Future<void> insertCar(Map<String, dynamic> carData) async {
    try {
      final vehicles = _cars['vehicles'] as Map<String, dynamic>? ?? {};

      final carId = _nextCarId++;
      vehicles[carId.toString()] = {
        'id': carId,
        'plate_number': carData['plate_number'],
        'entry_time': carData['entry_time'],
        'exit_time': carData['exit_time'],
        'duration': carData['duration'],
        'status': carData['status'] ?? 'inside',
        'image_path': carData['image_path'] ?? '',
        'confidence_score': carData['confidence_score'] ?? 0.0,
        'detection_method': carData['detection_method'] ?? 'manual',
        'created_at': DateTime.now().toIso8601String(),
      };

      _cars['vehicles'] = vehicles;
      await _saveData();
    } catch (e) {
      print('Error inserting car: $e');
      throw Exception('Failed to insert car data');
    }
  }

  static Future<void> updateCarExit(int carId, String exitTime, String duration) async {
    try {
      final vehicles = _cars['vehicles'] as Map<String, dynamic>? ?? {};

      if (vehicles.containsKey(carId.toString())) {
        vehicles[carId.toString()]['exit_time'] = exitTime;
        vehicles[carId.toString()]['duration'] = duration;
        vehicles[carId.toString()]['status'] = 'exited';
        vehicles[carId.toString()]['updated_at'] = DateTime.now().toIso8601String();

        _cars['vehicles'] = vehicles;
        await _saveData();
      }
    } catch (e) {
      print('Error updating car exit: $e');
      throw Exception('Failed to update car exit');
    }
  }

  static Future<List<Map<String, dynamic>>> getCars() async {
    try {
      final vehicles = _cars['vehicles'] as Map<String, dynamic>? ?? {};

      List<Map<String, dynamic>> carsList = [];
      for (var carData in vehicles.values) {
        carsList.add(Map<String, dynamic>.from(carData));
      }

      // Sort by entry time (newest first)
      carsList.sort((a, b) {
        DateTime aTime = DateTime.parse(a['entry_time']);
        DateTime bTime = DateTime.parse(b['entry_time']);
        return bTime.compareTo(aTime);
      });

      return carsList;
    } catch (e) {
      print('Error getting cars: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTodayCars() async {
    try {
      final allCars = await getCars();
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      return allCars.where((car) {
        DateTime entryTime = DateTime.parse(car['entry_time']);
        return entryTime.isAfter(startOfDay) && entryTime.isBefore(endOfDay);
      }).toList();
    } catch (e) {
      print('Error getting today\'s cars: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCarsInsideNow() async {
    try {
      final allCars = await getCars();
      return allCars.where((car) => car['status'] == 'inside').toList();
    } catch (e) {
      print('Error getting cars inside: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCarsByPlate(String plateNumber) async {
    try {
      final allCars = await getCars();
      return allCars.where((car) =>
      car['plate_number'].toString().toLowerCase() == plateNumber.toLowerCase()
      ).toList();
    } catch (e) {
      print('Error getting cars by plate: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getSettings() async {
    await _loadData();
    return Map<String, dynamic>.from(_settings);
  }

  static Future<void> updateSettings(Map<String, dynamic> newSettings) async {
    try {
      _settings.addAll(newSettings);
      await _saveData();
    } catch (e) {
      print('Error updating settings: $e');
      throw Exception('Failed to update settings');
    }
  }

  static Future<String> calculateAverageDuration() async {
    try {
      final allCars = await getCars();
      final exitedCars = allCars.where((car) =>
      car['exit_time'] != null && car['duration'] != null
      ).toList();

      if (exitedCars.isEmpty) return '0h0m';

      int totalMinutes = 0;
      int count = 0;

      for (var car in exitedCars) {
        DateTime entryTime = DateTime.parse(car['entry_time']);
        DateTime exitTime = DateTime.parse(car['exit_time']);
        Duration duration = exitTime.difference(entryTime);
        totalMinutes += duration.inMinutes;
        count++;
      }

      if (count == 0) return '0h0m';

      int avgMinutes = totalMinutes ~/ count;
      int hours = avgMinutes ~/ 60;
      int minutes = avgMinutes % 60;

      return '${hours}h${minutes}m';
    } catch (e) {
      print('Error calculating average duration: $e');
      return '0h0m';
    }
  }

  static Future<void> closeConnection() async {
    await _saveData();
  }
}
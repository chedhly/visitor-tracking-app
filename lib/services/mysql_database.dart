import 'package:mysql1/mysql1.dart';
import 'package:visitor_tracking_app/services/database_setup.dart';
import 'package:visitor_tracking_app/services/local_database.dart';

class MySQLDatabaseHelper {
  static MySqlConnection? _connection;
  static bool _useLocalFallback = false;

  static final ConnectionSettings _settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'root',
    password: 'root',
    db: 'visitor_tracking_db',
  );

  static Future<void> initializeDatabase() async {
    try {
      // Setup database and tables first
      await DatabaseSetup.setupDatabase();
      await DatabaseSetup.createTables();

      _connection = await MySqlConnection.connect(_settings);
      print('Connected to MySQL database');
    } catch (e) {
      print('Database connection error: $e');
      // For development, we'll use a fallback local database
      print('Falling back to local SQLite database');
      await LocalDatabaseHelper.initializeDatabase();
    }
  }

  static Future<void> _createTables() async {
    try {
      // Create users table
      await _connection!.query('''
        CREATE TABLE IF NOT EXISTS users (
          id INT AUTO_INCREMENT PRIMARY KEY,
          email VARCHAR(255) UNIQUE NOT NULL,
          password VARCHAR(255) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Create cars table
      await _connection!.query('''
        CREATE TABLE IF NOT EXISTS cars (
          id INT AUTO_INCREMENT PRIMARY KEY,
          plate_number VARCHAR(50) NOT NULL,
          entry_time DATETIME NOT NULL,
          exit_time DATETIME NULL,
          duration VARCHAR(20) NULL,
          status ENUM('inside', 'exited') DEFAULT 'inside',
          image_path VARCHAR(500) NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Create settings table
      await _connection!.query('''
        CREATE TABLE IF NOT EXISTS settings (
          id INT AUTO_INCREMENT PRIMARY KEY,
          max_stay_hours INT DEFAULT 8,
          max_stay_minutes INT DEFAULT 0,
          alert_method VARCHAR(20) DEFAULT 'sound',
          language VARCHAR(20) DEFAULT 'English',
          theme VARCHAR(20) DEFAULT 'light',
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
      ''');

      // Insert default user if not exists
      var userResult = await _connection!.query('SELECT COUNT(*) as count FROM users');
      if (userResult.first['count'] == 0) {
        await _connection!.query('''
          INSERT INTO users (email, password) VALUES ('admin@example.com', 'admin123')
        ''');
      }

      // Insert default settings if not exists
      var settingsResult = await _connection!.query('SELECT COUNT(*) as count FROM settings');
      if (settingsResult.first['count'] == 0) {
        await _connection!.query('''
          INSERT INTO settings (max_stay_hours, max_stay_minutes, alert_method, language, theme) 
          VALUES (8, 0, 'sound', 'English', 'light')
        ''');
      }

      print('Database tables created successfully');
    } catch (e) {
      print('Error creating tables: $e');
      throw Exception('Failed to create database tables');
    }
  }

  static Future<Map<String, dynamic>?> getUser(String email) async {
    try {
      if (_useLocalFallback) {
        return await LocalDatabaseHelper.getUser(email);
      }

      var results = await _connection!.query(
          'SELECT * FROM users WHERE email = ?',
          [email]
      );

      if (results.isNotEmpty) {
        var row = results.first;
        return {
          'id': row['id'],
          'email': row['email'],
          'password': row['password'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  static Future<void> insertCar(Map<String, dynamic> carData) async {
    try {
      if (_useLocalFallback) {
        return await LocalDatabaseHelper.insertCar(carData);
      }

      await _connection!.query('''
        INSERT INTO cars (plate_number, entry_time, image_path, status, confidence_score, detection_method) 
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [
        carData['plate_number'],
        carData['entry_time'],
        carData['image_path'] ?? '',
        carData['status'] ?? 'inside',
        carData['confidence_score'] ?? 0.0,
        carData['detection_method'] ?? 'manual'
      ]);
    } catch (e) {
      print('Error inserting car: $e');
      throw Exception('Failed to insert car data');
    }
  }

  static Future<void> updateCarExit(int carId, String exitTime, String duration) async {
    try {
      await _connection!.query('''
        UPDATE cars SET exit_time = ?, duration = ?, status = 'exited' 
        WHERE id = ?
      ''', [exitTime, duration, carId]);
    } catch (e) {
      print('Error updating car exit: $e');
      throw Exception('Failed to update car exit');
    }
  }

  static Future<List<Map<String, dynamic>>> getCars() async {
    try {
      var results = await _connection!.query('SELECT * FROM cars ORDER BY entry_time DESC');
      return results.map((row) => {
        'id': row['id'],
        'plate_number': row['plate_number'],
        'entry_time': row['entry_time'].toString(),
        'exit_time': row['exit_time']?.toString(),
        'duration': row['duration'],
        'status': row['status'],
        'image_path': row['image_path'],
      }).toList();
    } catch (e) {
      print('Error getting cars: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getTodayCars() async {
    try {
      var today = DateTime.now();
      var startOfDay = DateTime(today.year, today.month, today.day);
      var endOfDay = startOfDay.add(Duration(days: 1));

      var results = await _connection!.query('''
        SELECT * FROM cars 
        WHERE entry_time >= ? AND entry_time < ? 
        ORDER BY entry_time DESC
      ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

      return results.map((row) => {
        'id': row['id'],
        'plate_number': row['plate_number'],
        'entry_time': row['entry_time'].toString(),
        'exit_time': row['exit_time']?.toString(),
        'duration': row['duration'],
        'status': row['status'],
      }).toList();
    } catch (e) {
      print('Error getting today\'s cars: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCarsInsideNow() async {
    try {
      var results = await _connection!.query('''
        SELECT * FROM cars WHERE status = 'inside' ORDER BY entry_time DESC
      ''');

      return results.map((row) => {
        'id': row['id'],
        'plate_number': row['plate_number'],
        'entry_time': row['entry_time'].toString(),
        'status': row['status'],
      }).toList();
    } catch (e) {
      print('Error getting cars inside: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getCarsByPlate(String plateNumber) async {
    try {
      var results = await _connection!.query(
          'SELECT * FROM cars WHERE plate_number = ? ORDER BY entry_time DESC',
          [plateNumber]
      );

      return results.map((row) => {
        'id': row['id'],
        'plate_number': row['plate_number'],
        'entry_time': row['entry_time'].toString(),
        'exit_time': row['exit_time']?.toString(),
        'duration': row['duration'],
        'status': row['status'],
      }).toList();
    } catch (e) {
      print('Error getting cars by plate: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getSettings() async {
    try {
      var results = await _connection!.query('''
        SELECT setting_key, setting_value, setting_type 
        FROM settings 
        ORDER BY setting_key
      ''');

      Map<String, dynamic> settings = {};

      for (var row in results) {
        String key = row['setting_key'];
        String value = row['setting_value'];
        String type = row['setting_type'];

        switch (type) {
          case 'integer':
            settings[key] = int.tryParse(value) ?? 0;
            break;
          case 'boolean':
            settings[key] = value.toLowerCase() == 'true';
            break;
          case 'json':
          // Handle JSON if needed
            settings[key] = value;
            break;
          default:
            settings[key] = value;
        }
      }

      // Ensure required settings exist with defaults
      settings.putIfAbsent('max_stay_hours', () => 8);
      settings.putIfAbsent('max_stay_minutes', () => 0);
      settings.putIfAbsent('alert_method', () => 'sound');
      settings.putIfAbsent('language', () => 'English');
      settings.putIfAbsent('theme', () => 'light');
      settings.putIfAbsent('demo_mode', () => true);

      return settings;
    } catch (e) {
      print('Error getting settings: $e');
      return {
        'max_stay_hours': 8,
        'max_stay_minutes': 0,
        'alert_method': 'sound',
        'language': 'English',
        'theme': 'light',
        'demo_mode': true,
      };
    }
  }

  static Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      for (String key in settings.keys) {
        var value = settings[key];
        String stringValue;
        String type;

        if (value is int) {
          stringValue = value.toString();
          type = 'integer';
        } else if (value is bool) {
          stringValue = value.toString();
          type = 'boolean';
        } else {
          stringValue = value.toString();
          type = 'string';
        }

        await _connection!.query('''
          INSERT INTO settings (setting_key, setting_value, setting_type) 
          VALUES (?, ?, ?)
          ON DUPLICATE KEY UPDATE 
          setting_value = VALUES(setting_value),
          setting_type = VALUES(setting_type),
          updated_at = CURRENT_TIMESTAMP
        ''', [key, stringValue, type]);
      }
    } catch (e) {
      print('Error updating settings: $e');
      throw Exception('Failed to update settings');
    }
  }

  static Future<String> calculateAverageDuration() async {
    try {
      var results = await _connection!.query('''
        SELECT AVG(TIMESTAMPDIFF(MINUTE, entry_time, exit_time)) as avg_minutes 
        FROM cars 
        WHERE exit_time IS NOT NULL
      ''');

      if (results.isNotEmpty && results.first['avg_minutes'] != null) {
        int avgMinutes = results.first['avg_minutes'].round();
        int hours = avgMinutes ~/ 60;
        int minutes = avgMinutes % 60;
        return '${hours}h${minutes}m';
      }

      return '0h0m';
    } catch (e) {
      print('Error calculating average duration: $e');
      return '0h0m';
    }
  }

  static Future<void> closeConnection() async {
    await _connection?.close();
    _connection = null;
  }
}
import 'package:mysql1/mysql1.dart';

class MySQLDatabaseHelper {
  static MySqlConnection? _connection;

  static final ConnectionSettings _settings = ConnectionSettings(
    host: 'localhost',
    port: 3306,
    user: 'visitor_app',
    password: '',
    db: 'visitor_tracking_db',
  );

  static Future<void> initializeDatabase() async {
    try {
      _connection = await MySqlConnection.connect(_settings);
      print('Connected to MySQL database');
      await _createTables();
    } catch (e) {
      print('Database connection error: $e');
      throw Exception('Failed to connect to database');
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
      await _connection!.query('''
        INSERT INTO cars (plate_number, entry_time, image_path, status) 
        VALUES (?, ?, ?, ?)
      ''', [
        carData['plate_number'],
        carData['entry_time'],
        carData['image_path'] ?? '',
        carData['status'] ?? 'inside'
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
      var results = await _connection!.query('SELECT * FROM settings LIMIT 1');

      if (results.isNotEmpty) {
        var row = results.first;
        return {
          'max_stay_hours': row['max_stay_hours'],
          'max_stay_minutes': row['max_stay_minutes'],
          'alert_method': row['alert_method'],
          'language': row['language'],
          'theme': row['theme'],
        };
      }

      // Return defaults if no settings found
      return {
        'max_stay_hours': 8,
        'max_stay_minutes': 0,
        'alert_method': 'sound',
        'language': 'English',
        'theme': 'light',
      };
    } catch (e) {
      print('Error getting settings: $e');
      return {
        'max_stay_hours': 8,
        'max_stay_minutes': 0,
        'alert_method': 'sound',
        'language': 'English',
        'theme': 'light',
      };
    }
  }

  static Future<void> updateSettings(Map<String, dynamic> settings) async {
    try {
      await _connection!.query('''
        UPDATE settings SET 
          max_stay_hours = ?, 
          max_stay_minutes = ?, 
          alert_method = ?, 
          language = ?, 
          theme = ?,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = 1
      ''', [
        settings['max_stay_hours'],
        settings['max_stay_minutes'],
        settings['alert_method'],
        settings['language'],
        settings['theme'],
      ]);
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
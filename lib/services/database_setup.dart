import 'package:mysql1/mysql1.dart';

class DatabaseSetup {
  static Future<void> setupDatabase() async {
    try {
      // First connect without specifying database to create it if needed
      final connectionSettings = ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: 'root',
        password: 'root',
      );

      final connection = await MySqlConnection.connect(connectionSettings);

      // Create database if it doesn't exist
      await connection.query('CREATE DATABASE IF NOT EXISTS visitor_tracking_db');
      await connection.close();

      print('Database setup completed successfully');
    } catch (e) {
      print('Database setup error: $e');
      throw Exception('Failed to setup database: $e');
    }
  }

  static Future<void> createTables() async {
    try {
      final connectionSettings = ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: 'root',
        password: 'root',
        db: 'visitor_tracking_db',
      );

      final connection = await MySqlConnection.connect(connectionSettings);

      // Create users table
      await connection.query('''
        CREATE TABLE IF NOT EXISTS users (
          id INT AUTO_INCREMENT PRIMARY KEY,
          email VARCHAR(255) UNIQUE NOT NULL,
          password VARCHAR(255) NOT NULL,
          name VARCHAR(255) DEFAULT 'Admin User',
          role VARCHAR(50) DEFAULT 'admin',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      ''');

      // Create cars table with enhanced structure
      await connection.query('''
        CREATE TABLE IF NOT EXISTS cars (
          id INT AUTO_INCREMENT PRIMARY KEY,
          plate_number VARCHAR(50) NOT NULL,
          entry_time DATETIME NOT NULL,
          exit_time DATETIME NULL,
          duration VARCHAR(20) NULL,
          status ENUM('inside', 'exited') DEFAULT 'inside',
          image_path VARCHAR(500) NULL,
          confidence_score DECIMAL(5,2) DEFAULT 0.00,
          detection_method ENUM('camera', 'manual', 'openalpr') DEFAULT 'manual',
          notes TEXT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
          INDEX idx_plate_number (plate_number),
          INDEX idx_entry_time (entry_time),
          INDEX idx_status (status),
          INDEX idx_created_at (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      ''');

      // Create settings table
      await connection.query('''
        CREATE TABLE IF NOT EXISTS settings (
          id INT AUTO_INCREMENT PRIMARY KEY,
          setting_key VARCHAR(100) UNIQUE NOT NULL,
          setting_value TEXT NOT NULL,
          setting_type ENUM('string', 'integer', 'boolean', 'json') DEFAULT 'string',
          description TEXT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      ''');

      // Create alerts table for overstay tracking
      await connection.query('''
        CREATE TABLE IF NOT EXISTS alerts (
          id INT AUTO_INCREMENT PRIMARY KEY,
          car_id INT NOT NULL,
          alert_type ENUM('overstay', 'entry', 'exit') NOT NULL,
          message TEXT NOT NULL,
          is_read BOOLEAN DEFAULT FALSE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE,
          INDEX idx_car_id (car_id),
          INDEX idx_alert_type (alert_type),
          INDEX idx_created_at (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
      ''');

      // Insert default admin user
      await connection.query('''
        INSERT IGNORE INTO users (email, password, name, role) 
        VALUES ('admin@draexlmaier.com', 'admin123', 'System Administrator', 'admin')
      ''');

      // Insert default settings
      final defaultSettings = [
        ['max_stay_hours', '8', 'integer', 'Maximum stay time in hours'],
        ['max_stay_minutes', '0', 'integer', 'Maximum stay time additional minutes'],
        ['alert_method', 'sound', 'string', 'Alert notification method'],
        ['language', 'English', 'string', 'Application language'],
        ['theme', 'light', 'string', 'Application theme'],
        ['api_provider', 'platerecognizer', 'string', 'ALPR API provider'],
        ['api_token', '', 'string', 'API token for ALPR service'],
        ['demo_mode', 'true', 'boolean', 'Enable demo mode for testing'],
        ['camera_enabled', 'true', 'boolean', 'Enable camera functionality'],
        ['auto_barrier', 'false', 'boolean', 'Automatically open barrier'],
      ];

      for (final setting in defaultSettings) {
        await connection.query('''
          INSERT IGNORE INTO settings (setting_key, setting_value, setting_type, description) 
          VALUES (?, ?, ?, ?)
        ''', setting);
      }

      await connection.close();
      print('Database tables created successfully');
    } catch (e) {
      print('Error creating tables: $e');
      throw Exception('Failed to create database tables: $e');
    }
  }
}
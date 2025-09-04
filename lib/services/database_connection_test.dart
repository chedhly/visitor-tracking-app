import 'package:mysql1/mysql1.dart';

class DatabaseConnectionTest {
  static Future<bool> testConnection() async {
    try {
      print('Testing database connection...');

      final settings = ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: 'root',
        password: 'root',
        db: 'visitor_tracking_db',
      );

      final connection = await MySqlConnection.connect(settings);

      // Test basic query
      final result = await connection.query('SELECT 1 as test');
      await connection.close();

      print('✅ Database connection successful!');
      return true;
    } catch (e) {
      print('❌ Database connection failed: $e');
      print('');
      print('Please ensure:');
      print('1. XAMPP/WAMP/MAMP is running');
      print('2. MySQL service is started');
      print('3. phpMyAdmin is accessible at http://localhost/phpmyadmin');
      print('4. Database "visitor_tracking_db" exists');
      print('5. MySQL user "root" with password "root" has access');
      print('');
      return false;
    }
  }

  static Future<void> createDatabaseIfNeeded() async {
    try {
      // Connect without database to create it
      final settings = ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: 'root',
        password: 'root',
      );

      final connection = await MySqlConnection.connect(settings);

      await connection.query('CREATE DATABASE IF NOT EXISTS visitor_tracking_db');
      await connection.close();

      print('✅ Database "visitor_tracking_db" created/verified');
    } catch (e) {
      print('❌ Failed to create database: $e');
      throw e;
    }
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visitor_tracking_app/pages/home.dart';
import 'package:visitor_tracking_app/pages/history.dart';
import 'package:visitor_tracking_app/pages/setting.dart';
import 'package:visitor_tracking_app/pages/todaycar.dart';
import 'package:visitor_tracking_app/services/setting_provider.dart';
import 'package:visitor_tracking_app/pages/login.dart';
import 'package:visitor_tracking_app/services/mysql_database.dart';
import 'package:visitor_tracking_app/services/database_connection_test.dart';
import 'package:visitor_tracking_app/services/pc_camera_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  // Test and initialize database connection
  try {
    print('🔄 Initializing database connection...');
    await DatabaseConnectionTest.createDatabaseIfNeeded();
    bool connectionOk = await DatabaseConnectionTest.testConnection();

    if (connectionOk) {
      print('🔄 Setting up database tables...');
    }

    await MySQLDatabaseHelper.initializeDatabase();
    print('✅ Database system ready!');
  } catch (e) {
    print('❌ Database initialization failed: $e');
    print('📱 App will continue with limited functionality');
  }

  // Initialize camera
  try {
    print('🔄 Initializing camera...');
    await PCCameraService.initializeCamera();
    print('✅ Camera ready!');
  } catch (e) {
    print('⚠️ Camera initialization failed: $e');
    print('📱 Manual entry will still work');
  }

  print('🚀 Starting Visitor Tracking App...');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: MaterialApp(
        title: 'Visitor Tracking App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto-Regular',
        ),
        initialRoute: '/home',
        routes: {
          '/': (context) => const Login(),
          '/home': (context) => const Home(),
          '/today': (context) => const Tcar(),
          '/history': (context) => const History(),
          '/setting': (context) => const Setting(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
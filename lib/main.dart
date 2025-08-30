import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:visitor_tracking_app/pages/home.dart';
import 'package:visitor_tracking_app/pages/history.dart';
import 'package:visitor_tracking_app/pages/setting.dart';
import 'package:visitor_tracking_app/pages/todaycar.dart';
import 'package:visitor_tracking_app/services/setting_provider.dart';
import 'package:visitor_tracking_app/pages/login.dart';
import 'package:visitor_tracking_app/services/mysql_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize database
  MySQLDatabaseHelper.initializeDatabase();
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
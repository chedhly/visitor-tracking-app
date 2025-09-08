import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/manual_entry_screen.dart';
import 'screens/history_screen.dart';
import 'screens/today_cars_screen.dart';
import 'screens/settings_screen.dart';
import 'services/visitor_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'postgresql://postgres:[PFAdrax25]@db.ajzzdwpjsmmxwwuuktpg.supabase.co:5432/postgres',
    anonKey: 'PFAdrax25',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VisitorService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'Visitor Tracking',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: Color(0xFF2196F3),
              brightness: settings.isDarkMode ? Brightness.dark : Brightness.light,
              fontFamily: 'Roboto',
            ),
            home: HomeScreen(),
            debugShowCheckedModeBanner: false,
            routes: {
              '/camera': (context) => CameraScreen(),
              '/manual-entry': (context) => ManualEntryScreen(),
              '/history': (context) => HistoryScreen(),
              '/today-cars': (context) => TodayCarsScreen(),
              '/settings': (context) => SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
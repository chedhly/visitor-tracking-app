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

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Missing Supabase credentials. Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
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
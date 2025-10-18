import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/visitor_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = 'https://0ec90b57d6e95fcbda19832f.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJib2x0IiwicmVmIjoiMGVjOTBiNTdkNmU5NWZjYmRhMTk4MzJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4ODE1NzQsImV4cCI6MTc1ODg4MTU3NH0.9I8-U0x86Ak8t2DGaIk0HfvTSLsAyzdnz-Nw00mMkKw';

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    print('Supabase initialization error: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => VisitorService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, child) {
          return MaterialApp(
            title: 'Vehicle Entry System',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: Color(0xFF2196F3),
              brightness: Brightness.light,
              fontFamily: 'Roboto',
            ),
            home: authService.isLoggedIn ? HomeScreen() : LoginScreen(),
            debugShowCheckedModeBanner: false,
            routes: {
              '/login': (context) => LoginScreen(),
              '/home': (context) => HomeScreen(),
            },
          );
        },
      ),
    );
  }
}

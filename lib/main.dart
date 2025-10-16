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

  const supabaseUrl = String.fromEnvironment(
   "https://dpnpibatsyvedyjxiqdc.supabase.co"
  );
  const supabaseAnonKey = String.fromEnvironment(
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwbnBpYmF0c3l2ZWR5anhpcWRjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2MDIwODQsImV4cCI6MjA3NjE3ODA4NH0.EzmI3P-VNhuHsvGYXPOYyNo7ftbuJxAbM8oeiZ2GRYU"
  );

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    } catch (e) {
      print('Supabase initialization error: $e');
    }
  } else {
    print('Warning: Supabase credentials not set. Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.');
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

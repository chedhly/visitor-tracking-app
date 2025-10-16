import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/personnel.dart';

class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  Personnel? _currentUser;
  bool _isLoading = false;

  Personnel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('personnel')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        throw Exception('Invalid email or password');
      }

      _currentUser = Personnel.fromJson(response);
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}

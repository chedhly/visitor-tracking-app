import 'package:flutter/foundation.dart';
import 'package:visitor_tracking_app/services/data base.dart';

class SettingsProvider with ChangeNotifier {
  final RemoteDatabaseHelper _dbHelper = RemoteDatabaseHelper();

  int _maxStayHours = 8;
  int _maxStayMinutes = 0;
  String _alertMethod = 'sound';
  String _selectedLanguage = 'English';
  String _selectedTheme = 'light';

  int get maxStayHours => _maxStayHours;
  int get maxStayMinutes => _maxStayMinutes;
  String get alertMethod => _alertMethod;
  String get selectedLanguage => _selectedLanguage;
  String get selectedTheme => _selectedTheme;

  Duration get maxStayDuration => Duration(
    hours: _maxStayHours,
    minutes: _maxStayMinutes,
  );

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _dbHelper.getSettings();

      // Handle different response structures
      if (settings.containsKey('data')) {
        // If settings are nested under 'data' key
        final data = settings['data'] as Map<String, dynamic>;
        _maxStayHours = data['max_stay_hours'] ?? 8;
        _maxStayMinutes = data['max_stay_minutes'] ?? 0;
        _alertMethod = data['alert_method'] ?? 'sound';
        _selectedLanguage = data['language'] ?? 'English';
        _selectedTheme = data['theme'] ?? 'light';
      } else {
        // If settings are at the root level
        _maxStayHours = settings['max_stay_hours'] ?? 8;
        _maxStayMinutes = settings['max_stay_minutes'] ?? 0;
        _alertMethod = settings['alert_method'] ?? 'sound';
        _selectedLanguage = settings['language'] ?? 'English';
        _selectedTheme = settings['theme'] ?? 'light';
      }

      notifyListeners();
    } catch (e) {
      print('Error loading settings: $e');
      // Use default values if loading fails
      notifyListeners();
    }
  }

  Future<void> updateSettings({
    int? maxStayHours,
    int? maxStayMinutes,
    String? alertMethod,
    String? language,
    String? theme,
  }) async {
    if (maxStayHours != null) _maxStayHours = maxStayHours;
    if (maxStayMinutes != null) _maxStayMinutes = maxStayMinutes;
    if (alertMethod != null) _alertMethod = alertMethod;
    if (language != null) _selectedLanguage = language;
    if (theme != null) _selectedTheme = theme;

    try {
      await _dbHelper.updateSettings({
        'max_stay_hours': _maxStayHours,
        'max_stay_minutes': _maxStayMinutes,
        'alert_method': _alertMethod,
        'language': _selectedLanguage,
        'theme': _selectedTheme,
      });
    } catch (e) {
      print('Error updating settings: $e');
      // Revert changes if update fails
      await _loadSettings();
      throw Exception('Failed to update settings');
    }

    notifyListeners();
  }
}
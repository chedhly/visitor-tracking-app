import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_settings.dart';

class SettingsService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  AppSettings? _settings;
  bool _isLoading = false;

  AppSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  int get overstayThresholdHours => _settings?.overstayThresholdHours ?? 8;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('settings')
          .select()
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _settings = AppSettings.fromJson(response);
      }
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOverstayThreshold(int hours, String personnelId) async {
    try {
      await _supabase
          .from('settings')
          .update({
            'overstay_threshold_hours': hours,
            'updated_at': DateTime.now().toIso8601String(),
            'updated_by': personnelId,
          })
          .eq('id', _settings!.id);

      await loadSettings();
      return true;
    } catch (e) {
      print('Error updating settings: $e');
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/visitor.dart';

class VisitorService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<Visitor> _visitors = [];
  bool _isLoading = false;

  List<Visitor> get visitors => _visitors;
  bool get isLoading => _isLoading;

  Future<void> recordEntry(String plateNumber) async {
    try {
      // Check if vehicle is already inside
      final existing = await _supabase
          .from('visitors')
          .select()
          .eq('plate_number', plateNumber)
          .filter('exit_time', 'is', null)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Vehicle is already inside');
      }

      // Record new entry
      await _supabase.from('visitors').insert({
        'plate_number': plateNumber,
        'entry_time': DateTime.now().toIso8601String(),
      });

      await loadVisitors();
    } catch (e) {
      throw Exception('Failed to record entry: $e');
    }
  }

  Future<void> recordExit(String plateNumber) async {
    try {
      final visitor = await _supabase
          .from('visitors')
          .select()
          .eq('plate_number', plateNumber)
          .filter('exit_time', 'is', null)
          .single();

      await _supabase
          .from('visitors')
          .update({
        'exit_time': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      })
          .eq('id', visitor['id']);

      await loadVisitors();
    } catch (e) {
      throw Exception('Failed to record exit: $e');
    }
  }

  Future<void> loadVisitors() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('visitors')
          .select()
          .order('entry_time', ascending: false);

      _visitors = response.map<Visitor>((json) => Visitor.fromJson(json)).toList();
    } catch (e) {
      print('Error loading visitors: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Visitor> getTodayVisitors() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _visitors.where((visitor) =>
        visitor.entryTime.isAfter(startOfDay)).toList();
  }

  VisitorStatistics getTodayStatistics() {
    final todayVisitors = getTodayVisitors();
    final insideNow = todayVisitors.where((v) => v.exitTime == null).length;

    // Calculate overstay (vehicles inside longer than 8 hours)
    final overStay = todayVisitors.where((v) {
      if (v.exitTime != null) return false;
      final duration = DateTime.now().difference(v.entryTime);
      return duration.inHours > 8;
    }).length;

    // Calculate average duration
    final completedVisits = todayVisitors.where((v) => v.exitTime != null).toList();
    String averageDuration = '0h0m';

    if (completedVisits.isNotEmpty) {
      final totalMinutes = completedVisits
          .map((v) => v.exitTime!.difference(v.entryTime).inMinutes)
          .reduce((a, b) => a + b);
      final avgMinutes = totalMinutes ~/ completedVisits.length;
      final hours = avgMinutes ~/ 60;
      final minutes = avgMinutes % 60;
      averageDuration = '${hours}h${minutes}m';
    }

    return VisitorStatistics(
      todayCount: todayVisitors.length,
      insideNow: insideNow,
      overStay: overStay,
      averageDuration: averageDuration,
    );
  }
}

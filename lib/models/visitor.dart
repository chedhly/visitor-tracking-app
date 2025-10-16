class Visitor {
  final String id;
  final String plateNumber;
  final DateTime entryTime;
  final DateTime? exitTime;
  final int? durationMinutes;

  Visitor({
    required this.id,
    required this.plateNumber,
    required this.entryTime,
    this.exitTime,
    this.durationMinutes,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'].toString(),
      plateNumber: json['plate_number'],
      entryTime: DateTime.parse(json['entry_time']),
      exitTime: json['exit_time'] != null
          ? DateTime.parse(json['exit_time'])
          : null,
      durationMinutes: json['duration_minutes'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate_number': plateNumber,
      'entry_time': entryTime.toIso8601String(),
      'exit_time': exitTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
    };
  }

  bool get isInside => exitTime == null;
  
  Duration get timeInside {
    if (exitTime != null) {
      return exitTime!.difference(entryTime);
    }
    return DateTime.now().difference(entryTime);
  }

  String get durationFormatted {
    final duration = timeInside;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  bool isOverstay(int thresholdHours) {
    return isInside && timeInside.inHours >= thresholdHours;
  }
}

class VisitorStatistics {
  final int todayCount;
  final int insideNow;
  final int overStay;
  final String averageDuration;

  VisitorStatistics({
    required this.todayCount,
    required this.insideNow,
    required this.overStay,
    required this.averageDuration,
  });
}

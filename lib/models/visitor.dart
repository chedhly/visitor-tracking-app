class Visitor {
  final int id;
  final String plateNumber;
  final DateTime entryTime;
  final DateTime? exitTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  Visitor({
    required this.id,
    required this.plateNumber,
    required this.entryTime,
    this.exitTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: json['id'],
      plateNumber: json['plate_number'],
      entryTime: DateTime.parse(json['entry_time']),
      exitTime: json['exit_time'] != null ? DateTime.parse(json['exit_time']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate_number': plateNumber,
      'entry_time': entryTime.toIso8601String(),
      'exit_time': exitTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get duration {
    if (exitTime == null) return 'Still inside';
    final diff = exitTime!.difference(entryTime);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return '${hours}h ${minutes}m';
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

class AppSettings {
  final String id;
  final int overstayThresholdHours;
  final DateTime updatedAt;

  AppSettings({
    required this.id,
    required this.overstayThresholdHours,
    required this.updatedAt,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      id: json['id'] as String,
      overstayThresholdHours: json['overstay_threshold_hours'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overstay_threshold_hours': overstayThresholdHours,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

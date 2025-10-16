class Personnel {
  final String id;
  final String email;
  final String name;
  final String clearanceLevel;

  Personnel({
    required this.id,
    required this.email,
    required this.name,
    required this.clearanceLevel,
  });

  factory Personnel.fromJson(Map<String, dynamic> json) {
    return Personnel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      clearanceLevel: json['clearance_level'] as String,
    );
  }

  bool get isAdmin => clearanceLevel == 'admin';
}

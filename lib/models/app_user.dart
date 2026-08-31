class AppUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String role; // 'user' or 'admin'
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.role = 'user',
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create AppUser from JSON
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Create AppUser from Firebase User
  factory AppUser.fromFirebaseUser(
    String uid,
    String? displayName,
    String? email,
    String? photoUrl, {
    String role = 'user',
  }) {
    return AppUser(
      id: uid,
      name: displayName ?? 'User',
      email: email ?? '',
      photoUrl: photoUrl,
      role: role,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Copy with method for updates
  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper method to check if user is admin
  bool get isAdmin => role == 'admin';

  @override
  String toString() {
    return 'AppUser(id: $id, name: $name, email: $email, role: $role)';
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' or 'intern'
  final String? profileImageUrl;
  final String? fcmToken;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
    this.fcmToken,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'intern',
      profileImageUrl: map['profileImageUrl'] as String?,
      fcmToken: map['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? role,
    String? profileImageUrl,
    String? fcmToken,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}

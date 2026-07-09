class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' or 'intern'

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  // Convert from Firestore document to User object
  factory User.fromMap(Map<String, dynamic> map, String id) {
    return User(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'intern',
    );
  }

  // Convert User object to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
    };
  }
}

// lib/models/user.dart
class User {
  final int? id;
  String name;  // Make mutable
  final String email;
  String password;  // Make mutable
  String phone;  // Make mutable
  final String gender;
  final String? createdAt;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.gender,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'gender': gender,
      'created_at': createdAt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      phone: map['phone'],
      gender: map['gender'],
      createdAt: map['created_at'],
    );
  }
}
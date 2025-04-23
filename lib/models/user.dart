import 'package:intl/intl.dart';

class User {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;
  final String username;
  final DateTime createdAt;
  final String? status;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.role = 'user',
    String? username,
    DateTime? createdAt,
    this.status = 'active',
  }) : username = username ?? email.split('@')[0],
       createdAt = createdAt ?? DateTime.now();

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      password: map['password'] as String,
      role: map['role'] as String? ?? 'user',
      username: map['username'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      status: map['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? password,
    String? role,
    String? username,
    DateTime? createdAt,
    String? status,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}

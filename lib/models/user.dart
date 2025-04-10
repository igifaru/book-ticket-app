
class User {
  int? id;
  String name;
  String email;
  String password;
  String phone;
  String gender;
  String? createdAt;

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
      phone: map['phone'] ?? '',  // Handle possible null value
      gender: map['gender'],
      createdAt: map['created_at'],
    );
  }
}

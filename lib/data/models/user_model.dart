import 'dart:convert';

class UserModel {
  final String name;
  final String email;
  final String mobile;
  final String password;
  final String? imagePath;

  UserModel({
    required this.name,
    required this.email,
    required this.mobile,
    required this.password,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'mobile': mobile,
      'password': password,
      'imagePath': imagePath,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      mobile: map['mobile'] ?? '',
      password: map['password'] ?? '',
      imagePath: map['imagePath'],
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source));
}

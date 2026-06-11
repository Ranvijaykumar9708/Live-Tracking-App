import 'dart:convert';

class UserModel {
  final String name;
  String email;
  String mobile;
  String password;
  String? imagePath;
  String? homeAddress;
  String? workAddress;

  UserModel({
    required this.name,
    required this.email,
    required this.mobile,
    required this.password,
    this.imagePath,
    this.homeAddress,
    this.workAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'mobile': mobile,
      'password': password,
      'imagePath': imagePath,
      'homeAddress': homeAddress,
      'workAddress': workAddress,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      mobile: map['mobile'] ?? '',
      password: map['password'] ?? '',
      imagePath: map['imagePath'],
      homeAddress: map['homeAddress'],
      workAddress: map['workAddress'],
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => UserModel.fromMap(json.decode(source));
}

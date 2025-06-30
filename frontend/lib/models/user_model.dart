import 'dart:convert';

class User {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String role;
  final String? businessName;
  final String? businessDescription;
  final String? profileimage;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.businessName,
    this.businessDescription,
    required this.profileimage
  });

  // Convert JSON to User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      profileimage: json['profileimage'] ?? '',
      businessName: json['businessName'],
      businessDescription: json['businessDescription'],
    );
  }

  // Convert User object to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'profileimage': profileimage,
      'businessName': businessName,
      'businessDescription': businessDescription,
    };
  }

  // Convert JSON string to User object
  static User fromJsonString(String jsonString) {
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return User.fromJson(jsonData);
  }

  // Convert User object to JSON string
  String toJsonString() {
    return json.encode(toJson());
  }
}

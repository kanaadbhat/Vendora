import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Save token after login
  Future<void> saveToken(String token) async {
    await _storage.write(key: "auth_token", value: token);
  }

  // Save refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    await _storage.write(key: "refresh_token", value: refreshToken);
  }

  // Retrieve stored token
  Future<String?> getToken() async {
    return await _storage.read(key: "auth_token");
  }

  // Retrieve refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: "refresh_token");
  }

  // Clear tokens on logout
  Future<void> logout() async {
    await _storage.delete(key: "auth_token");
    await _storage.delete(key: "refresh_token");
  }
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'storage_service.dart';

class AuthService {
  final _storage = PlatformStorage.instance;

  // Save token after login
  Future<void> saveToken(String token) async {
    debugPrint("[DEBUG] AuthService.saveToken() - Saving auth token");
    await _storage.write( "auth_token",  token);
  }

  // Save refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    debugPrint("[DEBUG] AuthService.saveRefreshToken() - Saving refresh token");
    await _storage.write("refresh_token",  refreshToken);
  }

  // Retrieve stored token
  Future<String?> getToken() async {
    final token = await _storage.read( "auth_token");
    debugPrint(
      "[DEBUG] AuthService.getToken() - Retrieved token: ${token != null ? 'exists' : 'null'}",
    );
    return token;
  }

  // Retrieve refresh token
  Future<String?> getRefreshToken() async {
    final refreshToken = await _storage.read("refresh_token");
    debugPrint(
      "[DEBUG] AuthService.getRefreshToken() - Retrieved refresh token: ${refreshToken != null ? 'exists' : 'null'}",
    );
    return refreshToken;
  }

  // Clear tokens on logout
  Future<void> logout() async {
    debugPrint(
      "[DEBUG] AuthService.logout() - Deleting tokens from secure storage",
    );
    //await _storage.delete(key: "auth_token");
    //await _storage.delete(key: "refresh_token");
    await _storage.deleteAll();
    // Verify tokens are deleted
    final authToken = await _storage.read( "auth_token");
    final refreshToken = await _storage.read("refresh_token");
    debugPrint(
      "[DEBUG] AuthService.logout() - Verification: auth token ${authToken == null ? 'deleted' : 'still exists'}, refresh token ${refreshToken == null ? 'deleted' : 'still exists'}",
    );
  }
} 

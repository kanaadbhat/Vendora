import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class UserService {
  final ApiService _apiService = ApiService();

  // Fetch user details
  Future<User?> fetchUserDetails() async {
    try {
      var response = await _apiService.get('/user/details');
      if (response.statusCode == 200) {
        return User.fromJson(response.data['user']);
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }
    return null;
  }

  // Fetch user role
  Future<String?> fetchUserRole() async {
    try {
      final user = await fetchUserDetails();
      return user?.role;
    } catch (e) {
      debugPrint("Error fetching user role: $e");
    }
    return null;
  }

  // Delete user profile
  Future<bool> deleteProfile() async {
    try {
      var response = await _apiService.delete('/user/delete');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error deleting profile: $e");
    }
    return false;
  }
}

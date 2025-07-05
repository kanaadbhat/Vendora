import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'role_viewmodel.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

final authProvider = StateNotifierProvider<AuthViewModel, AsyncValue<User?>>((
  ref,
) {
  return AuthViewModel(ref);
});

class AuthViewModel extends StateNotifier<AsyncValue<User?>> {
  AuthViewModel(this.ref) : super(const AsyncValue.data(null)) {
    initializeUser();
  }

  final Ref ref;
  final ApiService _apiService = ApiService();

  Future<void> initializeUser() async {
    debugPrint(
      "[DEBUG] AuthViewModel.initializeUser() - Starting initialization",
    );

    try {
      final token = await AuthService().getToken();
      debugPrint(
        "[DEBUG] AuthViewModel._initializeUser() - Token: ${token != null ? 'exists' : 'null'}",
      );
      if (token == null) {
        debugPrint(
          "[DEBUG] AuthViewModel._initializeUser() - No token, setting state to null",
        );
        state = const AsyncValue.data(null);
        return;
      }
      debugPrint(
        "[DEBUG] AuthViewModel._initializeUser() - Fetching user details",
      );
      final response = await _apiService.get('/user/details');
      debugPrint(
        "[DEBUG] AuthViewModel._initializeUser() - Response: ${response.data}",
      );
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['user'] != null) {
        final user = User.fromJson(response.data['user']);
        debugPrint(
          "[DEBUG] AuthViewModel._initializeUser() - Setting user: ${user.name} (${user.role})",
        );
        state = AsyncValue.data(user);
      } else {
        debugPrint(
          "[DEBUG] AuthViewModel._initializeUser() - Invalid response, logging out",
        );
        await AuthService().logout();
        state = const AsyncValue.data(null);
      }
    } catch (e, stackTrace) {
      debugPrint("[DEBUG] AuthViewModel._initializeUser() - Error: $e");
      await AuthService().logout();
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      var response = await _apiService.post(
        '/user/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final userData = response.data['user'];
        final user = User.fromJson(userData);
        state = AsyncValue.data(user);
        ref.read(roleProvider.notifier).setRole(user.role);
      } else {
        throw Exception("Login failed: ${response.data['message']}");
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();

    try {
      var response = await _apiService.post('/user/register', data: data);

      if (response.statusCode == 201) {
        final userData = response.data['user'];
        final user = User.fromJson(userData);
        state = AsyncValue.data(user);
        ref.read(roleProvider.notifier).setRole(user.role);
      } else {
        throw Exception("Registration failed: ${response.data['message']}");
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> logout() async {
    debugPrint("[DEBUG] AuthViewModel.logout() - Starting logout process");
    try {
      debugPrint(
        "[DEBUG] AuthViewModel.logout() - Current auth state before logout: ${state.toString()}",
      );
      debugPrint(
        "[DEBUG] AuthViewModel.logout() - Current role state before logout: ${ref.read(roleProvider).toString()}",
      );

      await _apiService.logout();

      // Set state to null first to ensure UI updates
      state = const AsyncValue.data(null);
      debugPrint("[DEBUG] AuthViewModel.logout() - Auth state set to null");

      // Clear role after state is updated
      ref.read(roleProvider.notifier).clearRole();
      debugPrint("[DEBUG] AuthViewModel.logout() - Role cleared");

      // Verify state after logout
      debugPrint(
        "[DEBUG] AuthViewModel.logout() - Auth state after logout: ${state.toString()}",
      );
      debugPrint(
        "[DEBUG] AuthViewModel.logout() - Role state after logout: ${ref.read(roleProvider).toString()}",
      );
    } catch (e, stackTrace) {
      debugPrint("[DEBUG] AuthViewModel.logout() - Error during logout: $e");
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

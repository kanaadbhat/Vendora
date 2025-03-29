import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import 'role_viewmodel.dart';

final authProvider = StateNotifierProvider<AuthViewModel, AsyncValue<User?>>((
  ref,
) {
  return AuthViewModel(ref);
});

class AuthViewModel extends StateNotifier<AsyncValue<User?>> {
  AuthViewModel(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

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
    try {
      await _apiService.logout();
      state = const AsyncValue.data(null);
      ref.read(roleProvider.notifier).clearRole();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:flutter/foundation.dart';

final roleProvider = StateNotifierProvider<RoleViewModel, AsyncValue<String?>>(
  (ref) => RoleViewModel(ref),
);

class RoleViewModel extends StateNotifier<AsyncValue<String?>> {
  RoleViewModel(this.ref) : super(const AsyncValue.data(null)) {
    fetchUserRole();
  }

  final Ref ref;
  final ApiService _apiService = ApiService();

  Future<void> fetchUserRole() async {
    debugPrint("[DEBUG] RoleViewModel.fetchUserRole() - Starting fetch");
    state = const AsyncValue.loading();

    final token = await AuthService().getToken();
    if (token == null) {
      debugPrint("[DEBUG] No token found in fetchUserRole()");
      state = const AsyncValue.data(null);
      return;
    }

    try {
      debugPrint("[DEBUG] RoleViewModel.fetchUserRole() - Making API call");
      final response = await _apiService.get('/user/details');
      debugPrint("[DEBUG] API /user/details response: ${response.data}");

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['user'] != null &&
          response.data['user']['role'] != null) {
        final role = response.data['user']['role'];
        debugPrint("[DEBUG] User role resolved as: $role");
        debugPrint(
          "[DEBUG] RoleViewModel.fetchUserRole() - Setting state to: $role",
        );
        state = AsyncValue.data(role);
        debugPrint(
          "[DEBUG] RoleViewModel.fetchUserRole() - State set successfully",
        );
      } else {
        debugPrint("[DEBUG] Unexpected response or role missing");
        state = const AsyncValue.data(null);
      }
    } catch (e, stackTrace) {
      debugPrint("[DEBUG] Error in fetchUserRole(): $e");
      await AuthService().logout();
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void setRole(String role) {
    state = AsyncValue.data(role);
  }

  void clearRole() {
    state = const AsyncValue.data(null);
  }
}

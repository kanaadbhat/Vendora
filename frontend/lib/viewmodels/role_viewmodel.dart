import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final roleProvider = StateNotifierProvider<RoleViewModel, AsyncValue<String?>>((
  ref,
) {
  return RoleViewModel(ref);
});

class RoleViewModel extends StateNotifier<AsyncValue<String?>> {
  RoleViewModel(this.ref) : super(const AsyncValue.data(null)) {
    fetchUserRole();
  }

  final Ref ref;
  final ApiService _apiService = ApiService();

  Future<void> fetchUserRole() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiService.get('/user/details');
      if (response.statusCode == 200) {
        state = AsyncValue.data(response.data['user']['role']);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stackTrace) {
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

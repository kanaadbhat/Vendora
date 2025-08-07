import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/server_availability_service.dart';

final serverAvailabilityProvider = StateNotifierProvider<ServerAvailabilityNotifier, ServerAvailabilityState>((ref) {
  return ServerAvailabilityNotifier();
});

class ServerAvailabilityNotifier extends StateNotifier<ServerAvailabilityState> {
  ServerAvailabilityNotifier() : super(ServerAvailabilityState.initial());
  
  final ServerAvailabilityService _service = ServerAvailabilityService();

  Future<void> checkServerAvailability() async {
    if (state.isChecking) return;
    
    state = state.copyWith(isChecking: true, hasError: false);
    
    try {
      final isAvailable = await _service.waitForServerAvailability();
      state = state.copyWith(
        isAvailable: isAvailable,
        isChecking: false,
        hasError: !isAvailable,
      );
    } catch (e) {
      state = state.copyWith(
        isAvailable: false,
        isChecking: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    _service.stopHealthCheck();
    state = ServerAvailabilityState.initial();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

class ServerAvailabilityState {
  final bool isAvailable;
  final bool isChecking;
  final bool hasError;
  final String? errorMessage;

  const ServerAvailabilityState({
    required this.isAvailable,
    required this.isChecking,
    required this.hasError,
    this.errorMessage,
  });

  factory ServerAvailabilityState.initial() {
    return const ServerAvailabilityState(
      isAvailable: false,
      isChecking: false,
      hasError: false,
    );
  }

  ServerAvailabilityState copyWith({
    bool? isAvailable,
    bool? isChecking,
    bool? hasError,
    String? errorMessage,
  }) {
    return ServerAvailabilityState(
      isAvailable: isAvailable ?? this.isAvailable,
      isChecking: isChecking ?? this.isChecking,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

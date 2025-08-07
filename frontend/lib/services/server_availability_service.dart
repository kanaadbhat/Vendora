import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ServerAvailabilityService {
  static final ServerAvailabilityService _instance = ServerAvailabilityService._internal();
  factory ServerAvailabilityService() => _instance;

  late final Dio _dio;
  late final String apiBaseUrl;
  Timer? _healthCheckTimer;
  final StreamController<bool> _serverStatusController = StreamController<bool>.broadcast();

  ServerAvailabilityService._internal() {
    apiBaseUrl = (kIsWeb && kReleaseMode)
        ? const String.fromEnvironment('API_BASE_URL', defaultValue: '')
        : (dotenv.env['API_BASE_URL'] ?? '');
    
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ),
    );
  }

  Stream<bool> get serverStatus => _serverStatusController.stream;

  Future<bool> checkServerHealth() async {
    try {
      debugPrint("[ServerAvailability] Checking server health at: $apiBaseUrl/user/health");
      final response = await _dio.get('/user/health');
      final isHealthy = response.statusCode == 200;
      debugPrint("[ServerAvailability] Server health check result: $isHealthy");
      return isHealthy;
    } catch (e) {
      debugPrint("[ServerAvailability] Server health check failed: $e");
      return false;
    }
  }

  Future<bool> waitForServerAvailability({
    Duration checkInterval = const Duration(seconds: 2),
    Duration maxWaitTime = const Duration(minutes: 2),
  }) async {
    debugPrint("[ServerAvailability] Starting server availability check");
    final completer = Completer<bool>();
    final startTime = DateTime.now();

    _healthCheckTimer = Timer.periodic(checkInterval, (timer) async {
      final elapsed = DateTime.now().difference(startTime);
      
      if (elapsed > maxWaitTime) {
        debugPrint("[ServerAvailability] Max wait time exceeded");
        timer.cancel();
        _serverStatusController.add(false);
        if (!completer.isCompleted) {
          completer.complete(false);
        }
        return;
      }

      final isHealthy = await checkServerHealth();
      _serverStatusController.add(isHealthy);
      
      if (isHealthy) {
        debugPrint("[ServerAvailability] Server is now available");
        timer.cancel();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    // Also check immediately
    final isHealthy = await checkServerHealth();
    _serverStatusController.add(isHealthy);
    if (isHealthy && !completer.isCompleted) {
      _healthCheckTimer?.cancel();
      completer.complete(true);
    }

    return completer.future;
  }

  void stopHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  void dispose() {
    stopHealthCheck();
    _serverStatusController.close();
  }
}

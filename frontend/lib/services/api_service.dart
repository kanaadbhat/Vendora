import 'package:dio/dio.dart';
import 'auth_service.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final String apiBaseUrl;
  late final Dio _dio;

  ApiService()
    : apiBaseUrl =
          (kIsWeb && kReleaseMode)
              ? const String.fromEnvironment('API_BASE_URL', defaultValue: '')
              : (dotenv.env['API_BASE_URL'] ?? '') {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {"Content-Type": "application/json"},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _initializeToken();
    _setupInterceptors();
  }

  final AuthService _authService = AuthService();
  bool _isRefreshing = false;
  final _refreshController = StreamController<bool>.broadcast();

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Get token before each request
          final token = await _authService.getToken();
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            _isRefreshing = true;
            try {
              final refreshToken = await _authService.getRefreshToken();
              if (refreshToken != null) {
                final response = await _dio.post(
                  '/user/refresh-token',
                  data: {'refreshToken': refreshToken},
                );
                if (response.statusCode == 200) {
                  final newAccessToken = response.data['accessToken'];
                  await _updateToken(newAccessToken);
                  // Retry the original request
                  final originalRequest = error.requestOptions;
                  final retryResponse = await _dio.fetch(originalRequest);
                  return handler.resolve(retryResponse);
                }
              }
            } catch (e) {
              debugPrint("Token refresh failed: $e");
            } finally {
              _isRefreshing = false;
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> _initializeToken() async {
    debugPrint("[DEBUG] ApiService._initializeToken() - Initializing token");
    String? token = await _authService.getToken();
    if (token != null) {
      debugPrint(
        "[DEBUG] ApiService._initializeToken() - Setting Authorization header with token",
      );
      _dio.options.headers["Authorization"] = "Bearer $token";
    } else {
      debugPrint(
        "[DEBUG] ApiService._initializeToken() - No token found, Authorization header not set",
      );
    }
  }

  Future<bool> checkServerHealth() async {
    try {
      debugPrint("[DEBUG] ApiService.checkServerHealth() - Checking server health");
      final response = await _dio.get('/user/health');
      final isHealthy = response.statusCode == 200;
      debugPrint("[DEBUG] ApiService.checkServerHealth() - Server health: $isHealthy");
      return isHealthy;
    } catch (e) {
      debugPrint("[DEBUG] ApiService.checkServerHealth() - Server health check failed: $e");
      return false;
    }
  }

  Future<void> _updateToken(String? token) async {
    if (token != null) {
      await _authService.saveToken(token);
      _dio.options.headers["Authorization"] = "Bearer $token";
      _refreshController.add(true);
    }
  }

  Future<void> logout() async {
    debugPrint("[DEBUG] ApiService.logout() - Starting logout process");
    try {
      debugPrint(
        "[DEBUG] ApiService.logout() - Sending logout request to server",
      );
      final response = await _dio.post('/user/logout');
      debugPrint(
        "[DEBUG] ApiService.logout() - Server response: ${response.statusCode}",
      );
    } catch (e) {
      debugPrint("[DEBUG] ApiService.logout() - Error during API call: $e");
    } finally {
      debugPrint(
        "[DEBUG] ApiService.logout() - Clearing local storage and headers",
      );
      await _authService.logout();
      _dio.options.headers.remove("Authorization");
      debugPrint("[DEBUG] ApiService.logout() - Authorization header removed");
      _refreshController.add(false);
      debugPrint("[DEBUG] ApiService.logout() - Logout process completed");
    }
  }

  Future<Response> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      return await _dio.get(endpoint, queryParameters: queryParams);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Response> post(String endpoint, {dynamic data}) async {
    debugPrint("[DEBUG] ApiService.post() - Endpoint: $endpoint");
    try {
      Response response = await _dio.post(endpoint, data: data);
      debugPrint(
        "[DEBUG] ApiService.post() - Response status: ${response.statusCode}",
      );

      // Update tokens for login and register responses
      if ((endpoint == "/user/login" || endpoint == "/user/register") &&
          response.data["accessToken"] != null) {
        debugPrint(
          "[DEBUG] ApiService.post() - Received new access token from ${endpoint}",
        );
        await _updateToken(response.data["accessToken"]);
        if (response.data["refreshToken"] != null) {
          debugPrint(
            "[DEBUG] ApiService.post() - Received new refresh token from ${endpoint}",
          );
          await _authService.saveRefreshToken(response.data["refreshToken"]);
        }

        // Verify tokens were saved
        final token = await _authService.getToken();
        final refreshToken = await _authService.getRefreshToken();
        debugPrint(
          "[DEBUG] ApiService.post() - Token verification: access token ${token != null ? 'exists' : 'null'}, refresh token ${refreshToken != null ? 'exists' : 'null'}",
        );
      }

      return response;
    } on DioException catch (e) {
      debugPrint("[DEBUG] ApiService.post() - DioException: ${e.message}");
      return _handleError(e);
    }
  }

  Future<Response> put(String endpoint, {dynamic data}) async {
    try {
      return await _dio.put(endpoint, data: data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Future<Response> delete(String endpoint, {dynamic data}) async {
    try {
      return await _dio.delete(endpoint, data: data);
    } on DioException catch (e) {
      return _handleError(e);
    }
  }

  Response _handleError(DioException e) {
    if (e.response != null) {
      debugPrint("API Error: ${e.response?.data}");

      final data = e.response?.data;

      if (data is Map && data['message'] is String) {
        debugPrint("Throwing String message: ${data['message']}");
        throw Exception(data['message']);
      } else if (data is String) {
        throw Exception(data);
      } else {
        throw Exception('Unexpected error from server.');
      }
    } else if (e.type == DioExceptionType.connectionTimeout) {
      debugPrint("Connection Timeout");
      throw Exception(
        "Connection timeout. Please check your internet connection.",
      );
    } else if (e.type == DioExceptionType.receiveTimeout) {
      debugPrint("Receive Timeout");
      throw Exception("Server took too long to respond. Please try again.");
    } else {
      debugPrint("Network Error: ${e.message}");
      throw Exception("Network Error: ${e.message}");
    }
  }

  Stream<bool> get onTokenRefresh => _refreshController.stream;
}

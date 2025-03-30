import 'package:dio/dio.dart';
import 'auth_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "http://localhost:8000/api",
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      headers: {"Content-Type": "application/json"},
      validateStatus: (status) => status! < 500,
    ),
  );

  final AuthService _authService = AuthService();
  bool _isRefreshing = false;
  final _refreshController = StreamController<bool>.broadcast();

  ApiService() {
    _initializeToken();
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
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
    String? token = await _authService.getToken();
    if (token != null) {
      _dio.options.headers["Authorization"] = "Bearer $token";
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
    try {
      await _dio.post('/user/logout');
    } catch (e) {
      debugPrint("Logout error: $e");
    } finally {
      await _authService.logout();
      _dio.options.headers.remove("Authorization");
      _refreshController.add(false);
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
    try {
      Response response = await _dio.post(endpoint, data: data);

      // Update tokens for login and register responses
      if ((endpoint == "/user/login" || endpoint == "/user/register") &&
          response.data["accessToken"] != null) {
        await _updateToken(response.data["accessToken"]);
        if (response.data["refreshToken"] != null) {
          await _authService.saveRefreshToken(response.data["refreshToken"]);
        }
      }

      return response;
    } on DioException catch (e) {
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
      if (e.response?.statusCode == 401) {
        // Token expired or invalid
        logout();
      }
      return e.response!;
    } else if (e.type == DioExceptionType.connectionTimeout) {
      debugPrint("Connection Timeout");
      throw Exception(
        "Connection timeout. Please check your internet connection.",
      );
    } else if (e.type == DioExceptionType.receiveTimeout) {
      debugPrint("Receive Timeout");
      throw Exception(
        "Server is taking too long to respond. Please try again.",
      );
    } else {
      debugPrint("Network Error: ${e.message}");
      throw Exception("Network Error: ${e.message}");
    }
  }

  Stream<bool> get onTokenRefresh => _refreshController.stream;
}

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/core/config/app_config.dart';
import 'package:mobile_app/core/services/auth_storage.dart';
import 'package:mobile_app/core/services/navigation_service.dart';
import 'package:mobile_app/features/auth/screens/login_screen.dart';

/// Centralized API client with Dio
/// Handles authorization headers, error handling, and token refresh
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        final token = await AuthStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        if (AppConfig.isDebug) {
          debugPrint('API REQUEST: ${options.method} ${options.path}');
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (AppConfig.isDebug) {
          debugPrint(
              'API RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (AppConfig.isDebug) {
          debugPrint(
              'API ERROR: ${error.response?.statusCode} ${error.message}');
        }

        // Handle 401 Unauthorized - token expired
        if (error.response?.statusCode == 401) {
          // Skip global handling for logout request to avoid loops/double-nav
          // specific logout flow is handled by AuthService/UI
          if (error.requestOptions.path.contains('/logout')) {
            return handler.next(error);
          }

          await AuthStorage.clearAll();

          // Redirect to login screen
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }

        return handler.next(error);
      },
    ));
  }

  /// Reset client (clear token state)
  static void reset() {
    _instance = null;
  }
}

/// Convenience getter for Dio instance
Dio get apiClient => ApiClient.instance.dio;

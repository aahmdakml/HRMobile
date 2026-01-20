import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_app/core/config/app_config.dart';
import 'package:mobile_app/core/models/user.dart';
import 'package:mobile_app/core/services/api_client.dart';
import 'package:mobile_app/core/services/auth_storage.dart';
import 'package:mobile_app/core/services/auth_state.dart';

/// Authentication service for backend API
/// Handles login, logout, token verification
class AuthService {
  /// Login with email and password
  static Future<AuthResult> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      debugPrint('AUTH: Attempting login for $email');

      final response = await apiClient.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;
        final user = User.fromJson(userData);

        // Calculate token expiry (backend: 1 day)
        final expiresAt = DateTime.now().add(
          Duration(hours: AppConfig.tokenExpiryHours),
        );

        // Save to secure storage
        await AuthStorage.saveToken(token, expiresAt: expiresAt);
        await AuthStorage.saveUser(user);

        // Handle remember me
        if (rememberMe) {
          await AuthStorage.saveRememberedEmail(email);
        } else {
          await AuthStorage.clearRememberedEmail();
        }

        // Update global auth state
        authState.login(user: user, token: token);

        debugPrint('AUTH: Login successful for ${user.displayName}');

        return AuthResult(
          success: true,
          user: user,
          token: token,
          message: response.data['message'] ?? 'Login successful',
        );
      }

      return AuthResult(
        success: false,
        message: response.data['message'] ?? 'Login failed',
      );
    } on DioException catch (e) {
      debugPrint('AUTH ERROR: ${e.message}');
      return _handleDioError(e);
    } catch (e) {
      debugPrint('AUTH ERROR: $e');
      return AuthResult(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Verify stored token and get user data
  static Future<bool> verifyToken() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        debugPrint('AUTH: No stored token');
        return false;
      }

      debugPrint('AUTH: Verifying stored token');

      final response = await apiClient.get('/verify-token');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final user = User.fromJson(data['user']);

        // Update stored user data
        await AuthStorage.saveUser(user);

        // Update global auth state
        authState.login(user: user, token: token);

        debugPrint('AUTH: Token verified for ${user.displayName}');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('AUTH VERIFY ERROR: $e');
      await AuthStorage.clearAll();
      return false;
    }
  }

  /// Logout user
  static Future<void> logout() async {
    try {
      debugPrint('AUTH: Logging out');

      // Try to invalidate token on server
      try {
        await apiClient.post('/auth/logout');
      } catch (e) {
        // Ignore server errors on logout
      }
    } finally {
      // Clear local storage
      await AuthStorage.clearAll();
      authState.logout();
      ApiClient.reset();
      debugPrint('AUTH: Logged out');
    }
  }

  /// Change password
  static Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await apiClient.post('/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      });

      return AuthResult(
        success: response.statusCode == 200,
        message: response.data['message'] ?? 'Password changed',
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return AuthResult(success: false, message: 'Unexpected error: $e');
    }
  }

  /// Check if user is logged in (has valid token)
  static Future<bool> isLoggedIn() async {
    return await AuthStorage.hasValidToken();
  }

  /// Handle Dio errors
  static AuthResult _handleDioError(DioException e) {
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please try again.';
        break;
      case DioExceptionType.connectionError:
        message = 'Cannot connect to server. Check your internet.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          message = e.response?.data['message'] ?? 'Invalid credentials';
        } else if (statusCode == 422) {
          // Validation error - extract first message
          final errors = e.response?.data['errors'];
          if (errors is Map && errors.isNotEmpty) {
            final firstError = errors.values.first;
            message =
                firstError is List ? firstError.first : firstError.toString();
          } else {
            message = e.response?.data['message'] ?? 'Validation error';
          }
        } else if (statusCode == 500) {
          message = 'Server error. Please try again later.';
        } else {
          message = e.response?.data['message'] ?? 'Request failed';
        }
        break;
      default:
        message = 'Network error. Please try again.';
    }

    return AuthResult(success: false, message: message);
  }
}

/// Auth result wrapper
class AuthResult {
  final bool success;
  final User? user;
  final String? token;
  final String message;

  AuthResult({
    required this.success,
    this.user,
    this.token,
    required this.message,
  });
}

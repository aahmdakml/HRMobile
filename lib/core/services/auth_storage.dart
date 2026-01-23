import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_app/core/models/user.dart';
import 'package:mobile_app/core/services/cache_service.dart';
import 'package:mobile_app/core/services/time_service.dart';
import 'package:flutter/foundation.dart';

/// Secure storage for authentication data
/// Uses flutter_secure_storage for encrypted storage
class AuthStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Storage keys
  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';
  static const _keyRememberedEmail = 'remembered_email';
  static const _keyTokenExpiry = 'token_expiry';

  // ============ Token Operations ============

  /// Save auth token with expiry
  static Future<void> saveToken(String token, {DateTime? expiresAt}) async {
    await _storage.write(key: _keyToken, value: token);
    if (expiresAt != null) {
      await _storage.write(
        key: _keyTokenExpiry,
        value: expiresAt.toIso8601String(),
      );
    }
  }

  /// Get stored token (returns null if expired)
  static Future<String?> getToken() async {
    final token = await _storage.read(key: _keyToken);
    if (token == null) return null;

    // Check expiry
    final expiryStr = await _storage.read(key: _keyTokenExpiry);
    if (expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        // Token expired, clear it
        await clearAll();
        return null;
      }
    }

    return token;
  }

  /// Check if token exists and not expired
  static Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null;
  }

  // ============ User Operations ============

  /// Save user data
  static Future<void> saveUser(User user) async {
    final json = jsonEncode(user.toJson());
    await _storage.write(key: _keyUser, value: json);
  }

  /// Get stored user
  static Future<User?> getUser() async {
    final json = await _storage.read(key: _keyUser);
    if (json == null) return null;
    try {
      return User.fromJson(jsonDecode(json));
    } catch (e) {
      return null;
    }
  }

  // ============ Remember Me Operations ============

  /// Save remembered email
  static Future<void> saveRememberedEmail(String email) async {
    await _storage.write(key: _keyRememberedEmail, value: email);
  }

  /// Get remembered email
  static Future<String?> getRememberedEmail() async {
    return await _storage.read(key: _keyRememberedEmail);
  }

  /// Clear remembered email
  static Future<void> clearRememberedEmail() async {
    await _storage.delete(key: _keyRememberedEmail);
  }

  // ============ Clear Operations ============

  /// Clear auth data (logout) - keeps remembered email
  static Future<void> clearAll() async {
    debugPrint('AUTH_STORAGE: Clearing auth data...');
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUser);
    await _storage.delete(key: _keyTokenExpiry);

    // Also clear SQLite cache and RAM
    debugPrint('AUTH_STORAGE: Clearing SQLite cache...');
    await CacheService.clearAll();
    TimeService.clear(); // Clear RAM anchor
    debugPrint('AUTH_STORAGE: All data cleared');
  }

  /// Clear everything including remembered email
  static Future<void> clearEverything() async {
    debugPrint(
        'AUTH_STORAGE: Clearing ALL data (including remembered email)...');
    await _storage.deleteAll();

    // Also clear SQLite cache
    debugPrint('AUTH_STORAGE: Clearing SQLite cache...');
    await CacheService.clearAll();
    debugPrint('AUTH_STORAGE: Everything cleared');
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/models/user.dart';
import 'package:mobile_app/core/services/auth_storage.dart';

/// Global authentication state
/// Singleton that holds current user session
class AuthState extends ChangeNotifier {
  static final AuthState _instance = AuthState._internal();
  factory AuthState() => _instance;
  AuthState._internal();

  bool _isLoggedIn = false;
  User? _user;
  String? _token;
  bool _isInitialized = false;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  User? get user => _user;
  String? get token => _token;
  bool get isInitialized => _isInitialized;
  bool get hasValidSession => _isLoggedIn && _token != null && _user != null;

  // Convenience getters
  String get userName => _user?.displayName ?? 'User'; // Employee name
  String get username => _user?.username ?? 'User'; // user_name from db
  String? get userEmail => _user?.email;
  String? get empId => _user?.empId;
  String? get position => _user?.employee?.position;
  String? get department => _user?.employee?.department;
  String? get company => _user?.employee?.company;
  String? get avatar => _user?.employee?.avatar;
  String? get phone => _user?.employee?.phone;

  /// Get first word of user's full name for greeting
  String get userFirstName {
    final fullName = _user?.displayName ?? 'User';
    final words = fullName.split(' ');
    return words.first;
  }

  /// Initialize from storage (call on app start)
  Future<void> initFromStorage() async {
    if (_isInitialized) return;

    final token = await AuthStorage.getToken();
    final user = await AuthStorage.getUser();

    if (token != null && user != null) {
      _isLoggedIn = true;
      _token = token;
      _user = user;
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Login - called after successful authentication
  void login({required User user, required String token}) {
    _isLoggedIn = true;
    _user = user;
    _token = token;
    notifyListeners();
  }

  /// Update user data
  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }

  /// Logout - clear all state
  void logout() {
    _isLoggedIn = false;
    _user = null;
    _token = null;
    notifyListeners();
  }
}

/// Global auth state instance
final authState = AuthState();

/// Riverpod provider for AuthState
final authStateProvider = ChangeNotifierProvider<AuthState>((ref) {
  return AuthState();
});

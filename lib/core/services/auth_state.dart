import 'package:flutter/foundation.dart';

/// Auth state management - holds current user session
class AuthState extends ChangeNotifier {
  static final AuthState _instance = AuthState._internal();
  factory AuthState() => _instance;
  AuthState._internal();

  bool _isLoggedIn = false;
  String? _userEmail;
  String? _userName;
  String? _token;

  bool get isLoggedIn => _isLoggedIn;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get token => _token;

  /// Call after successful login
  void login({
    required String email,
    required String name,
    required String token,
  }) {
    _isLoggedIn = true;
    _userEmail = email;
    _userName = name;
    _token = token;
    notifyListeners();
  }

  /// Call on logout
  void logout() {
    _isLoggedIn = false;
    _userEmail = null;
    _userName = null;
    _token = null;
    notifyListeners();
  }

  /// Check if session is valid (for splash screen)
  bool get hasValidSession => _isLoggedIn && _token != null;
}

/// Global auth state instance
final authState = AuthState();

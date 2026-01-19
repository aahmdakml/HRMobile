import 'package:mobile_app/core/services/auth_state.dart';

/// Mock Authentication Service for development
/// Replace with real API calls when backend is ready
class MockAuthService {
  static const String _validEmail = 'admin@user.com';
  static const String _validPassword = 'admin123';

  // Simulated user data
  static const Map<String, dynamic> _mockUser = {
    'id': 1,
    'name': 'Admin User',
    'email': 'admin@user.com',
    'emp_id': 'EMP001',
    'position': 'Software Developer',
    'department': 'IT',
    'avatar': null,
  };

  /// Simulate login with delay
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (email.toLowerCase() == _validEmail && password == _validPassword) {
      final user = User.fromJson(_mockUser);
      final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';

      // Update global auth state
      authState.login(
        email: user.email,
        name: user.name,
        token: token,
      );

      return AuthResult(
        success: true,
        user: user,
        token: token,
        message: 'Login successful',
      );
    } else {
      return AuthResult(
        success: false,
        user: null,
        token: null,
        message: 'Invalid email or password',
      );
    }
  }

  /// Simulate logout
  static Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    authState.logout();
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    return authState.hasValidSession;
  }
}

/// Auth result model
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

/// User model
class User {
  final int id;
  final String name;
  final String email;
  final String empId;
  final String position;
  final String department;
  final String? avatar;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.empId,
    required this.position,
    required this.department,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      empId: json['emp_id'] ?? '',
      position: json['position'] ?? '',
      department: json['department'] ?? '',
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'emp_id': empId,
      'position': position,
      'department': department,
      'avatar': avatar,
    };
  }
}

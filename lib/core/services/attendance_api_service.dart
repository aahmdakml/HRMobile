import 'package:dio/dio.dart';
import 'package:mobile_app/core/constants/api_config.dart';

/// Attendance API Service
/// Connects to Laravel backend for attendance operations
/// USING TEST ENDPOINTS (NO AUTH) - Update when auth is ready
class AttendanceApiService {
  // Test endpoint path (no auth required)
  static const String testBaseUrl = '${ApiConfig.apiBasePath}/test/attendance';

  // Default test emp_id - matches seeded employee
  static String _empId = '601120045'; // Fallback

  // Dio instance for test endpoints
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: testBaseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
  ));

  static void setEmpId(String empId) {
    _empId = empId;
  }

  static void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Get today's attendance status
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _dio.get('/status/$_empId');
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ??
          'Failed to get attendance status: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Get allowed office locations
  static Future<List<Map<String, dynamic>>> getLocations() async {
    try {
      final response = await _dio.get('/locations/$_empId');
      return List<Map<String, dynamic>>.from(response.data['data']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get locations');
    }
  }

  /// Check in
  static Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    String? mac,
  }) async {
    try {
      final response = await _dio.post(
        '/check-in/$_empId',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (mac != null) 'mac': mac,
        },
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Check-in failed');
    }
  }

  /// Check out
  static Future<Map<String, dynamic>> checkOut({
    required double latitude,
    required double longitude,
    String? mac,
  }) async {
    try {
      final response = await _dio.post(
        '/check-out/$_empId',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (mac != null) 'mac': mac,
        },
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Check-out failed');
    }
  }

  /// Start break
  static Future<Map<String, dynamic>> breakIn({
    required double latitude,
    required double longitude,
    String? mac,
  }) async {
    try {
      final response = await _dio.post(
        '/break-in/$_empId',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (mac != null) 'mac': mac,
        },
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Break-in failed');
    }
  }

  /// End break
  static Future<Map<String, dynamic>> breakOut({
    required double latitude,
    required double longitude,
    String? mac,
  }) async {
    try {
      final response = await _dio.post(
        '/break-out/$_empId',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (mac != null) 'mac': mac,
        },
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Break-out failed');
    }
  }

  /// Reset attendance (TEST ONLY)
  static Future<void> resetAttendance() async {
    try {
      await _dio.delete('/reset/$_empId');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Reset failed');
    }
  }
}

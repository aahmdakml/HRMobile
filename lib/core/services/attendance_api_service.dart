import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_app/core/constants/api_config.dart';
import 'package:mobile_app/core/services/cache_service.dart';
import 'package:mobile_app/core/services/time_service.dart';

/// Attendance API Service
/// Connects to Laravel backend for attendance operations
/// USING TEST ENDPOINTS (NO AUTH) - Update when auth is ready
class AttendanceApiService {
  // Test endpoint path (no auth required)
  static const String testBaseUrl = '${ApiConfig.apiBasePath}/test/attendance';

  // Cache key for attendance security data
  static const String _cacheKeyLocations = 'attendance_security';

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

  /// Get allowed office locations - FROM CACHE (for 5-sec checks)
  /// Use syncLocations() to refresh from server
  static Future<List<Map<String, dynamic>>> getLocations() async {
    // Try cache first
    final cached = await CacheService.getData(_cacheKeyLocations);
    if (cached != null && cached is List) {
      debugPrint('CACHE: Using cached locations (${cached.length} items)');
      return List<Map<String, dynamic>>.from(
          cached.map((e) => Map<String, dynamic>.from(e)));
    }

    // No cache? Fetch from server (first time)
    debugPrint('CACHE: No cache found, fetching from server...');
    return await syncLocations();
  }

  /// Sync locations from server and update cache
  /// Call this on app start and manual refresh ONLY
  static Future<List<Map<String, dynamic>>> syncLocations() async {
    try {
      debugPrint('API: Fetching locations from server...');

      // 1. Fetch Locations
      final response = await _dio.get('/locations/$_empId');
      final data = List<Map<String, dynamic>>.from(response.data['data']);

      // 2. Fetch Status (for Server Time)
      // We do this in parallel or sequence? Sequence is safer.
      try {
        final statusResponse = await _dio.get('/status/$_empId');
        final serverTimeStr = statusResponse.data['data']['server_time'];
        if (serverTimeStr != null) {
          final serverTime = DateTime.tryParse(serverTimeStr);
          if (serverTime != null) {
            await TimeService.syncServerTime(serverTime);
            debugPrint('CACHE: Synced server time anchor: $serverTime');
          }
        }
      } catch (e) {
        debugPrint('API: Warning - could not sync server time: $e');
      }

      // 3. Save Locations to cache
      await CacheService.setData(_cacheKeyLocations, data);
      debugPrint('CACHE: Saved ${data.length} locations to cache');

      return data;
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

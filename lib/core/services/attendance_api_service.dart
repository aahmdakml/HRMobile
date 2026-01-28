import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_app/core/constants/api_config.dart';
import 'package:mobile_app/core/services/cache_service.dart';
import 'package:mobile_app/core/services/time_service.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// Attendance API Service
/// Connects to Laravel backend for attendance operations
/// USES AUTHENTICATED ENDPOINTS - Requires Auth Token
class AttendanceApiService {
  // Mobile app authenticated routes base path
  // Routes: /hris/profile/mobile-attendance/status, /check-in, etc.
  static const String baseUrl =
      '${ApiConfig.apiBasePath}/hris/profile/mobile-attendance';

  // Cache key for attendance security data
  static const String _cacheKeyLocations = 'attendance_security';

  // Dio instance
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  static void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    debugPrint('API: Token set for attendance service');
  }

  /// Get today's attendance status
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _dio.get('/status');
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
  /// Cache auto-expires after 6 hours
  static Future<List<Map<String, dynamic>>> getLocations() async {
    // Try cache first
    final cached = await CacheService.getData(_cacheKeyLocations);

    if (cached != null && cached is Map) {
      // Check if cache has expired (6 hours = 21600000 ms)
      final timestamp = cached['timestamp'] as int?;
      final data = cached['data'] as List?;

      if (timestamp != null && data != null) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        const maxCacheAge = 6 * 60 * 60 * 1000; // 6 hours in milliseconds

        if (cacheAge < maxCacheAge) {
          debugPrint(
              'CACHE: Using cached locations (${data.length} items, age: ${(cacheAge / 1000 / 60).toStringAsFixed(1)} min)');
          return List<Map<String, dynamic>>.from(
              data.map((e) => Map<String, dynamic>.from(e)));
        } else {
          debugPrint(
              'CACHE: Cache expired (age: ${(cacheAge / 1000 / 60 / 60).toStringAsFixed(1)} hours) - fetching fresh data');
        }
      }
    }

    // No cache or expired? Fetch from server (first time or after expiry)
    debugPrint('CACHE: No valid cache found, fetching from server...');
    return await syncLocations();
  }

  /// Sync locations from server and update cache
  /// Call this on app start and manual refresh ONLY
  static Future<List<Map<String, dynamic>>> syncLocations() async {
    try {
      debugPrint('API: Fetching locations from server...');

      // 1. Fetch Locations
      final response = await _dio.get('/locations');
      final data = List<Map<String, dynamic>>.from(response.data['data']);

      // 2. Fetch Status (for Server Time)
      try {
        final statusResponse = await _dio.get('/status');
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

      // 3. Save Locations to cache WITH TIMESTAMP for expiry tracking
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };
      await CacheService.setData(_cacheKeyLocations, cacheData);
      debugPrint(
          'CACHE: Saved ${data.length} locations to cache with timestamp');

      return data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get locations');
    }
  }

  /// Helper: Get WiFi BSSID (Connected Router MAC)
  static Future<String?> _getWifiBssid() async {
    try {
      final info = NetworkInfo();
      return await info.getWifiBSSID();
    } catch (e) {
      debugPrint('API: Error getting WiFi BSSID: $e');
      return null;
    }
  }

  /// Check in
  static Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    String? mac,
  }) async {
    try {
      final bssid = mac ?? await _getWifiBssid();

      debugPrint(
          'API: checkIn request - lat: $latitude, lng: $longitude, mac: $bssid');

      final response = await _dio.post(
        '/check-in',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (bssid != null) 'mac_address': bssid,
        },
      );

      debugPrint(
          'API: checkIn response - ${response.statusCode} - ${response.data}');

      return response.data['data'];
    } on DioException catch (e) {
      debugPrint(
          'API: checkIn ERROR - ${e.response?.statusCode} - ${e.response?.data}');
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
      final bssid = mac ?? await _getWifiBssid();

      final response = await _dio.post(
        '/check-out',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (bssid != null) 'mac_address': bssid,
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
      final bssid = mac ?? await _getWifiBssid();

      final response = await _dio.post(
        '/break-in',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (bssid != null) 'mac_address': bssid,
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
      final bssid = mac ?? await _getWifiBssid();

      final response = await _dio.post(
        '/break-out',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (bssid != null) 'mac_address': bssid,
        },
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Break-out failed');
    }
  }

  /// Reset attendance (DEBUG ONLY)
  static Future<void> resetAttendance() async {
    try {
      await _dio.delete('/reset');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Reset failed');
    }
  }
}

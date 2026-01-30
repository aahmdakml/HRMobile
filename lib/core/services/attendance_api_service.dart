import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_app/core/services/cache_service.dart';
import 'package:mobile_app/core/services/time_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_app/core/services/api_client.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// Attendance API Service
/// Connects to Laravel backend for attendance operations
/// USES AUTHENTICATED ENDPOINTS - Requires Auth Token
class AttendanceApiService {
  // Base path relative to ApiClient base URL (which ends in /api/v1)
  static const String _basePath = '/hris/profile/mobile-attendance';

  // Cache key for attendance security data
  static const String _cacheKeyLocations = 'attendance_security';

  /// Get today's attendance status
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await apiClient.get('$_basePath/status');
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
      final response = await apiClient.get('$_basePath/locations');
      final data = List<Map<String, dynamic>>.from(response.data['data']);

      // 2. Fetch Status (for Server Time)
      try {
        final statusResponse = await apiClient.get('$_basePath/status');
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

  // Cache for pre-loaded data
  static Map<String, dynamic>? cachedStatus;
  static ValidationResult? cachedValidation;

  /// Pre-load all attendance data (Status + Validation) in background
  static Future<void> preloadData() async {
    try {
      debugPrint('ATTENDANCE_PRELOAD: Starting...');

      // 1. Fetch Status & Locations in parallel
      await Future.wait([
        getStatus().then((data) => cachedStatus = data),
        syncLocations(), // Updates cache
      ]);

      // 2. Run Validation Logic (GPS + MAC)
      // We run this *after* locations are synced so we validate against fresh rules
      cachedValidation = await _runBackgroundValidation();

      debugPrint('ATTENDANCE_PRELOAD: Complete. '
          'LocValid=${cachedValidation?.isLocationValid}, '
          'NetValid=${cachedValidation?.isNetworkValid}');
    } catch (e) {
      debugPrint('ATTENDANCE_PRELOAD: Error: $e');
    }
  }

  /// Run detailed validation logic (duplicated from AttendanceScreen for background run)
  static Future<ValidationResult> _runBackgroundValidation() async {
    bool isLocationValid = false;
    String locationName = 'Checking...';
    bool isNetworkValid = false;
    String networkName = 'Checking...';

    // --- A. Location Check ---
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Don't request in background to avoid intrusive popups, just fail
        locationName = 'Permission denied';
      } else if (permission == LocationPermission.deniedForever) {
        locationName = 'Permission blocked';
      } else {
        // Permission granted, check position
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Medium for speed
          timeLimit: const Duration(seconds: 5),
        );

        final locations = await getLocations();

        bool isValid = false;
        String matched = 'Out of range';

        for (var location in locations) {
          final isEnableGps = location['is_enable_gps'] ?? true;
          final name = location['location_name']?.toString() ?? 'Mobile';

          if (!isEnableGps) {
            isValid = true;
            matched = 'Verified';
            break;
          } else {
            // Strict check
            final lat = double.tryParse(location['latitude'].toString());
            final lng = double.tryParse(location['longitude'].toString());
            final radius =
                double.tryParse(location['radius'].toString()) ?? 100.0;

            if (lat != null && lng != null) {
              final distance = Geolocator.distanceBetween(
                position.latitude,
                position.longitude,
                lat,
                lng,
              );
              if (distance <= radius) {
                isValid = true;
                matched = name;
                break;
              }
            }
          }
        }
        isLocationValid = isValid;
        locationName = matched;
      }
    } catch (e) {
      locationName = 'GPS Error';
    }

    // --- B. Network Check ---
    try {
      final info = NetworkInfo();
      final bssid = await info.getWifiBSSID();

      final locations = await getLocations();
      bool isValid = false;
      String matched = 'Unknown Network';

      for (var location in locations) {
        final isEnableMac = location['is_enable_mac'] ?? false;
        final name = location['location_name']?.toString() ?? 'Mobile';

        if (!isEnableMac) {
          isValid = true;
          matched = 'Verified';
          break;
        } else {
          // Strict check
          if (bssid == null || bssid == '02:00:00:00:00:00') continue;

          final macList = location['mac'];
          if (macList == null) continue;

          List<String> allowedMacs = [];
          if (macList is List) {
            allowedMacs = macList.map((m) => m.toString()).toList();
          } else if (macList is String) {
            allowedMacs = [
              macList
            ]; // Handle raw string if json decode failed/skipped
            // Try to decode if looks like JSON
            if (macList.startsWith('[')) {
              try {
                // Manual simple parse if simple list
              } catch (_) {}
            }
          }
          // For robustness, we assume getLocations returns parsed list if handled or raw
          // Using loose check

          // Simple approach: Check if BSSID is in the string representation if parsing is complex or just assume getLocations returns logic
          // Re-using logic:
          if (allowedMacs.contains(bssid) ||
              allowedMacs.contains(bssid.toUpperCase()) ||
              macList.toString().toUpperCase().contains(bssid.toUpperCase())) {
            isValid = true;
            matched = name;
            break;
          }
        }
      }

      if (!isValid && (bssid == null || bssid == '02:00:00:00:00:00')) {
        isNetworkValid = false;
        networkName = 'No WiFi';
      } else {
        isNetworkValid = isValid;
        networkName = isValid ? matched : 'Unknown Network';
      }
    } catch (e) {
      networkName = 'WiFi Error';
    }

    return ValidationResult(
      isLocationValid: isLocationValid,
      locationName: locationName,
      isNetworkValid: isNetworkValid,
      networkName: networkName,
    );
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

      final response = await apiClient.post(
        '$_basePath/check-in',
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

      final response = await apiClient.post(
        '$_basePath/check-out',
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

      final response = await apiClient.post(
        '$_basePath/break-in',
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

      final response = await apiClient.post(
        '$_basePath/break-out',
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
      await apiClient.delete('$_basePath/reset');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Reset failed');
    }
  }
}

/// Result of background validation
class ValidationResult {
  final bool isLocationValid;
  final String locationName;
  final bool isNetworkValid;
  final String networkName;

  ValidationResult({
    required this.isLocationValid,
    required this.locationName,
    required this.isNetworkValid,
    required this.networkName,
  });
}

import 'package:mobile_app/core/services/cache_service.dart';

/// Time Service
/// Handles secure server time synchronization using monotonic stopwatch
class TimeService {
  // Monotonic clock that counts elapsed time since app start
  // Immune to system wall-clock changes
  static final Stopwatch _stopwatch = Stopwatch()..start();

  static const String _cacheKey = 'server_time_anchor';

  // RAM cache to avoid hitting SQLite every second
  static Map<String, dynamic>? _memoryAnchor;

  /// Sync server time and save anchor to cache
  /// Call this whenever we get a trusted time from the server API
  static Future<void> syncServerTime(DateTime serverTime) async {
    final anchor = {
      'server_time': serverTime.toIso8601String(),
      'anchor_uptime_ms': _stopwatch.elapsedMilliseconds,
    };
    _memoryAnchor = anchor; // Update RAM
    await CacheService.setData(_cacheKey, anchor);
  }

  /// Get current server time from cache (offline capable)
  /// Returns null if not synced or invalid
  static Future<DateTime?> getCachedServerTime() async {
    // 1. Try RAM first (fastest)
    Map<String, dynamic>? anchor = _memoryAnchor;

    // 2. If RAM empty, try Disk (SQLite)
    if (anchor == null) {
      anchor = await CacheService.getData(_cacheKey);
      if (anchor != null) {
        _memoryAnchor = anchor; // Populate RAM
      }
    }

    if (anchor == null) return null;

    final serverTimeStr = anchor['server_time'] as String?;
    final anchorUptime = anchor['anchor_uptime_ms'] as int?;

    if (serverTimeStr == null || anchorUptime == null) return null;

    final serverTime = DateTime.tryParse(serverTimeStr);
    if (serverTime == null) return null;

    // Calculate elapsed time since anchor
    final currentUptime = _stopwatch.elapsedMilliseconds;
    final elapsed = currentUptime - anchorUptime;

    // Safety check: if stopwatch reset (app restart), elapsed might be weird
    // Ideally, Stopwatch resets to 0 on restart, so elapsed would be negative
    // if we are comparing to an old anchor from a previous run.
    // However, since Stopwatch is in-memory static, it resets on app kill.
    // But Cache persists key. So 'anchorUptime' will be from PREVIOUS run.
    // e.g. Old run anchor: 100000ms. New run current: 500ms.
    // Elapsed = 500 - 100000 = -99500 (Negative).

    if (elapsed < 0) {
      // Stopwatch reset (app was restarted), invalidating the anchor.
      // We cannot trust the time until next sync.
      return null;
    }

    return serverTime.add(Duration(milliseconds: elapsed)).toLocal();
  }

  /// Clear the RAM cache (call on logout)
  static void clear() {
    _memoryAnchor = null;
  }
}

/// App configuration for API and environment settings
class AppConfig {
  /// Base URL for API
  /// - Physical Device with adb reverse: use localhost (runs `adb reverse tcp:8000 tcp:8000`)
  /// - Android Emulator: use 10.0.2.2 (maps to host localhost)
  /// - Production: use actual server URL
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  /// Token expiry (from backend: 1 day = 24 hours)
  static const int tokenExpiryHours = 24;

  /// App version
  static const String version = '1.0.0';

  /// Debug mode
  static const bool isDebug = bool.fromEnvironment('DEBUG', defaultValue: true);
}

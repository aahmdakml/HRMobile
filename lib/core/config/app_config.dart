/// App configuration for API and environment settings
class AppConfig {
  AppConfig._();

  /// Detect if running in release/production mode
  /// This is automatically true when built with `flutter build apk --release`
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  /// Debug mode - only enabled in non-production builds
  /// Controls API logging, verbose errors, etc.
  static const bool isDebug = !isProduction;

  /// Base URL for API
  /// - Production: Uses HTTPS only
  /// - Development: Allows HTTP for localhost testing
  static String get apiBaseUrl {
    if (isProduction) {
      // Production API - HTTPS required
      return const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.saraswanti.com/api/v1',
      );
    }
    // Development API - allows HTTP for local testing
    return const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000/api/v1',
    );
  }

  /// Token expiry (from backend: 1 day = 24 hours)
  static const int tokenExpiryHours = 24;

  /// App version
  static const String version = '1.0.0';

  /// Minimum supported API version
  static const String minApiVersion = '1.0';
}

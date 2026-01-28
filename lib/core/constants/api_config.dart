/// API Configuration
/// Central configuration for all API endpoints
class ApiConfig {
  // Base URL for the backend API
  static const String baseUrl = 'http://127.0.0.1:8000';

  // API version
  static const String apiVersion = 'v1';

  // Full API base path
  static const String apiBasePath = '$baseUrl/api/$apiVersion';

  // Module endpoints
  static const String hrisBase = '$apiBasePath/hris';
  static const String profileBase = '$hrisBase/profile';
  static const String attendanceBase = '$hrisBase/attendance';

  // Specific endpoints
  static const String profileAttendance = '$profileBase/attendance';

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

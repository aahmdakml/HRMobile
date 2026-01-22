import 'package:dio/dio.dart';
import 'package:mobile_app/core/services/api_client.dart';
import 'package:mobile_app/features/leave/models/leave_model.dart';

class LeaveService {
  static const String _baseUrl = '/hris/attendance/leave';

  /// Get list of leaves and balance summary
  /// Returns: { 'data': List<LeaveModel>, 'balance': List<LeaveBalance> }
  static Future<Map<String, dynamic>> getLeaves({
    int page = 1,
    int limit = 10,
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'limit': limit,
        'offset': (page - 1) * limit,
      };

      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['leave_type'] = type;
      if (startDate != null)
        queryParams['date_start'] = startDate.toIso8601String();
      if (endDate != null) queryParams['date_end'] = endDate.toIso8601String();

      final response =
          await apiClient.get(_baseUrl, queryParameters: queryParams);

      final responseData = response.data['data'];

      // Parse leaves list
      final List<dynamic> listJson = responseData['data'] ?? [];
      final leaves = listJson.map((json) => LeaveModel.fromJson(json)).toList();

      // Parse balance summary (leave_annual)
      final List<dynamic> balanceJson = responseData['leave_annual'] ?? [];
      final balances =
          balanceJson.map((json) => LeaveBalance.fromJson(json)).toList();

      return {
        'data': leaves,
        'balance': balances,
        'count': responseData['count'] ?? 0,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Create new leave request
  static Future<LeaveModel> createLeave({
    required String timeoffCode,
    required DateTime startDate,
    required DateTime endDate,
    required String description,
    String? attachmentPath,
  }) async {
    try {
      // Calculate total days (inclusive)
      final duration = endDate.difference(startDate).inDays + 1;

      // Generate date array
      final List<String> dates = [];
      for (int i = 0; i < duration; i++) {
        dates.add(
            startDate.add(Duration(days: i)).toIso8601String().split('T')[0]);
      }

      // Payload map
      final Map<String, dynamic> payload = {
        'timeoff_code': timeoffCode,
        'emp_leave_date_start': startDate.toIso8601String().split('T')[0],
        'emp_leave_date_end': endDate.toIso8601String().split('T')[0],
        'emp_leave_total_day': duration,
        'emp_leave_description': description,
        'emp_leave_det_date': dates,
      };

      Response response;
      if (attachmentPath != null) {
        // Use FormData if attachment exists
        final formData = FormData.fromMap(payload);
        // Add dates as array manually if needed, but for simplicity relying on JSON is better.
        // However, if attachment is present, we MUST use FormData.
        // Dio FormData array support:
        // By default Dio sends list as key[] which Laravel accepts.
        // But to be safe, if we have issues, checking how Dio handles it.
        // Let's stick to Map for now for FormData, but JSON is preferred.

        formData.files.add(MapEntry(
          'emp_leave_attachment',
          await MultipartFile.fromFile(attachmentPath),
        ));
        response = await apiClient.post(_baseUrl, data: formData);
      } else {
        // Use JSON
        response = await apiClient.post(_baseUrl, data: payload);
      }

      return LeaveModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel leave request
  static Future<void> cancelLeave(String id) async {
    await apiClient.delete('$_baseUrl/$id');
  }
}

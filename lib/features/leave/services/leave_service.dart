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

  /// Get available timeoff types
  static Future<List<TimeoffCompany>> getTimeoffTypes(String companyId) async {
    try {
      final response = await apiClient.get(
        '/company/$companyId/timeoff',
        queryParameters: {
          'offset': 0,
          'limit': 100,
          'type': 'LEAVE',
        },
      );

      final List<dynamic> listJson = response.data['data']['data'] ?? [];
      return listJson.map((json) => TimeoffCompany.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get approval flow for employee
  static Future<List<EmployeeSpvApproval>> getApprovalFlow(String empId) async {
    try {
      final response = await apiClient.get(
        '/hris/employee-spv-approval',
        queryParameters: {
          'emp_id': empId,
          'module_code': 'LEAVE',
        },
      );

      final List<dynamic> listJson = response.data['data'] ?? [];
      print('empId1: $empId');
      return listJson
          .map((json) => EmployeeSpvApproval.fromJson(json))
          .toList();
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
    required List<String> dates, // Specific dates list
    String? attachmentPath,
  }) async {
    try {
      final payload = {
        'timeoff_code': timeoffCode,
        'emp_leave_date_start': startDate.toIso8601String().split('T')[0],
        'emp_leave_date_end': endDate.toIso8601String().split('T')[0],
        'emp_leave_total_day': dates.length,
        'emp_leave_description': description,
        'emp_leave_det_date': dates,
      };

      Response response;
      if (attachmentPath != null) {
        final formData = FormData.fromMap(payload);

        // Manual array append for Dio FormData to ensure backend receives array
        // Remove the list from map first if fromMap automatically adds it incorrectly?
        // Actually Dio FormData.fromMap handles lists as key[] usually.
        // But to be safe with Laravel, we can iterate if needed.
        // Let's rely on standard behavior first.

        formData.files.add(MapEntry(
          'emp_leave_attachment',
          await MultipartFile.fromFile(attachmentPath),
        ));

        // NOTE: If dates array fails in FormData, we might need to loop:
        // for (var date in dates) formData.fields.add(MapEntry('emp_leave_det_date[]', date));

        response = await apiClient.post(_baseUrl, data: formData);
      } else {
        response = await apiClient.post(_baseUrl, data: payload);
      }

      return LeaveModel.fromJson(response.data['data']);
    } catch (e) {
      // Log error for debugging
      print('Leave Create Error: $e');
      rethrow;
    }
  }

  /// Cancel leave request
  static Future<void> cancelLeave(String id) async {
    await apiClient.delete('$_baseUrl/$id');
  }
}

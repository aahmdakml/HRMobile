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
    String? search,
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

      if (search != null) queryParams['search'] = search;
      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['leave_type'] = type;
      if (startDate != null)
        queryParams['date_start'] = startDate.toIso8601String();
      if (endDate != null) queryParams['date_end'] = endDate.toIso8601String();

      final response =
          await apiClient.get(_baseUrl, queryParameters: queryParams);

      final responseData = response.data['data'];
      print('LEAVE_LIST_RAW: $responseData');

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
    List<String> attachmentPaths = const [],
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
      if (attachmentPaths.isNotEmpty) {
        // Construct FormData manually to ensure arrays are sent correctly with []
        final formData = FormData();

        // Add regular fields
        formData.fields.add(MapEntry('timeoff_code', timeoffCode));
        formData.fields.add(MapEntry(
            'emp_leave_date_start', startDate.toIso8601String().split('T')[0]));
        formData.fields.add(MapEntry(
            'emp_leave_date_end', endDate.toIso8601String().split('T')[0]));
        formData.fields
            .add(MapEntry('emp_leave_total_day', dates.length.toString()));
        formData.fields.add(MapEntry('emp_leave_description', description));

        // Add array fields - KEY MUST HAVE [] FOR LARAVEL VALIDATION
        for (var date in dates) {
          formData.fields.add(MapEntry('emp_leave_det_date[]', date));
        }

        // Add files
        for (var path in attachmentPaths) {
          formData.files.add(MapEntry(
            'emp_leave_attachments[]',
            await MultipartFile.fromFile(path),
          ));
        }

        response = await apiClient.post(_baseUrl, data: formData);
      } else {
        // For JSON requests, Dio handles list properly
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
  /// Delete/Cancel leave request
  static Future<void> deleteLeave(String id) async {
    await apiClient.delete('$_baseUrl/$id');
  }

  /// Get Leave Details including approval history
  static Future<LeaveModel> getLeaveDetail(String id) async {
    try {
      // Use LeaveController endpoint as it includes 'employeeTransactionFiles' for attachments
      final response = await apiClient.get('$_baseUrl/$id');

      print('LEAVE_DETAIL_RAW: ${response.data}');

      return LeaveModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}

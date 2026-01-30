import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_app/core/services/api_client.dart';
import 'package:mobile_app/features/leave/models/leave_model.dart'
    hide TimeOffType;
import 'package:mobile_app/features/permission/models/permission_model.dart';

class PermissionService {
  static const String _baseUrl = '/hris/attendance/permission';

  /// Get list of permissions
  static Future<Map<String, dynamic>> getPermissions({
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
      if (type != null) queryParams['permission_type'] = type;
      if (startDate != null) {
        queryParams['date_start'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['date_end'] = endDate.toIso8601String();
      }

      final response =
          await apiClient.get(_baseUrl, queryParameters: queryParams);

      final responseData = response.data['data'];
      final List<dynamic> listJson = responseData['data'] ?? [];
      final permissions =
          listJson.map((json) => PermissionModel.fromJson(json)).toList();

      return {
        'data': permissions,
        'count': responseData['count'] ?? 0,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get single permission detail
  static Future<PermissionModel> getPermissionDetail(String id) async {
    try {
      final response = await apiClient.get('$_baseUrl/$id');
      debugPrint('PERMISSION_DETAIL: Response data for $id: ${response.data}');
      if (response.data['data'] == null) {
        throw Exception('Permission detail data is null');
      }
      return PermissionModel.fromJson(response.data['data']);
    } catch (e) {
      debugPrint('PERMISSION_DETAIL: Error fetching $id: $e');
      rethrow;
    }
  }

  /// Get available permission types (timeoff types)
  static Future<List<TimeOffType>> getPermissionTypes(String companyId) async {
    try {
      final response = await apiClient.get(
        '/company/$companyId/timeoff',
        queryParameters: {
          'offset': 0,
          'limit': 100,
          'type': 'PERMISSION',
        },
      );

      // Structure is data -> data -> list
      final List<dynamic> listJson = response.data['data']['data'] ?? [];
      return listJson.map((json) {
        // The timeoff object structure might be nested or direct
        // Frontend: item.timeoff_name = item.timeoff_types?.timeoff_name;
        // We reuse TimeOffType.fromJson which expects { 'timeoff_code': '...', 'timeoff_name': '...' }
        // But the API returns CompanyTimeoff object which HAS 'timeoff_types' relation.
        // Let's manually map it to our TimeOffType model
        final typeName = json['timeoff_types']?['timeoff_name'] ??
            json['timeoff_name'] ??
            '';
        final typeCode = json['timeoff_code'];
        final settingJson = json['timeoff_types']?['timeoff_setting'];

        return TimeOffType(
          code: typeCode,
          name: typeName,
          setting:
              settingJson != null ? TimeOffSetting.fromJson(settingJson) : null,
        );
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get approval flow
  static Future<List<EmployeeSpvApproval>> getApprovalFlow(String empId) async {
    try {
      final response = await apiClient.get(
        '/hris/employee-spv-approval',
        queryParameters: {
          'emp_id': empId,
          'module_code': 'PERMISSION',
        },
      );

      final List<dynamic> listJson = response.data['data'] ?? [];
      return listJson
          .map((json) => EmployeeSpvApproval.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create new permission
  static Future<PermissionModel> createPermission({
    required String timeoffCode,
    required DateTime date,
    required String description,
    String? timeStart,
    String? timeEnd,
    double? totalHour,
    List<String> attachmentPaths = const [],
  }) async {
    try {
      final formData = FormData.fromMap({
        'timeoff_code': timeoffCode,
        'emp_permission_date':
            date.toIso8601String().split('T')[0], // YYYY-MM-DD
        'emp_permission_description': description,
        'emp_permission_total_hour': totalHour ?? 1,
      });

      if (timeStart != null) {
        formData.fields.add(MapEntry('emp_permission_time_start', timeStart));
      }
      if (timeEnd != null) {
        formData.fields.add(MapEntry('emp_permission_time_end', timeEnd));
      }

      // Add files
      for (var path in attachmentPaths) {
        final filename = path.split('/').last;
        formData.files.add(MapEntry(
          'emp_permission_attachments[]',
          await MultipartFile.fromFile(path, filename: filename),
        ));
      }

      final response = await apiClient.post(_baseUrl, data: formData);
      return PermissionModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete/Cancel permission
  static Future<void> deletePermission(String id) async {
    try {
      await apiClient.delete('$_baseUrl/$id');
    } catch (e) {
      rethrow;
    }
  }
}

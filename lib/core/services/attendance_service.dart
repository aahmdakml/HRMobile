import 'package:mobile_app/core/services/api_client.dart';
import 'package:flutter/foundation.dart';

/// Attendance Service for HRIS Attendance API calls
class AttendanceService {
  /// Get leave balance
  static Future<AttendanceResult<LeaveBalance>> getLeaveBalance(
      String empId) async {
    try {
      final response =
          await apiClient.get('/hris/attendance/leave-balance/$empId');
      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        return AttendanceResult.success(LeaveBalance.fromJson(data));
      }
      return AttendanceResult.failure(
          response.data['message'] ?? 'Failed to load');
    } catch (e) {
      debugPrint('ATTENDANCE ERROR: $e');
      return AttendanceResult.failure('Connection error');
    }
  }

  /// Get leave requests list
  static Future<AttendanceResult<List<LeaveRequest>>> getLeaveRequests() async {
    try {
      final response = await apiClient.get('/hris/attendance/leave');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        return AttendanceResult.success(
          data.map((e) => LeaveRequest.fromJson(e)).toList(),
        );
      }
      return AttendanceResult.failure(
          response.data['message'] ?? 'Failed to load');
    } catch (e) {
      debugPrint('ATTENDANCE ERROR: $e');
      return AttendanceResult.failure('Connection error');
    }
  }

  /// Submit leave request
  static Future<AttendanceResult<void>> submitLeaveRequest({
    required String leaveType,
    required String startDate,
    required String endDate,
    required String reason,
  }) async {
    try {
      final response = await apiClient.post('/hris/attendance/leave', data: {
        'leave_type': leaveType,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AttendanceResult.success(null);
      }
      return AttendanceResult.failure(
          response.data['message'] ?? 'Failed to submit');
    } catch (e) {
      debugPrint('ATTENDANCE ERROR: $e');
      return AttendanceResult.failure('Connection error');
    }
  }

  /// Get permission requests
  static Future<AttendanceResult<List<PermissionRequest>>>
      getPermissions() async {
    try {
      final response = await apiClient.get('/hris/attendance/permission');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        return AttendanceResult.success(
          data.map((e) => PermissionRequest.fromJson(e)).toList(),
        );
      }
      return AttendanceResult.failure(
          response.data['message'] ?? 'Failed to load');
    } catch (e) {
      debugPrint('ATTENDANCE ERROR: $e');
      return AttendanceResult.failure('Connection error');
    }
  }

  /// Get public holidays
  static Future<AttendanceResult<List<PublicHoliday>>>
      getPublicHolidays() async {
    try {
      final response = await apiClient.get('/hris/attendance/public-holidays');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        return AttendanceResult.success(
          data.map((e) => PublicHoliday.fromJson(e)).toList(),
        );
      }
      return AttendanceResult.failure(
          response.data['message'] ?? 'Failed to load');
    } catch (e) {
      debugPrint('ATTENDANCE ERROR: $e');
      return AttendanceResult.failure('Connection error');
    }
  }
}

/// Result wrapper
class AttendanceResult<T> {
  final bool success;
  final T? data;
  final String? error;

  AttendanceResult._({required this.success, this.data, this.error});

  factory AttendanceResult.success(T? data) =>
      AttendanceResult._(success: true, data: data);
  factory AttendanceResult.failure(String error) =>
      AttendanceResult._(success: false, error: error);
}

// ============ Models ============

class LeaveBalance {
  final int totalDays;
  final int usedDays;
  final int remainingDays;
  final Map<String, int> balanceByType;

  LeaveBalance({
    required this.totalDays,
    required this.usedDays,
    required this.remainingDays,
    this.balanceByType = const {},
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      totalDays: json['total_days'] ?? json['total'] ?? 0,
      usedDays: json['used_days'] ?? json['used'] ?? 0,
      remainingDays: json['remaining_days'] ?? json['remaining'] ?? 0,
      balanceByType: Map<String, int>.from(json['balance_by_type'] ?? {}),
    );
  }
}

class LeaveRequest {
  final int id;
  final String type;
  final String startDate;
  final String endDate;
  final int days;
  final String status;
  final String? reason;
  final String? approvedBy;
  final String? approvedAt;

  LeaveRequest({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.status,
    this.reason,
    this.approvedBy,
    this.approvedAt,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] ?? 0,
      type: json['leave_type'] ?? json['type'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      days: json['total_days'] ?? json['days'] ?? 0,
      status: json['status'] ?? '',
      reason: json['reason'],
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'],
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
}

class PermissionRequest {
  final int id;
  final String type;
  final String date;
  final String startTime;
  final String endTime;
  final String status;
  final String? reason;

  PermissionRequest({
    required this.id,
    required this.type,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.reason,
  });

  factory PermissionRequest.fromJson(Map<String, dynamic> json) {
    return PermissionRequest(
      id: json['id'] ?? 0,
      type: json['permission_type'] ?? json['type'] ?? '',
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: json['status'] ?? '',
      reason: json['reason'],
    );
  }
}

class PublicHoliday {
  final int id;
  final String name;
  final String date;
  final String? description;

  PublicHoliday({
    required this.id,
    required this.name,
    required this.date,
    this.description,
  });

  factory PublicHoliday.fromJson(Map<String, dynamic> json) {
    return PublicHoliday(
      id: json['id'] ?? 0,
      name: json['holiday_name'] ?? json['name'] ?? '',
      date: json['holiday_date'] ?? json['date'] ?? '',
      description: json['description'],
    );
  }
}

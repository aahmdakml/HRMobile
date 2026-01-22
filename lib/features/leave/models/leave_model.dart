import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_colors.dart';

// Use a simplified model structure based on backend response

class LeaveModel {
  final String id;
  final String empId;
  final String timeoffCode;
  final DateTime dateStart;
  final DateTime dateEnd;
  final int totalDays;
  final String description;
  final String? attachmentUrl;
  final String status;
  final String? statusName; // e.g., 'Disetujui'
  final String? statusColor; // e.g., 'success'
  final TimeOffType? timeOffType;

  // Helpers
  final List<dynamic>? approvalHistory;

  const LeaveModel({
    required this.id,
    required this.empId,
    required this.timeoffCode,
    required this.dateStart,
    required this.dateEnd,
    required this.totalDays,
    required this.description,
    this.attachmentUrl,
    required this.status,
    this.statusName,
    this.statusColor,
    this.timeOffType,
    this.approvalHistory,
  });

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return LeaveModel(
      id: json['emp_leave_id']?.toString() ?? '',
      empId: json['emp_id']?.toString() ?? '',
      timeoffCode: json['timeoff_code']?.toString() ?? '',
      dateStart: parseDate(json['emp_leave_date_start']),
      dateEnd: parseDate(json['emp_leave_date_end']),
      totalDays: int.tryParse(json['emp_leave_total_day'].toString()) ?? 0,
      description: json['emp_leave_description']?.toString() ?? '',
      attachmentUrl: json['emp_leave_attachment']?.toString(),
      status: json['emp_leave_status']?.toString() ?? '',
      statusName: json['leave_status']?['trx_name']?.toString(),
      statusColor: json['leave_status']?['trx_color']?.toString(),
      timeOffType: json['timeoff_type'] != null
          ? TimeOffType.fromJson(json['timeoff_type'])
          : null,
      approvalHistory: json['approval'] as List<dynamic>?,
    );
  }

  Color get color {
    switch (statusColor) {
      case 'success':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'danger':
        return AppColors.error;
      case 'info':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'APPROVED':
        return Icons.check_circle_outline;
      case 'REJECTED':
        return Icons.cancel_outlined;
      case 'WAITING_APPROVAL':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }
}

class TimeOffType {
  final String code;
  final String name;
  final String? description;

  const TimeOffType({
    required this.code,
    required this.name,
    this.description,
  });

  factory TimeOffType.fromJson(Map<String, dynamic> json) {
    return TimeOffType(
      code: json['timeoff_code'] ?? '',
      name: json['timeoff_name'] ?? '',
      description: json['timeoff_desc'],
    );
  }
}

class LeaveBalance {
  final int year;
  final int remaining;

  const LeaveBalance({required this.year, required this.remaining});

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    // Handle both int and double values from backend
    int parseIntSafe(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      // Try parsing as double first (handles "9.0")
      final parsed = double.tryParse(value.toString());
      return parsed?.toInt() ?? 0;
    }

    return LeaveBalance(
      year: parseIntSafe(json['lb_year']),
      remaining: parseIntSafe(json['lb_remaining']),
    );
  }
}

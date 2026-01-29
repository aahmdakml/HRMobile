import 'package:flutter/material.dart';
import 'package:mobile_app/core/config/app_config.dart';
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
  final List<String> attachmentUrls;
  final String status;
  final String? statusName; // e.g., 'Disetujui'
  final String? statusColor; // e.g., 'success'
  final TimeOffType? timeOffType;

  // Helpers
  final List<LeaveApproval>? approvalHistory;

  const LeaveModel({
    required this.id,
    required this.empId,
    required this.timeoffCode,
    required this.dateStart,
    required this.dateEnd,
    required this.totalDays,
    required this.description,
    this.attachmentUrls = const [],
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

    // Helper to constructing full URL
    String getFullUrl(String? path) {
      if (path == null) return '';
      if (path.startsWith('http')) return path;

      // Remove /api/v1 from base URL to get root
      final rootUrl = AppConfig.apiBaseUrl.replaceAll('/api/v1', '');

      // Backend stores as 'uploads/...', but public link needs '/storage/uploads/...'
      String cleanPath = path;
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }

      if (cleanPath.startsWith('uploads/')) {
        cleanPath = 'storage/$cleanPath';
      }

      return '$rootUrl$cleanPath';
    }

    return LeaveModel(
      id: json['emp_leave_id']?.toString() ?? '',
      empId: json['emp_id']?.toString() ?? '',
      timeoffCode: json['timeoff_code']?.toString() ?? '',
      dateStart: parseDate(json['emp_leave_date_start']),
      dateEnd: parseDate(json['emp_leave_date_end']),
      totalDays: int.tryParse(json['emp_leave_total_day'].toString()) ?? 0,
      description: json['emp_leave_description']?.toString() ?? '',
      attachmentUrls: (json['employee_transaction_files'] as List<dynamic>?)
              ?.map((e) => getFullUrl(e['etf_file']?.toString()))
              .where((e) => e != '')
              .cast<String>()
              .toList() ??
          [],
      status: json['emp_leave_status']?.toString() ?? '',
      statusName: json['leave_status']?['trx_name']?.toString(),
      statusColor: json['leave_status']?['trx_color']?.toString(),
      timeOffType: json['timeoff_type'] != null
          ? TimeOffType.fromJson(json['timeoff_type'])
          : null,
      approvalHistory: (json['approval'] as List<dynamic>?)
          ?.map((e) => LeaveApproval.fromJson(e))
          .toList(),
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

class LeaveApproval {
  final String approverId;
  final String approverName;
  final String? approverImage;
  final String status;
  final String statusName;
  final String statusColor;
  final int order;
  final DateTime? updatedAt;

  const LeaveApproval({
    required this.approverId,
    required this.approverName,
    this.approverImage,
    required this.status,
    required this.statusName,
    required this.statusColor,
    required this.order,
    this.updatedAt,
  });

  factory LeaveApproval.fromJson(Map<String, dynamic> json) {
    return LeaveApproval(
      approverId: json['emp_id_approver']?.toString() ?? '',
      approverName:
          json['employee_approver']?['emp_full_name']?.toString() ?? 'Unknown',
      approverImage: json['employee_approver']?['path_image']?.toString(),
      status: json['status_id']?.toString() ?? '',
      statusName: json['status']?['trx_name']?.toString() ?? '',
      statusColor: json['status']?['trx_color']?.toString() ?? '',
      order: int.tryParse(json['order']?.toString() ?? '0') ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
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
  final DateTime? expiredDate;

  const LeaveBalance({
    required this.year,
    required this.remaining,
    this.expiredDate,
  });

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

    DateTime? parseDateSafe(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return LeaveBalance(
      year: parseIntSafe(json['lb_year']),
      remaining: parseIntSafe(json['lb_remaining']),
      expiredDate: parseDateSafe(json['lb_expire_date'] ??
          json['lb_exp_date'] ??
          json['expired_date']),
    );
  }
}

class TimeoffCompany {
  final String code;
  final String? name; // From relation
  final int? maxDays;
  final bool needsApproval;
  final bool isDeductAnnual;

  const TimeoffCompany({
    required this.code,
    this.name,
    this.maxDays,
    required this.needsApproval,
    this.isDeductAnnual = false,
  });

  factory TimeoffCompany.fromJson(Map<String, dynamic> json) {
    int? parseMaxDays(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();

      final str = value.toString();
      // Try parsing as simple int first
      final parsedInt = int.tryParse(str);
      if (parsedInt != null) return parsedInt;

      // Try parsing as double for cases like "4.00"
      final parsedDouble = double.tryParse(str);
      if (parsedDouble != null) return parsedDouble.toInt();

      return null;
    }

    // Debug print to check raw data
    debugPrint(
        'Timeoff Raw: ${json['timeoff_types']?['timeoff_name']} -> tc_max_days: ${json['tc_max_days']}');

    return TimeoffCompany(
      code: json['timeoff_code'] ?? '',
      name: json['timeoff_types']?['timeoff_name'],
      maxDays: parseMaxDays(json['tc_max_days']),
      needsApproval: json['tc_needs_approval'] == true ||
          json['tc_needs_approval'] == 1 ||
          json['tc_needs_approval'] == '1',
      isDeductAnnual: json['tc_deduction_annual'] == true ||
          json['tc_deduction_annual'] == 1 ||
          json['tc_deduction_annual'] == '1',
    );
  }
}

class EmployeeSpvApproval {
  final String id;
  final String approverName;
  final String? approverTitle;
  final String? approverCompany;

  const EmployeeSpvApproval({
    required this.id,
    required this.approverName,
    this.approverTitle,
    this.approverCompany,
  });

  factory EmployeeSpvApproval.fromJson(Map<String, dynamic> json) {
    final toEmployee = json['to_employee'] ?? {};
    return EmployeeSpvApproval(
      id: json['id']?.toString() ?? '',
      approverName: toEmployee['emp_name'] ??
          toEmployee['emp_full_name'] ??
          json['emp_id_to'] ??
          '-',
      approverTitle: toEmployee['job_title'],
      approverCompany: toEmployee['company'],
    );
  }
}

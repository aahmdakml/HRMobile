import 'package:flutter/material.dart';
import 'package:mobile_app/core/config/app_config.dart';
import 'package:mobile_app/core/theme/app_colors.dart';

class PermissionModel {
  final String id;
  final String empId;
  final String? timeoffCode;
  final TimeOffType? timeOffType;
  final DateTime? date;
  final String? timeStart; // Format: HH:mm:ss
  final String? timeEnd; // Format: HH:mm:ss
  final double? totalHour;
  final String description;
  final String status; // status_id
  final String? statusName;
  final List<String> attachmentUrls;
  final List<PermissionApproval>? approvalHistory;

  PermissionModel({
    required this.id,
    required this.empId,
    this.timeoffCode,
    this.timeOffType,
    this.date,
    this.timeStart,
    this.timeEnd,
    this.totalHour,
    required this.description,
    required this.status,
    this.statusName,
    this.attachmentUrls = const [],
    this.approvalHistory,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) {
    // Parse Attachments
    List<String> attachments = [];
    if (json['employee_transaction_files'] != null) {
      attachments = (json['employee_transaction_files'] as List)
          .map((f) => getFullUrl(f['etf_file'] ?? ''))
          .where((url) => url.isNotEmpty)
          .toList();
    } else if (json['emp_permission_attachments'] != null) {
      // Handle response that might return the uploaded files key directly
      attachments = (json['emp_permission_attachments'] as List)
          .map((f) => getFullUrl(f.toString()))
          .where((url) => url.isNotEmpty)
          .toList();
    } else if (json['emp_permission_attachment'] != null) {
      // Legacy single file support
      final url = getFullUrl(json['emp_permission_attachment']);
      if (url.isNotEmpty) attachments.add(url);
    }

    // Parse Approval History
    List<PermissionApproval>? approvals;
    if (json['approval'] != null) {
      approvals = (json['approval'] as List)
          .map((e) => PermissionApproval.fromJson(e))
          .toList();
      // Sort by sequence or date if needed (usually backend sorts)
    }

    return PermissionModel(
      id: json['emp_permission_id']?.toString() ?? '',
      empId: json['emp_id']?.toString() ?? '',
      timeoffCode: json['timeoff_code'],
      timeOffType: json['timeoff_type'] != null
          ? TimeOffType.fromJson(json['timeoff_type'])
          : null,
      date: json['emp_permission_date'] != null
          ? DateTime.parse(json['emp_permission_date'])
          : null,
      timeStart: json['emp_permission_time_start'],
      timeEnd: json['emp_permission_time_end'],
      totalHour: json['emp_permission_total_hour'] != null
          ? double.tryParse(json['emp_permission_total_hour'].toString())
          : null,
      description: json['emp_permission_description'] ?? '',
      status: json['status_id']?.toString() ?? 'WAITING_APPROVAL',
      statusName: json['permission_status']?['status_name'],
      attachmentUrls: attachments,
      approvalHistory: approvals,
    );
  }

  static String getFullUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Use AppConfig for base URL
    String baseUrl = AppConfig.apiBaseUrl;
    // Remove /api/v1 if present to get root URL
    baseUrl = baseUrl.replaceAll('/api/v1', '');
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }

    // Ensure path doesn't start with / if we add one
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // Add storage prefix if needed AND not already present
    // Backend stores as 'uploads/...'. We need '/storage/uploads/...'
    if (!cleanPath.startsWith('storage/')) {
      cleanPath = 'storage/$cleanPath';
    }

    return '$baseUrl/$cleanPath';
  }

  Color get color {
    switch (status) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      case 'WAITING_APPROVAL':
        return AppColors.warning;
      case 'CANCELED':
        return Colors.grey;
      default:
        return AppColors.textSecondary;
    }
  }
}

class TimeOffType {
  final String code;
  final String name;
  final TimeOffSetting? setting;

  TimeOffType({
    required this.code,
    required this.name,
    this.setting,
  });

  factory TimeOffType.fromJson(Map<String, dynamic> json) {
    return TimeOffType(
      code: json['timeoff_code'] ?? '',
      name: json['timeoff_name'] ?? '',
      setting: json['timeoff_setting'] != null
          ? TimeOffSetting.fromJson(json['timeoff_setting'])
          : null,
    );
  }
}

class TimeOffSetting {
  final bool needStartTime;
  final bool needEndTime;

  TimeOffSetting({
    this.needStartTime = false,
    this.needEndTime = false,
  });

  factory TimeOffSetting.fromJson(Map<String, dynamic> json) {
    return TimeOffSetting(
      needStartTime: json['need_start_time'] == true ||
          json['need_start_time'] == 1 ||
          json['need_start_time'] == '1',
      needEndTime: json['need_end_time'] == true ||
          json['need_end_time'] == 1 ||
          json['need_end_time'] == '1',
    );
  }
}

class PermissionApproval {
  final String id;
  final String approverName;
  final String? approverImage;
  final String status;
  final String? statusName;
  final DateTime? date;
  final String? comment;

  PermissionApproval({
    required this.id,
    required this.approverName,
    this.approverImage,
    required this.status,
    this.statusName,
    this.date,
    this.comment,
  });

  factory PermissionApproval.fromJson(Map<String, dynamic> json) {
    final approver = json['employee_approver'];
    return PermissionApproval(
      id: json['trans_app_id']?.toString() ?? '',
      approverName: approver?['emp_full_name'] ?? 'Unknown',
      approverImage: PermissionModel.getFullUrl(approver?['path_image'] ?? ''),
      status: json['status_id']?.toString() ?? 'WAITING_APPROVAL',
      statusName: json['status']?['status_name'],
      date: json['trans_app_date'] != null
          ? DateTime.parse(json['trans_app_date'])
          : null,
      comment: json['trans_app_comment'],
    );
  }

  Color get color {
    switch (status) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      case 'WAITING_APPROVAL':
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }
}

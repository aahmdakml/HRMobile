// lib/features/leave/models/employee_spv_approval.dart

class EmployeeSpvApproval {
  final String empId;
  final String spvEmpId;
  final String spvName;
  final String?  spvEmail;
  final int level; // Approval level (1, 2, 3, etc.)
  final String moduleCode;

  const EmployeeSpvApproval({
    required this. empId,
    required this. spvEmpId,
    required this.spvName,
    this.spvEmail,
    required this.level,
    required this.moduleCode,
  });

  factory EmployeeSpvApproval.fromJson(Map<String, dynamic> json) {
    return EmployeeSpvApproval(
      empId: json['emp_id']?. toString() ?? '',
      spvEmpId: json['spv_emp_id']?.toString() ?? '',
      spvName: json['spv_name']?.toString() ?? '',
      spvEmail: json['spv_email']?.toString(),
      level: int.tryParse(json['approval_level']. toString()) ?? 1,
      moduleCode: json['module_code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'emp_id': empId,
        'spv_emp_id': spvEmpId,
        'spv_name':  spvName,
        'spv_email': spvEmail,
        'approval_level': level,
        'module_code': moduleCode,
      };
}
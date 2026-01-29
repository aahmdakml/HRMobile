/// User model matching backend response
/// Backend returns user with employee relation
class User {
  final int id;
  final String email;
  final String name; // Employee name or email
  final String username; // user_name from users table
  final int? roleId;
  final Employee? employee;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.username,
    this.roleId,
    this.employee,
  });

  /// Parse from backend login/verify response
  factory User.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'] as Map<String, dynamic>?;
    return User(
      id: json['user_id'] ?? json['id'] ?? 0,
      email: json['user_email'] ?? json['email'] ?? '',
      name: emp?['emp_name'] ?? json['user_email'] ?? '',
      username: json['user_name'] ?? json['name'] ?? '',
      roleId: json['role_id'],
      employee: emp != null ? Employee.fromJson(emp) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': id,
        'user_email': email,
        'name': name,
        'user_name': username,
        'role_id': roleId,
        'employee': employee?.toJson(),
      };

  /// Display name (prefer employee name)
  String get displayName => employee?.name ?? email;

  /// Employee ID
  String? get empId => employee?.empId;
}

/// Employee model from backend
class Employee {
  final int id;
  final String empId;
  final String name;
  final String? position;
  final String? department;
  final String? company;
  final String? companyId; // Added companyId
  final String? avatar;
  final String? phone;

  Employee({
    required this.id,
    required this.empId,
    required this.name,
    this.position,
    this.department,
    this.company,
    this.companyId,
    this.avatar,
    this.phone,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      empId: json['emp_id'] ?? '',
      name: json['emp_name'] ?? '',
      position: json['position']?['pos_name'] ?? json['pos_name'],
      department: json['department']?['dept_name'] ?? json['dept_name'],
      company: json['company']?['comp_name'] ?? json['comp_name'],
      companyId: json['company']?['company_id'] ??
          json['emp_company_id'] ??
          json['company_id'],
      avatar: json['emp_image'],
      phone: json['emp_phone'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'emp_id': empId,
        'emp_name': name,
        'pos_name': position,
        'dept_name': department,
        'comp_name': company,
        'emp_company_id': companyId,
        'emp_image': avatar,
        'emp_phone': phone,
      };
}

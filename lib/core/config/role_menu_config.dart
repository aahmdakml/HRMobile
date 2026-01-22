import 'package:flutter/material.dart';
import 'package:mobile_app/i18n/translations.dart';

/// Role-based menu configuration
/// Hardcoded for now, will integrate with backend role_menu table later
///
/// Backend structure reference (sc_mst.role_menu):
/// - role_id (FK to role)
/// - menu_id (FK to menu)

class RoleMenuConfig {
  /// Current user role (will be fetched from AuthState later)
  static const String currentRole = 'staff'; /// -> hardcoded for now

  /// Get modules accessible for current role
  static List<StaffModule> getAccessibleModules() {
    switch (currentRole) {
      case 'staff':
        return _staffModules;
      case 'manager':
        return _managerModules;
      case 'admin':
        return _allModules;
      default:
        return _staffModules;
    }
  }

  /// Get modules by category for All Modules page
  static List<ModuleCategory> getCategorizedModules() {
    final accessible = getAccessibleModules();
    return _categories
        .map((cat) {
          return ModuleCategory(
            id: cat.id,
            name: cat.name,
            icon: cat.icon,
            modules: cat.modules
                .where((m) => accessible.any((a) => a.id == m.id))
                .toList(),
          );
        })
        .where((cat) => cat.modules.isNotEmpty)
        .toList();
  }

  /// Get default featured module IDs for new users
  static List<String> getDefaultFeaturedIds() {
    return ['clock_in', 'leave', 'profile'];
  }

  /// Get module by ID
  static StaffModule? getModuleById(String id) {
    return _allModules.firstWhereOrNull((m) => m.id == id);
  }
}

// ============ Staff Modules for Staff Role ============

final List<StaffModule> _staffModules = [
  // Attendance
  StaffModule(
    id: 'clock_in',
    translationKey: 'clockIn',
    icon: Icons.fingerprint,
    color: const Color(0xFF22C55E), // Green
    route: '/attendance/clock-in',
    category: 'attendance',
  ),
  StaffModule(
    id: 'attendance',
    translationKey: 'attendance',
    icon: Icons.event_note_outlined,
    color: const Color(0xFF10B981), // Emerald
    route: '/attendance/history',
    category: 'attendance',
  ),
  StaffModule(
    id: 'overtime',
    translationKey: 'overtime',
    icon: Icons.more_time,
    color: const Color(0xFFF59E0B), // Amber
    route: '/attendance/overtime',
    category: 'attendance',
  ),

  // Leave & Permission
  StaffModule(
    id: 'leave',
    translationKey: 'leave',
    icon: Icons.flight_takeoff,
    color: const Color(0xFFA855F7), // Purple
    route: '/leave/request',
    category: 'leave',
  ),
  StaffModule(
    id: 'permission',
    translationKey: 'permission',
    icon: Icons.schedule,
    color: const Color(0xFF8B5CF6), // Violet
    route: '/leave/permission',
    category: 'leave',
  ),

  // Finance
  StaffModule(
    id: 'payslip',
    translationKey: 'payslip',
    icon: Icons.receipt_long_outlined,
    color: const Color(0xFF3B82F6), // Blue
    route: '/finance/payslip',
    category: 'finance',
  ),
  StaffModule(
    id: 'reimburse',
    translationKey: 'reimburse',
    icon: Icons.account_balance_wallet_outlined,
    color: const Color(0xFF0EA5E9), // Sky
    route: '/finance/reimburse',
    category: 'finance',
  ),
  StaffModule(
    id: 'loan',
    translationKey: 'loan',
    icon: Icons.payments_outlined,
    color: const Color(0xFFF97316), // Orange
    route: '/finance/loan',
    category: 'finance',
  ),

  // Employee
  StaffModule(
    id: 'profile',
    translationKey: 'profile',
    icon: Icons.person_outline,
    color: const Color(0xFF6366F1), // Indigo
    route: '/profile',
    category: 'employee',
  ),
  StaffModule(
    id: 'my_info',
    translationKey: 'myPersonalInfo',
    icon: Icons.badge_outlined,
    color: const Color(0xFF64748B), // Slate
    route: '/profile/info',
    category: 'employee',
  ),

  // Travel
  StaffModule(
    id: 'travel_order',
    translationKey: 'travelOrder',
    icon: Icons.flight,
    color: const Color(0xFF14B8A6), // Teal
    route: '/travel/order',
    category: 'travel',
  ),
];

// ============ Manager Modules (Staff + Approval) ============

final List<StaffModule> _managerModules = [
  ..._staffModules,
  StaffModule(
    id: 'approval',
    translationKey: 'approval',
    icon: Icons.check_circle_outline,
    color: const Color(0xFF059669), // Emerald
    route: '/approval',
    category: 'approval',
  ),
  StaffModule(
    id: 'approval_travel',
    translationKey: 'approvalTravelOrder',
    icon: Icons.approval,
    color: const Color(0xFF0D9488), // Teal
    route: '/approval/travel',
    category: 'approval',
  ),
];

// ============ All Modules (Admin) ============

final List<StaffModule> _allModules = [
  ..._managerModules,
  // Reports
  StaffModule(
    id: 'reports_attendance',
    translationKey: 'reportsAttendance',
    icon: Icons.assessment_outlined,
    color: const Color(0xFF6366F1),
    route: '/reports/attendance',
    category: 'reports',
  ),
  StaffModule(
    id: 'reports_payroll',
    translationKey: 'reportsPayrollSummary',
    icon: Icons.summarize_outlined,
    color: const Color(0xFF3B82F6),
    route: '/reports/payroll',
    category: 'reports',
  ),
];

// ============ Categories ============

final List<ModuleCategory> _categories = [
  ModuleCategory(
    id: 'attendance',
    name: 'Attendance',
    icon: Icons.fingerprint,
    modules: _allModules.where((m) => m.category == 'attendance').toList(),
  ),
  ModuleCategory(
    id: 'leave',
    name: 'Leave & Permission',
    icon: Icons.flight_takeoff,
    modules: _allModules.where((m) => m.category == 'leave').toList(),
  ),
  ModuleCategory(
    id: 'finance',
    name: 'Finance',
    icon: Icons.account_balance_wallet,
    modules: _allModules.where((m) => m.category == 'finance').toList(),
  ),
  ModuleCategory(
    id: 'employee',
    name: 'Employee',
    icon: Icons.person,
    modules: _allModules.where((m) => m.category == 'employee').toList(),
  ),
  ModuleCategory(
    id: 'travel',
    name: 'Travel',
    icon: Icons.flight,
    modules: _allModules.where((m) => m.category == 'travel').toList(),
  ),
  ModuleCategory(
    id: 'approval',
    name: 'Approval',
    icon: Icons.check_circle,
    modules: _allModules.where((m) => m.category == 'approval').toList(),
  ),
  ModuleCategory(
    id: 'reports',
    name: 'Reports',
    icon: Icons.assessment,
    modules: _allModules.where((m) => m.category == 'reports').toList(),
  ),
];

// ============ Models ============

class StaffModule {
  final String id;
  final String translationKey;
  final IconData icon;
  final Color color;
  final String route;
  final String category;

  const StaffModule({
    required this.id,
    required this.translationKey,
    required this.icon,
    required this.color,
    required this.route,
    required this.category,
  });

  /// Get translated name
  String get name => t.module.byKey(translationKey) ?? translationKey;

  /// Get light color (20% opacity)
  Color get lightColor => color.withOpacity(0.15);
}

class ModuleCategory {
  final String id;
  final String name;
  final IconData icon;
  final List<StaffModule> modules;

  const ModuleCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.modules,
  });
}

// ============ Extension ============

extension _ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

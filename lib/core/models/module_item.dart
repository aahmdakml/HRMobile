import 'package:flutter/material.dart';

/// Module data model for dashboard
class ModuleItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isEnabled;

  const ModuleItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isEnabled = true,
  });

  ModuleItem copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    bool? isEnabled,
  }) {
    return ModuleItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// All available modules in HRIS
class HrisModules {
  static const List<ModuleItem> allModules = [
    ModuleItem(
      id: 'clock_in',
      name: 'Clock In',
      icon: Icons.fingerprint,
      color: Color(0xFF50CD89),
    ),
    ModuleItem(
      id: 'leave',
      name: 'Leave',
      icon: Icons.event_note_outlined,
      color: Color(0xFF7239EA),
    ),
    ModuleItem(
      id: 'payslip',
      name: 'Payslip',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFF009EF7),
    ),
    ModuleItem(
      id: 'overtime',
      name: 'Overtime',
      icon: Icons.more_time,
      color: Color(0xFFF1416C),
    ),
    ModuleItem(
      id: 'attendance',
      name: 'Attendance',
      icon: Icons.history,
      color: Color(0xFFFFC700),
    ),
    ModuleItem(
      id: 'travel',
      name: 'Travel Order',
      icon: Icons.flight_takeoff,
      color: Color(0xFF3F4254),
    ),
    ModuleItem(
      id: 'reimburse',
      name: 'Reimburse',
      icon: Icons.request_quote_outlined,
      color: Color(0xFF17C653),
    ),
    ModuleItem(
      id: 'loan',
      name: 'Loan',
      icon: Icons.account_balance_wallet_outlined,
      color: Color(0xFFE4A11B),
    ),
  ];

  /// Get module by ID
  static ModuleItem? getById(String id) {
    try {
      return allModules.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Default featured module IDs for new users
  static const List<String> defaultFeaturedIds = [
    'clock_in',
    'leave',
    'payslip',
  ];
}

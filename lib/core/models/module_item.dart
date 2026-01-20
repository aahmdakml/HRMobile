import 'package:flutter/material.dart';
import 'package:mobile_app/core/services/menu_service.dart';
import 'package:mobile_app/i18n/translations.dart';

/// Module data model for dashboard
/// Supports both hardcoded fallback and backend data
class ModuleItem {
  final String id;
  final String name;
  final IconData icon;
  final Color primaryColor;
  final Color lightColor;
  final String? route;
  final bool isEnabled;

  const ModuleItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.primaryColor,
    required this.lightColor,
    this.route,
    this.isEnabled = true,
  });

  /// Create from backend MobileMenu
  /// Automatically translates menu_heading using i18n
  factory ModuleItem.fromMobileMenu(MobileMenu menu) {
    // Translate database key to human-readable name
    final translatedName = translateModuleKey(menu.heading);

    return ModuleItem(
      id: menu.menuId.toString(),
      name: translatedName,
      icon: _parseIconName(menu.mobileIcon),
      primaryColor: menu.theme != null
          ? Color(menu.theme!.primaryColorValue)
          : const Color(0xFF3B82F6),
      lightColor: menu.theme != null
          ? Color(menu.theme!.lightColorValue)
          : const Color(0xFFDBEAFE),
      route: menu.mobileRoute,
      isEnabled: true,
    );
  }

  /// Parse Flutter icon name string to IconData
  static IconData _parseIconName(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return Icons.apps;
    }

    // Normalize to lowercase for matching
    final normalizedName = iconName.toLowerCase().trim();

    // Map common icon names to IconData
    final iconMap = <String, IconData>{
      'fingerprint': Icons.fingerprint,
      'event_note': Icons.event_note_outlined,
      'event_note_outlined': Icons.event_note_outlined,
      'receipt_long': Icons.receipt_long_outlined,
      'receipt_long_outlined': Icons.receipt_long_outlined,
      'more_time': Icons.more_time,
      'history': Icons.history,
      'flight_takeoff': Icons.flight_takeoff,
      'request_quote': Icons.request_quote_outlined,
      'request_quote_outlined': Icons.request_quote_outlined,
      'account_balance_wallet': Icons.account_balance_wallet_outlined,
      'account_balance_wallet_outlined': Icons.account_balance_wallet_outlined,
      'calendar_today': Icons.calendar_today,
      'calendar_month': Icons.calendar_month,
      'person': Icons.person_outline,
      'person_outline': Icons.person_outline,
      'settings': Icons.settings_outlined,
      'settings_outlined': Icons.settings_outlined,
      'work': Icons.work_outline,
      'work_outline': Icons.work_outline,
      'home': Icons.home_outlined,
      'home_outlined': Icons.home_outlined,
      'badge': Icons.badge_outlined,
      'badge_outlined': Icons.badge_outlined,
      'assignment': Icons.assignment_outlined,
      'assignment_outlined': Icons.assignment_outlined,
      'description': Icons.description_outlined,
      'description_outlined': Icons.description_outlined,
      'folder': Icons.folder_outlined,
      'folder_outlined': Icons.folder_outlined,
      'attach_money': Icons.attach_money,
      'payments': Icons.payments_outlined,
      'payments_outlined': Icons.payments_outlined,
      'schedule': Icons.schedule,
      'access_time': Icons.access_time,
      'timer': Icons.timer_outlined,
      'timer_outlined': Icons.timer_outlined,
      'approval': Icons.approval,
      'check_circle': Icons.check_circle_outline,
      'check_circle_outline': Icons.check_circle_outline,
      'car_rental': Icons.car_rental,
      'meeting_room': Icons.meeting_room_outlined,
      'meeting_room_outlined': Icons.meeting_room_outlined,
      'event': Icons.event,
      'apps': Icons.apps,
    };

    final icon = iconMap[normalizedName];
    if (icon == null) {
      debugPrint('MODULE_ITEM: Unknown icon name "$iconName", using default');
    }
    return icon ?? Icons.apps;
  }

  ModuleItem copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? primaryColor,
    Color? lightColor,
    String? route,
    bool? isEnabled,
  }) {
    return ModuleItem(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      primaryColor: primaryColor ?? this.primaryColor,
      lightColor: lightColor ?? this.lightColor,
      route: route ?? this.route,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// All available modules in HRIS (fallback when offline)
class HrisModules {
  static const List<ModuleItem> allModules = [
    ModuleItem(
      id: 'clock_in',
      name: 'Clock In',
      icon: Icons.fingerprint,
      primaryColor: Color(0xFF22C55E),
      lightColor: Color(0xFFDCFCE7),
      route: '/attendance',
    ),
    ModuleItem(
      id: 'leave',
      name: 'Leave',
      icon: Icons.event_note_outlined,
      primaryColor: Color(0xFF8B5CF6),
      lightColor: Color(0xFFEDE9FE),
      route: '/leave',
    ),
    ModuleItem(
      id: 'payslip',
      name: 'Payslip',
      icon: Icons.receipt_long_outlined,
      primaryColor: Color(0xFF3B82F6),
      lightColor: Color(0xFFDBEAFE),
      route: '/payslip',
    ),
    ModuleItem(
      id: 'overtime',
      name: 'Overtime',
      icon: Icons.more_time,
      primaryColor: Color(0xFFEF4444),
      lightColor: Color(0xFFFEE2E2),
      route: '/overtime',
    ),
    ModuleItem(
      id: 'attendance',
      name: 'Attendance',
      icon: Icons.history,
      primaryColor: Color(0xFFEAB308),
      lightColor: Color(0xFFFEF9C3),
      route: '/attendance-history',
    ),
    ModuleItem(
      id: 'travel',
      name: 'Travel Order',
      icon: Icons.flight_takeoff,
      primaryColor: Color(0xFF6B7280),
      lightColor: Color(0xFFF3F4F6),
      route: '/travel',
    ),
    ModuleItem(
      id: 'reimburse',
      name: 'Reimburse',
      icon: Icons.request_quote_outlined,
      primaryColor: Color(0xFF22C55E),
      lightColor: Color(0xFFDCFCE7),
      route: '/reimburse',
    ),
    ModuleItem(
      id: 'loan',
      name: 'Loan',
      icon: Icons.account_balance_wallet_outlined,
      primaryColor: Color(0xFFF97316),
      lightColor: Color(0xFFFFEDD5),
      route: '/loan',
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

  /// Convert backend menus to ModuleItems
  static List<ModuleItem> fromBackend(List<MobileMenu> menus) {
    return menus.map((m) => ModuleItem.fromMobileMenu(m)).toList();
  }
}

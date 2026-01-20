import 'package:flutter/foundation.dart';
import 'package:mobile_app/core/services/api_client.dart';

/// Menu Service for fetching mobile menu from backend
class MenuService {
  /// Get icon theme templates
  static Future<MenuResult<List<IconTheme>>> getIconThemes() async {
    try {
      final response = await apiClient.get('/mobile/icon-themes');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        return MenuResult.success(
          data.map((e) => IconTheme.fromJson(e)).toList(),
        );
      }
      return MenuResult.failure(response.data['message'] ?? 'Failed');
    } catch (e) {
      debugPrint('MENU SERVICE ERROR: $e');
      return MenuResult.failure('Connection error');
    }
  }

  /// Get user's accessible menus (based on role)
  /// TEMP: Using /menus/all for testing - change back to /menus when role_menu is set up
  static Future<MenuResult<List<MobileMenu>>> getMenus() async {
    try {
      // Using /menus/all temporarily to bypass role filtering
      final response = await apiClient.get('/mobile/menus/all');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        // Filter only menus with mobile_route configured
        final mobileMenus =
            data.where((e) => e['mobile_route'] != null).toList();
        return MenuResult.success(
          mobileMenus.map((e) => MobileMenu.fromJson(e)).toList(),
        );
      }
      return MenuResult.failure(response.data['message'] ?? 'Failed');
    } catch (e) {
      debugPrint('MENU SERVICE ERROR: $e');
      return MenuResult.failure('Connection error');
    }
  }

  /// Get all menus (for admin setup)
  static Future<MenuResult<List<MobileMenu>>> getAllMenus() async {
    try {
      final response = await apiClient.get('/mobile/menus/all');
      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        return MenuResult.success(
          data.map((e) => MobileMenu.fromJson(e)).toList(),
        );
      }
      return MenuResult.failure(response.data['message'] ?? 'Failed');
    } catch (e) {
      debugPrint('MENU SERVICE ERROR: $e');
      return MenuResult.failure('Connection error');
    }
  }
}

/// Result wrapper
class MenuResult<T> {
  final bool success;
  final T? data;
  final String? error;

  MenuResult._({required this.success, this.data, this.error});

  factory MenuResult.success(T data) => MenuResult._(success: true, data: data);
  factory MenuResult.failure(String error) =>
      MenuResult._(success: false, error: error);
}

// ============ Models ============

/// Icon Theme for module styling
class IconTheme {
  final int id;
  final String name;
  final String colorPrimary;
  final String colorLight;
  final int order;
  final bool isActive;

  IconTheme({
    required this.id,
    required this.name,
    required this.colorPrimary,
    required this.colorLight,
    this.order = 0,
    this.isActive = true,
  });

  factory IconTheme.fromJson(Map<String, dynamic> json) {
    return IconTheme(
      id: json['theme_id'] ?? json['id'] ?? 0,
      name: json['theme_name'] ?? json['name'] ?? '',
      colorPrimary:
          json['theme_color_primary'] ?? json['color_primary'] ?? '#3B82F6',
      colorLight: json['theme_color_light'] ?? json['color_light'] ?? '#DBEAFE',
      order: json['theme_order'] ?? json['order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  /// Parse hex color to Flutter Color
  int get primaryColorValue => _parseHex(colorPrimary);
  int get lightColorValue => _parseHex(colorLight);

  int _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return int.parse(hex, radix: 16);
  }
}

/// Mobile Menu item from backend
class MobileMenu {
  final int menuId;
  final int? parentId;
  final String heading;
  final String? mobileRoute;
  final String? mobileIcon;
  final int order;
  final IconTheme? theme;

  MobileMenu({
    required this.menuId,
    this.parentId,
    required this.heading,
    this.mobileRoute,
    this.mobileIcon,
    this.order = 0,
    this.theme,
  });

  factory MobileMenu.fromJson(Map<String, dynamic> json) {
    return MobileMenu(
      menuId: json['menu_id'] ?? 0,
      parentId: json['parent_id'],
      heading: json['heading'] ?? '',
      mobileRoute: json['mobile_route'],
      mobileIcon: json['mobile_icon'],
      order: json['order'] ?? 0,
      theme: json['theme'] != null ? IconTheme.fromJson(json['theme']) : null,
    );
  }

  /// Check if menu has mobile configuration
  bool get hasMobileConfig => mobileRoute != null && mobileRoute!.isNotEmpty;
}

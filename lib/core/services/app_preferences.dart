import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_app/i18n/translations.dart';

/// App Preferences Service
/// Manages theme mode and language preferences with local storage persistence
class AppPreferences extends ChangeNotifier {
  static final AppPreferences _instance = AppPreferences._internal();
  factory AppPreferences() => _instance;
  AppPreferences._internal();

  static const _storage = FlutterSecureStorage();
  static const _keyThemeMode = 'theme_mode';
  static const _keyLocale = 'locale';

  // Theme mode: 'light', 'dark', 'system'
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  bool _isInitialized = false;

  // Getters
  /// Returns effective theme mode for MaterialApp
  /// When user selects 'System', we force Light mode (per user request)
  ThemeMode get themeMode {
    if (_themeMode == ThemeMode.system) {
      return ThemeMode.light; // Force light for system setting
    }
    return _themeMode;
  }

  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  /// Get actual brightness (resolves system mode)
  Brightness get brightness {
    if (_themeMode == ThemeMode.system) {
      // Force Light mode as default for System setting (per user request)
      return Brightness.light;
      // return SchedulerBinding.instance.platformDispatcher.platformBrightness;
    }
    return _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  }

  bool get isDarkMode => brightness == Brightness.dark;

  /// Initialize preferences from storage
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Load theme mode
      final themeModeStr = await _storage.read(key: _keyThemeMode);
      if (themeModeStr != null) {
        _themeMode = _parseThemeMode(themeModeStr);
      }

      // Load locale (or detect from device)
      final localeStr = await _storage.read(key: _keyLocale);
      if (localeStr != null) {
        _locale = Locale(localeStr);
      } else {
        // Detect from device
        final deviceLocale = PlatformDispatcher.instance.locale;
        if (deviceLocale.languageCode == 'id') {
          _locale = const Locale('id');
        } else {
          _locale = const Locale('en');
        }
      }

      // Apply locale to translations
      LocaleSettings.setLocale(_locale);

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('AppPreferences init error: $e');
      _isInitialized = true;
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _storage.write(key: _keyThemeMode, value: _themeModeToString(mode));
    notifyListeners();
  }

  /// Set locale
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    await _storage.write(key: _keyLocale, value: locale.languageCode);
    LocaleSettings.setLocale(locale);
    notifyListeners();
  }

  /// Convenience methods
  Future<void> setLightMode() => setThemeMode(ThemeMode.light);
  Future<void> setDarkMode() => setThemeMode(ThemeMode.dark);
  Future<void> setSystemMode() => setThemeMode(ThemeMode.system);

  Future<void> setEnglish() => setLocale(const Locale('en'));
  Future<void> setIndonesian() => setLocale(const Locale('id'));

  // Helpers
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Get theme mode display name
  String getThemeModeDisplayName() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get locale display name
  String getLocaleDisplayName() {
    switch (_locale.languageCode) {
      case 'id':
        return 'Indonesia';
      case 'en':
      default:
        return 'English';
    }
  }
}

/// Global instance
final appPreferences = AppPreferences();

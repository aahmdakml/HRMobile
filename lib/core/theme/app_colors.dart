import 'package:flutter/material.dart';

/// App color palette based on Enterprise-frontend theme
/// Primary color: #50CD89 (Saraswanti Green)
class AppColors {
  AppColors._();

  // Primary Colors - Saraswanti Green
  static const Color primary = Color(0xFF50CD89);
  static const Color primaryLight = Color(0xFF7EDBA8);
  static const Color primaryDark = Color(0xFF3AAA6D);

  // Secondary Colors
  static const Color secondary = Color(0xFF7239EA);
  static const Color secondaryLight = Color(0xFF9B6EF3);
  static const Color secondaryDark = Color(0xFF5014D0);

  // Background Colors
  static const Color background = Color(0xFFF9F9F9);
  static const Color backgroundDark = Color(0xFF151521);

  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E2D);

  // Text Colors
  static const Color textPrimary = Color(0xFF181C32);
  static const Color textSecondary = Color(0xFF5E6278);
  static const Color textMuted = Color(0xFFA1A5B7);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF50CD89);
  static const Color warning = Color(0xFFFFC700);
  static const Color error = Color(0xFFF1416C);
  static const Color info = Color(0xFF009EF7);

  // Border Colors
  static const Color border = Color(0xFFE4E6EF);
  static const Color borderDark = Color(0xFF323248);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  // Attendance Colors (reusing existing palette)
  static const Color checkIn = primary; // Saraswanti Green
  static const Color breakOut = Color(0xFFFF9100); // Orange
  static const Color resume = info; // Info Blue
  static const Color checkOut = error; // Error Red
  static const Color disabled = textMuted; // Muted Grey
}

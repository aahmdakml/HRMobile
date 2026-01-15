import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// A pill-shaped widget that displays security status (GPS or WiFi)
class SecurityPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isValid;

  const SecurityPill({
    super.key,
    required this.icon,
    required this.label,
    required this.isValid,
  });

  /// Factory for location security pill
  factory SecurityPill.location({
    Key? key,
    required String locationName,
    required bool isValid,
  }) {
    return SecurityPill(
      key: key,
      icon: Icons.location_on,
      label: locationName,
      isValid: isValid,
    );
  }

  /// Factory for network/WiFi security pill
  factory SecurityPill.network({
    Key? key,
    required String networkName,
    required bool isValid,
  }) {
    return SecurityPill(
      key: key,
      icon: Icons.wifi,
      label: networkName,
      isValid: isValid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isValid
        ? AppColors.checkIn.withOpacity(0.15)
        : AppColors.disabled.withOpacity(0.15);

    final contentColor = isValid ? AppColors.checkIn : AppColors.disabled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: contentColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }
}

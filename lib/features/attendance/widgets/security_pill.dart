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

  /// Factory for time/clock security pill
  factory SecurityPill.time({
    Key? key,
    required bool isValid,
  }) {
    return SecurityPill(
      key: key,
      icon: Icons.access_time_filled,
      label: isValid ? 'Time Synced' : 'Unverified Time',
      isValid: isValid,
    );
  }

  @override
  Widget build(BuildContext context) {
    // If not valid, use orange for Time/Warning, red for others?
    // Current logic uses: contentColor = isValid ? checkIn : disabled
    // We might want specific colors for invalid states
    final contentColor = isValid ? AppColors.checkIn : Colors.grey.shade600;
    final backgroundColor = isValid
        ? AppColors.checkIn.withOpacity(0.15)
        : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14, // Smaller icon
            color: contentColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10, // Smaller font
              fontWeight: FontWeight.w600,
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }
}

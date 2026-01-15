import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/attendance_state.dart';

/// A pill-shaped badge showing current attendance status with pulsing dot
class StatusBadge extends StatefulWidget {
  final AttendanceStatus status;
  final String? sinceTime; // e.g., "09:00"

  const StatusBadge({
    super.key,
    required this.status,
    this.sinceTime,
  });

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Only pulse for working and onBreak states
    if (_shouldPulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      if (_shouldPulse) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _shouldPulse =>
      widget.status == AttendanceStatus.working ||
      widget.status == AttendanceStatus.onBreak;

  Color get _statusColor {
    switch (widget.status) {
      case AttendanceStatus.idle:
        return AppColors.disabled;
      case AttendanceStatus.working:
        return AppColors.checkIn;
      case AttendanceStatus.onBreak:
        return AppColors.breakOut;
      case AttendanceStatus.shiftEnded:
        return AppColors.checkOut;
    }
  }

  String get _statusText {
    final label = widget.status.label;
    if (widget.sinceTime != null &&
        (widget.status == AttendanceStatus.working ||
            widget.status == AttendanceStatus.onBreak)) {
      return '$label • SINCE ${widget.sinceTime}';
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing dot
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor.withOpacity(
                    _shouldPulse ? _pulseAnimation.value : 1.0,
                  ),
                  boxShadow: _shouldPulse
                      ? [
                          BoxShadow(
                            color: _statusColor
                                .withOpacity(0.4 * _pulseAnimation.value),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          // Status text
          Text(
            _statusText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _statusColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

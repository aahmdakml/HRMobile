import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/attendance_state.dart';

/// Footer showing attendance stats: Check In Time | Working Hours | Check Out Time
class AttendanceFooter extends StatefulWidget {
  final String? checkInTime; // e.g., "09:00"
  final String? checkOutTime; // e.g., "17:30"
  final AttendanceStatus status;

  const AttendanceFooter({
    super.key,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
  });

  @override
  State<AttendanceFooter> createState() => _AttendanceFooterState();
}

class _AttendanceFooterState extends State<AttendanceFooter> {
  Timer? _workingTimer;
  Duration _workingDuration = Duration.zero;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _initializeTimer();
  }

  @override
  void didUpdateWidget(AttendanceFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status ||
        oldWidget.checkInTime != widget.checkInTime) {
      _initializeTimer();
    }
  }

  void _initializeTimer() {
    _workingTimer?.cancel();

    if (widget.status == AttendanceStatus.working &&
        widget.checkInTime != null) {
      // Parse check-in time and calculate duration
      _startTime = _parseTime(widget.checkInTime!);
      if (_startTime != null) {
        _updateWorkingDuration();
        _workingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          _updateWorkingDuration();
        });
      }
    } else {
      _workingDuration = Duration.zero;
    }
  }

  DateTime? _parseTime(String time) {
    try {
      final parts = time.split(':');
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, int.parse(parts[0]),
          int.parse(parts[1]));
    } catch (e) {
      return null;
    }
  }

  void _updateWorkingDuration() {
    if (_startTime != null) {
      setState(() {
        _workingDuration = DateTime.now().difference(_startTime!);
      });
    }
  }

  @override
  void dispose() {
    _workingTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(
            label: 'Check In',
            value: widget.checkInTime ?? '--:--',
            icon: Icons.login,
            color: AppColors.checkIn,
          ),
          _buildDivider(),
          _buildStatColumn(
            label: 'Working',
            value: widget.status == AttendanceStatus.working
                ? _formatDuration(_workingDuration)
                : '--:--:--',
            icon: Icons.timer,
            color: AppColors.primary,
            isLive: widget.status == AttendanceStatus.working,
          ),
          _buildDivider(),
          _buildStatColumn(
            label: 'Check Out',
            value: widget.checkOutTime ?? '--:--',
            icon: Icons.logout,
            color: AppColors.checkOut,
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isLive = false,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color.withOpacity(0.7)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isLive ? color : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.border,
    );
  }
}

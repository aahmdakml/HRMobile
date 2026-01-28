import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/attendance_state.dart';

/// Footer showing attendance stats: Check In Time | Working Hours | Check Out Time
class AttendanceFooter extends StatefulWidget {
  final String? checkInTime; // e.g., "09:00"
  final String? checkOutTime; // e.g., "17:30"
  final AttendanceStatus status;
  final DateTime? serverTime; // Server time for accurate duration calculation

  const AttendanceFooter({
    super.key,
    this.checkInTime,
    this.checkOutTime,
    required this.status,
    this.serverTime,
  });

  @override
  State<AttendanceFooter> createState() => _AttendanceFooterState();
}

class _AttendanceFooterState extends State<AttendanceFooter> {
  Timer? _workingTimer;
  Duration _workingDuration = Duration.zero;
  DateTime? _startTime;
  DateTime? _simulatedServerTime; // Ticks locally every second for smooth display

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
    // Resync simulated time when fresh server time arrives (every ~5s)
    if (widget.serverTime != null && widget.serverTime != oldWidget.serverTime) {
      _simulatedServerTime = widget.serverTime;
    }
  }

  void _initializeTimer() {
    _workingTimer?.cancel();

    if (widget.status == AttendanceStatus.working &&
        widget.checkInTime != null) {
      // Parse check-in time
      _startTime = _parseTime(widget.checkInTime!);
      // Initialize simulated server time
      _simulatedServerTime = widget.serverTime ?? DateTime.now();
      
      if (_startTime != null) {
        _updateWorkingDuration();
        _workingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          // Tick simulated time forward by 1 second
          if (_simulatedServerTime != null) {
            _simulatedServerTime = _simulatedServerTime!.add(const Duration(seconds: 1));
          }
          _updateWorkingDuration();
        });
      }
    } else {
      _workingDuration = Duration.zero;
      _simulatedServerTime = null;
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
    if (_startTime != null && _simulatedServerTime != null) {
      // Use the simulated server time (immune to local time changes)
      setState(() {
        _workingDuration = _simulatedServerTime!.difference(_startTime!);
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
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
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
          Icon(icon, size: 16, color: color.withOpacity(0.7)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isLive ? color : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
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
      height: 30,
      color: AppColors.border,
    );
  }
}

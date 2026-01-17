import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/attendance_state.dart';
import '../widgets/security_pill.dart';
import '../widgets/live_clock.dart';
import '../widgets/status_badge.dart';
import '../widgets/attendance_type_selector.dart';
import '../widgets/attendance_button.dart';
import '../widgets/attendance_footer.dart';

/// Main Attendance Screen
/// Layout: Header > Time > Status > Selector > Button > Footer
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // ============ HARDCODED STATE (for frontend-first development) ============

  // Security status (mocked)
  bool _isLocationValid = true;
  bool _isNetworkValid = true;

  // Attendance state
  AttendanceStatus _currentStatus = AttendanceStatus.idle;
  AttendanceAction _selectedAction = AttendanceAction.checkIn;

  // Times (mocked)
  String? _checkInTime;
  String? _checkOutTime;

  // ============ SMART DEFAULT LOGIC ============

  AttendanceAction _getSmartDefault() {
    switch (_currentStatus) {
      case AttendanceStatus.idle:
        return AttendanceAction.checkIn;
      case AttendanceStatus.working:
        return AttendanceAction.checkOut;
      case AttendanceStatus.onBreak:
        return AttendanceAction.resume;
      case AttendanceStatus.shiftEnded:
        return AttendanceAction.checkIn; // Shouldn't happen
    }
  }

  bool get _isSecurityValid => _isLocationValid && _isNetworkValid;

  // ============ ACTIONS ============

  void _onRefresh() {
    // Mocked refresh - toggle security for demo
    setState(() {
      // In real app, this would check GPS and WiFi
      _isLocationValid = true;
      _isNetworkValid = true;
    });
  }

  void _onActionSelected(AttendanceAction action) {
    setState(() {
      _selectedAction = action;
    });
  }

  void _onAttendanceComplete() {
    // Handle the attendance action
    setState(() {
      switch (_selectedAction) {
        case AttendanceAction.checkIn:
          _currentStatus = AttendanceStatus.working;
          _checkInTime = _getCurrentTime();
          _selectedAction = _getSmartDefault();
          break;
        case AttendanceAction.breakOut:
          _currentStatus = AttendanceStatus.onBreak;
          _selectedAction = _getSmartDefault();
          break;
        case AttendanceAction.resume:
          _currentStatus = AttendanceStatus.working;
          _selectedAction = _getSmartDefault();
          break;
        case AttendanceAction.checkOut:
          _currentStatus = AttendanceStatus.shiftEnded;
          _checkOutTime = _getCurrentTime();
          break;
      }
    });

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedAction.label} successful!'),
        backgroundColor: AppColors.checkIn,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // ============ BUILD ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ========== A. HEADER SECTION ==========
            _buildHeader(),

            // No spacing - clock directly under header

            // ========== B. TIME SECTION ==========
            const LiveClock(),

            const SizedBox(height: 24),

            // ========== C. STATUS SECTION ==========
            StatusBadge(
              status: _currentStatus,
              sinceTime: _checkInTime,
            ),

            const Spacer(),

            // ========== D. SELECTION SECTION ==========
            if (_currentStatus != AttendanceStatus.shiftEnded)
              AttendanceTypeSelector(
                selectedAction: _selectedAction,
                currentStatus: _currentStatus,
                onActionSelected: _onActionSelected,
                isEnabled: _isSecurityValid,
              ),

            const SizedBox(height: 32),

            // ========== E. ACTION SECTION ==========
            Center(
              child: AttendanceButton(
                action: _selectedAction,
                isEnabled: _isSecurityValid &&
                    _currentStatus != AttendanceStatus.shiftEnded,
                onComplete: _onAttendanceComplete,
              ),
            ),

            const Spacer(),

            // ========== F. FOOTER SECTION ==========
            AttendanceFooter(
              checkInTime: _checkInTime,
              checkOutTime: _checkOutTime,
              status: _currentStatus,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Title
          Text(
            'Attendance',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 16),

          // Security Cluster
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Location Pill
              SecurityPill.location(
                locationName: 'Surabaya',
                isValid: _isLocationValid,
              ),

              const SizedBox(width: 8),

              // Network Pill
              SecurityPill.network(
                networkName: 'Office WiFi',
                isValid: _isNetworkValid,
              ),

              const SizedBox(width: 8),

              // Refresh Button
              IconButton(
                onPressed: _onRefresh,
                icon: Icon(
                  Icons.refresh,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

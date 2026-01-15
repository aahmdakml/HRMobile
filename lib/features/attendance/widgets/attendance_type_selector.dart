import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/attendance_state.dart';

/// A smart collapsible selector for attendance actions
/// Collapsed: shows only ONE option (the smart default)
/// Expanded: shows all options [In] [Break] [Resume] [Out]
class AttendanceTypeSelector extends StatefulWidget {
  final AttendanceAction selectedAction;
  final AttendanceStatus currentStatus;
  final ValueChanged<AttendanceAction> onActionSelected;
  final bool isEnabled;

  const AttendanceTypeSelector({
    super.key,
    required this.selectedAction,
    required this.currentStatus,
    required this.onActionSelected,
    this.isEnabled = true,
  });

  @override
  State<AttendanceTypeSelector> createState() => _AttendanceTypeSelectorState();
}

class _AttendanceTypeSelectorState extends State<AttendanceTypeSelector> {
  bool _isExpanded = false;

  /// Get available actions based on current status
  List<AttendanceAction> get _availableActions {
    switch (widget.currentStatus) {
      case AttendanceStatus.idle:
        return [AttendanceAction.checkIn];
      case AttendanceStatus.working:
        return [AttendanceAction.breakOut, AttendanceAction.checkOut];
      case AttendanceStatus.onBreak:
        return [AttendanceAction.resume, AttendanceAction.checkOut];
      case AttendanceStatus.shiftEnded:
        return []; // No actions available
    }
  }

  Color _getColorForAction(AttendanceAction action) {
    switch (action) {
      case AttendanceAction.checkIn:
        return AppColors.checkIn;
      case AttendanceAction.breakOut:
        return AppColors.breakOut;
      case AttendanceAction.resume:
        return AppColors.resume;
      case AttendanceAction.checkOut:
        return AppColors.checkOut;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_availableActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.isEnabled && _availableActions.length > 1
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isExpanded ? _buildExpandedContent() : _buildCollapsedContent(),
      ),
    );
  }

  Widget _buildCollapsedContent() {
    final action = widget.selectedAction;
    final color = _getColorForAction(action);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionChip(action, color, isSelected: true),
        if (_availableActions.length > 1) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: AppColors.textMuted,
          ),
        ],
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _availableActions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _buildActionChip(
            _availableActions[i],
            _getColorForAction(_availableActions[i]),
            isSelected: _availableActions[i] == widget.selectedAction,
          ),
        ],
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = false),
          child: Icon(
            Icons.keyboard_arrow_up,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip(
    AttendanceAction action,
    Color color, {
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: widget.isEnabled
          ? () {
              widget.onActionSelected(action);
              setState(() => _isExpanded = false);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          action.shortLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

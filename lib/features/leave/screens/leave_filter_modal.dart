import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/features/leave/models/leave_model.dart';
import 'package:mobile_app/features/leave/providers/leave_provider.dart';
import 'package:mobile_app/features/leave/services/leave_service.dart';
import 'package:mobile_app/features/leave/widgets/searchable_type_sheet.dart';

class LeaveFilterModal extends ConsumerStatefulWidget {
  const LeaveFilterModal({super.key});

  @override
  ConsumerState<LeaveFilterModal> createState() => _LeaveFilterModalState();
}

class _LeaveFilterModalState extends ConsumerState<LeaveFilterModal> {
  // Local state for the filter form
  String? _status;
  String? _typeCode;
  DateTime? _startDate;
  DateTime? _endDate;

  // For leave types dropdown
  List<TimeoffCompany> _timeoffTypes = [];
  bool _loadingTypes = true;

  @override
  void initState() {
    super.initState();
    // Initialize local state from provider
    final currentFilters = ref.read(leaveFilterProvider);
    _status = currentFilters.status;
    _typeCode = currentFilters.typeCode;
    _startDate = currentFilters.startDate;
    _endDate = currentFilters.endDate;

    _fetchLeaveTypes();
  }

  Future<void> _fetchLeaveTypes() async {
    try {
      // In a real app we might get the user's company ID from auth provider
      // For now, assuming standard or fetched from context/profile
      // Just fetching blindly for now or pass a known company ID if needed
      // Actually leave service might need companyId.
      // Checking LeaveFormScreen logic, it fetches using 'SU' or user profile.
      // Let's assume we can fetch without ID or default 'SU' if service allows
      // OR better, we just rely on what LeaveForm uses.
      // LeaveService.getTimeoffTypes takes companyId.
      // We'll leave it as TODO or hardcode 'SU' for now as seen in logs
      final types =
          await LeaveService.getTimeoffTypes('SU'); // TODO: dynamic company ID
      setState(() {
        _timeoffTypes = types;
        _loadingTypes = false;
      });
    } catch (e) {
      setState(() => _loadingTypes = false);
      debugPrint('Error fetching types: $e');
    }
  }

  void _applyFilters() {
    final notifier = ref.read(leaveFilterProvider.notifier);
    notifier.setStatus(_status);
    notifier.setType(_typeCode);
    notifier.setDateRange(_startDate, _endDate);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _status = null;
      _typeCode = null;
      _startDate = null;
      _endDate = null;
    });
    ref.read(leaveFilterProvider.notifier).reset();
    // Don't close, just reset UI, user can then Apply or close
    // Actually standard UX is reset then optionally close or just stay
    // Let's just reset local state and provider state.
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Leaves',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Status Filter
          const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildStatusChip('Approved', 'APPROVED'),
              _buildStatusChip('Rejected', 'REJECTED'),
              _buildStatusChip('Waiting', 'WAITING_APPROVAL'),
              _buildStatusChip('Canceled', 'CANCELED'),
            ],
          ),
          const SizedBox(height: 16),

          // Date Range Filter
          const Text('Date Range',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDateRange,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _startDate == null
                        ? 'Select Date Range'
                        : '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                    style: TextStyle(
                      color: _startDate == null ? Colors.grey : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Leave Type Filter
          const Text('Leave Type',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_loadingTypes)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          InkWell(
            onTap: () async {
              final selected = await showModalBottomSheet<TimeoffCompany>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => SearchableTypeSheet(
                  options: _timeoffTypes,
                  selectedCode: _typeCode,
                ),
              );

              if (selected != null) {
                setState(() => _typeCode = selected.code);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _typeCode == null
                          ? 'All Types'
                          : _timeoffTypes
                                  .firstWhere((t) => t.code == _typeCode,
                                      orElse: () => TimeoffCompany(
                                          code: _typeCode!,
                                          needsApproval: false))
                                  .name ??
                              _typeCode!,
                      style: TextStyle(
                        color: _typeCode == null
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20), // Bottom padding
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _status == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _status = selected ? value : null;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      checkmarkColor: AppColors.primary,
    );
  }
}

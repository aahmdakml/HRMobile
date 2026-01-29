import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/features/permission/models/permission_model.dart';
import 'package:mobile_app/features/permission/providers/permission_provider.dart';
import 'package:mobile_app/features/permission/services/permission_service.dart';
import 'package:mobile_app/features/permission/widgets/permission_searchable_type_sheet.dart';

class PermissionFilterModal extends ConsumerStatefulWidget {
  const PermissionFilterModal({super.key});

  @override
  ConsumerState<PermissionFilterModal> createState() =>
      _PermissionFilterModalState();
}

class _PermissionFilterModalState extends ConsumerState<PermissionFilterModal> {
  // Local state for the filter form
  String? _status;
  String? _typeCode;
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedTypeName = '';

  List<TimeOffType> _permissionTypes = [];
  bool _loadingTypes = true;

  @override
  void initState() {
    super.initState();
    // Initialize local state from provider
    final currentFilters = ref.read(permissionFilterProvider);
    _status = currentFilters.status;
    _typeCode = currentFilters.typeCode;
    _startDate = currentFilters.startDate;
    _endDate = currentFilters.endDate;

    _fetchPermissionTypes();
  }

  Future<void> _fetchPermissionTypes() async {
    try {
      final types =
          await PermissionService.getPermissionTypes('SU'); // TODO: dynamic

      if (mounted) {
        setState(() {
          _permissionTypes = types;
          _loadingTypes = false;

          if (_typeCode != null) {
            final selected = types.firstWhere(
              (t) => t.code == _typeCode,
              orElse: () => TimeOffType(code: '', name: ''),
            );
            if (selected.code.isNotEmpty) _selectedTypeName = selected.name;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingTypes = false);
      debugPrint('Error fetching permission types: $e');
    }
  }

  void _applyFilters() {
    final notifier = ref.read(permissionFilterProvider.notifier);
    notifier.setAll(
      status: _status,
      typeCode: _typeCode,
      startDate: _startDate,
      endDate: _endDate,
    );
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _status = null;
      _typeCode = null;
      _startDate = null;
      _endDate = null;
      _selectedTypeName = '';
    });
    ref.read(permissionFilterProvider.notifier).reset();
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E2D),
                ),
              ),
              if (_status != null || _typeCode != null || _startDate != null)
                TextButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Date Range
          const Text(
            'Date Range',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDateRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 20, color: Colors.grey.shade500),
                  const SizedBox(width: 12),
                  Text(
                    _startDate != null && _endDate != null
                        ? '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM').format(_endDate!)}'
                        : 'Select Date Range',
                    style: TextStyle(
                      color: _startDate != null
                          ? Colors.black87
                          : Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Status Field
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['WAITING_APPROVAL', 'APPROVED', 'REJECTED', 'CANCELED']
                  .map((status) {
                final isSelected = _status == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        // Toggle: if already selected and tapped again, deselect (set to null)
                        // Wait, FilterChip behavior? Usually boolean.
                        // Logic: if current _status is this, set to null. Else set to this.
                        if (_status == status) {
                          _status = null;
                        } else {
                          _status = status;
                        }
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary,
                    checkmarkColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Type Field
          const Text(
            'Permission Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _loadingTypes
                ? null
                : () async {
                    final result = await showModalBottomSheet<TimeOffType>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PermissionSearchableTypeSheet(
                        options: _permissionTypes,
                        selectedCode: _typeCode,
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _typeCode = result.code;
                        _selectedTypeName = result.name;
                      });
                    }
                  },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.category_outlined,
                      size: 20, color: Colors.grey.shade500),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _typeCode != null && _selectedTypeName.isNotEmpty
                          ? _selectedTypeName
                          : 'Select Type',
                      style: TextStyle(
                        color: _typeCode != null
                            ? Colors.black87
                            : Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_loadingTypes)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

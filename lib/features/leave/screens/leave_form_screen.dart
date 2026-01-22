import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/features/leave/models/leave_model.dart';
import 'package:mobile_app/features/leave/providers/leave_provider.dart';
import 'package:mobile_app/features/leave/services/leave_service.dart';
import 'package:mobile_app/core/services/auth_state.dart';
import 'package:intl/intl.dart';

class LeaveFormScreen extends ConsumerStatefulWidget {
  const LeaveFormScreen({super.key});

  @override
  ConsumerState<LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends ConsumerState<LeaveFormScreen> {
  int _currentStep = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Form Data
  TimeoffCompany? _selectedTimeoff;
  DateTimeRange? _dateRange;
  final List<DateTime> _selectedDates = [];
  final TextEditingController _descController = TextEditingController();

  // Data Source
  List<TimeoffCompany> _timeoffTypes = [];
  List<EmployeeSpvApproval> _approvalFlow = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final user = ref.read(authStateProvider).user;
      final companyId = user?.employee?.companyId ?? '';
      final empId = user?.employee?.empId ?? '';

      if (companyId.isEmpty) {
        throw Exception('Company ID not found');
      }

      final results = await Future.wait([
        LeaveService.getTimeoffTypes(companyId),
        LeaveService.getApprovalFlow(empId),
      ]);

      if (mounted) {
        setState(() {
          _timeoffTypes = results[0] as List<TimeoffCompany>;
          _approvalFlow = results[1] as List<EmployeeSpvApproval>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load data: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _calculateDates() {
    if (_dateRange == null) return;

    _selectedDates.clear();
    DateTime current = _dateRange!.start;
    while (current.isBefore(_dateRange!.end) ||
        current.isAtSameMomentAs(_dateRange!.end)) {
      _selectedDates.add(current);
      current = current.add(const Duration(days: 1));
    }
    setState(() {});
  }

  void _removeDate(DateTime date) {
    setState(() {
      _selectedDates.removeWhere((d) =>
          d.day == date.day && d.month == date.month && d.year == date.year);
    });
  }

  Future<void> _pickDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primary,
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _dateRange = result;
      });
      _calculateDates();
    }
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (_selectedTimeoff == null) {
        _showError('Please select a leave type');
        return false;
      }
      if (_selectedDates.isEmpty) {
        _showError('Please select dates');
        return false;
      }
      if (_selectedTimeoff!.maxDays != null &&
          _selectedDates.length > _selectedTimeoff!.maxDays!) {
        _showError(
            'Exceeds maximum days allowed (${_selectedTimeoff!.maxDays})');
        return false;
      }
    } else if (step == 1) {
      if (_descController.text.trim().isEmpty) {
        _showError('Please enter a description');
        return false;
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await LeaveService.createLeave(
        timeoffCode: _selectedTimeoff!.code,
        startDate: _selectedDates.first, // Ideally min date
        endDate: _selectedDates.last, // Ideally max date
        description: _descController.text,
        dates: _selectedDates
            .map((d) => d.toIso8601String().split('T')[0])
            .toList(),
      );

      if (mounted) {
        ref.read(leaveListProvider.notifier).refresh();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Leave request submitted successfully'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to submit: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Leave Request',
            style:
                TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              elevation: 0,
              onStepContinue: () {
                if (_validateStep(_currentStep)) {
                  if (_currentStep < 2) {
                    setState(() => _currentStep += 1);
                  } else {
                    _submit();
                  }
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text(_currentStep == 2 ? 'Submit' : 'Continue',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Back',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black87)),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Dates'),
                  content: _buildStep1(),
                  isActive: _currentStep >= 0,
                  state:
                      _currentStep > 0 ? StepState.complete : StepState.editing,
                ),
                Step(
                  title: const Text('Details'),
                  content: _buildStep2(),
                  isActive: _currentStep >= 1,
                  state:
                      _currentStep > 1 ? StepState.complete : StepState.editing,
                ),
                Step(
                  title: const Text('Review'),
                  content: _buildStep3(),
                  isActive: _currentStep >= 2,
                ),
              ],
            ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leave Type
        const Text('Leave Type',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        DropdownButtonFormField<TimeoffCompany>(
          value: _selectedTimeoff,
          decoration: _inputDecoration('Select Leave Type'),
          items: _timeoffTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type.name ?? type.code),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedTimeoff = val),
        ),

        const SizedBox(height: 20),

        // Date Range
        const Text('Select Dates',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDateRange,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  _dateRange == null
                      ? 'Select start & end date'
                      : '${DateFormat('dd MMM').format(_dateRange!.start)} - ${DateFormat('dd MMM').format(_dateRange!.end)}',
                  style: TextStyle(
                    color: _dateRange == null
                        ? Colors.grey.shade600
                        : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_selectedDates.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Selected Days',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(
                '${_selectedDates.length} Days',
                style: TextStyle(
                  color: (_selectedTimeoff?.maxDays != null &&
                          _selectedDates.length > _selectedTimeoff!.maxDays!)
                      ? Colors.red
                      : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedDates.map((date) {
              return Chip(
                label: Text(DateFormat('dd MMM').format(date)),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeDate(date),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                labelStyle:
                    const TextStyle(color: AppColors.primary, fontSize: 12),
              );
            }).toList(),
          ),
          if (_selectedTimeoff?.maxDays != null &&
              _selectedDates.length > _selectedTimeoff!.maxDays!)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  'Exceeds maximum allowed days (${_selectedTimeoff!.maxDays})',
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Description',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descController,
          maxLines: 4,
          decoration: _inputDecoration('Enter reason for leave...'),
        ),
        const SizedBox(height: 20),
        const Text('Attachment (Optional)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle
                    .solid), // Dashed border not native, solid for now
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: Column(
            children: [
              Icon(Icons.cloud_upload_outlined,
                  size: 32, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text('Tap to upload file',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 4),
              const Text('(Attachment feature unavailable)',
                  style: TextStyle(color: Colors.red, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Type', _selectedTimeoff?.name ?? '-'),
              const Divider(height: 24),
              _buildSummaryRow(
                  'Dates',
                  _selectedDates.isEmpty
                      ? '-'
                      : '${_selectedDates.length} Days'),
              const Divider(height: 24),
              _buildSummaryRow('Reason', _descController.text),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Approval Flow',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        if (_selectedTimeoff?.needsApproval == false)
          Center(
            child: Column(
              children: [
                Icon(Icons.check_circle_outline,
                    size: 48, color: Colors.green.shade300),
                const SizedBox(height: 8),
                const Text('No Approval Needed',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        else if (_approvalFlow.isEmpty)
          const Center(
              child: Text('No approval flow found',
                  style: TextStyle(color: Colors.grey)))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _approvalFlow.length,
            itemBuilder: (context, index) {
              final approver = _approvalFlow[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                          child: Text('${index + 1}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(approver.approverName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text(approver.approverTitle ?? 'Approver',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14))),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}

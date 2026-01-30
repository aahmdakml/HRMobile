import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/features/leave/models/leave_model.dart';
import 'package:mobile_app/features/leave/providers/leave_provider.dart';
import 'package:mobile_app/features/leave/services/leave_service.dart';
import 'package:mobile_app/core/services/auth_state.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/leave/widgets/searchable_type_sheet.dart';
import 'package:mobile_app/features/leave/widgets/leave_skeleton_widgets.dart';
import 'package:mobile_app/features/leave/widgets/attachment_thumbnail.dart';

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
  final List<File> _selectedFiles = []; // Multiple files

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
      print('empId: $empId');
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
    // If maxDays is 1, pick a single date
    if (_selectedTimeoff?.maxDays == 1) {
      final date = await showDatePicker(
        context: context,
        initialDate: _dateRange?.start ?? DateTime.now(),
        firstDate: DateTime.now(), // Prevent backdate
        lastDate: DateTime(2030),
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

      if (date != null) {
        setState(() {
          _dateRange = DateTimeRange(start: date, end: date);
        });
        _calculateDates();
      }
    } else {
      // Otherwise allow range selection
      final result = await showDateRangePicker(
        context: context,
        firstDate: DateTime.now(), // Prevent backdate
        lastDate: DateTime(2030),
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
            'Maximum allowed duration for this leave type is ${_selectedTimeoff!.maxDays} days.');
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

  // File picker constants
  static const List<String> _allowedExtensions = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'doc',
    'docx'
  ];
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

  Future<void> _pickFile() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Upload Attachment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildUploadOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        final picker = ImagePicker();
                        final XFile? photo = await picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 1024,
                          imageQuality: 80,
                        );

                        if (photo != null) {
                          setState(() {
                            _selectedFiles.add(File(photo.path));
                          });
                        }
                      } catch (e) {
                        _showError('Camera error: $e');
                      }
                    },
                  ),
                  _buildUploadOption(
                    icon: Icons.folder,
                    label: 'File / Gallery',
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: _allowedExtensions,
                          allowMultiple: true,
                        );

                        if (result != null) {
                          final validFiles = result.files.where((file) {
                            if (file.size > _maxFileSizeBytes) {
                              if (mounted) {
                                _showError(
                                    'File ${file.name} exceeds 5MB limit');
                              }
                              return false;
                            }
                            return file.path != null;
                          }).toList();

                          setState(() {
                            _selectedFiles.addAll(
                                validFiles.map((f) => File(f.path!)).toList());
                          });
                        }
                      } catch (e) {
                        _showError('File picker error: $e');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showError(String message) {
    _showAlert(title: 'Error', message: message, isError: true);
  }

  void _showAlert({
    required String title,
    required String message,
    bool isError = false,
    VoidCallback? onOk,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError ? Colors.red : AppColors.primary,
            ),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              onOk?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      debugPrint('LEAVE_SUBMIT: Starting submission...');
      debugPrint('LEAVE_SUBMIT: timeoffCode=${_selectedTimeoff!.code}');
      debugPrint('LEAVE_SUBMIT: dates=${_selectedDates.length}');
      debugPrint('LEAVE_SUBMIT: attachments=${_selectedFiles.length}');

      await LeaveService.createLeave(
        timeoffCode: _selectedTimeoff!.code,
        startDate: _selectedDates.first,
        endDate: _selectedDates.last,
        description: _descController.text,
        dates: _selectedDates
            .map((d) => d.toIso8601String().split('T')[0])
            .toList(),
        attachmentPaths: _selectedFiles.map((f) => f.path).toList(),
      );

      debugPrint('LEAVE_SUBMIT: Success!');

      if (mounted) {
        ref.read(leaveListProvider.notifier).refresh();
        _showAlert(
          title: 'Success',
          message: 'Leave request submitted successfully',
          onOk: () => Navigator.pop(context),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('LEAVE_SUBMIT: Error: $e');
      debugPrint('LEAVE_SUBMIT: StackTrace: $stackTrace');
      if (mounted) {
        String errorMessage = e.toString();
        // Check for Dio 422 Error (Balance Limit)
        if (errorMessage.contains('422')) {
          errorMessage =
              'Pengajuan cuti Anda melebihi ketersediaan sisa cuti tahunan.';
        }
        _showError(errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _showAlert(
            title: 'Please Wait',
            message: 'Please wait until submission completes',
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2D),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Custom Header
              _buildHeader(context),

              // Main Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: _isLoading
                      ? const SkeletonLeaveForm()
                      : ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                          child: Stepper(
                            type: StepperType.horizontal,
                            currentStep: _currentStep,
                            elevation: 0,
                            margin: EdgeInsets.zero,
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
                              return Container(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 24, 20, 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Back Button (LEFT)
                                    // Back Button (ALWAYS VISIBLE)
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          if (_isSubmitting) {
                                            _showAlert(
                                              title: 'Please Wait',
                                              message:
                                                  'Please wait until submission completes',
                                            );
                                            return;
                                          }
                                          if (_currentStep > 0) {
                                            details.onStepCancel?.call();
                                          } else {
                                            Navigator.pop(context);
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          side: BorderSide(
                                              color: Colors.grey.shade300),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                            _currentStep == 0
                                                ? 'Cancel'
                                                : 'Back',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Continue/Submit Button (RIGHT)
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : details.onStepContinue,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          disabledBackgroundColor: AppColors
                                              .primary
                                              .withOpacity(0.5),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: _isSubmitting
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2))
                                            : Text(
                                                _currentStep == 2
                                                    ? 'Submit'
                                                    : 'Continue',
                                                style: const TextStyle(
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
                            },
                            steps: [
                              Step(
                                title: const Text('Dates'),
                                content: _buildStep1(),
                                isActive: _currentStep >= 0,
                                state: _currentStep > 0
                                    ? StepState.complete
                                    : StepState.editing,
                              ),
                              Step(
                                title: const Text('Details'),
                                content: _buildStep2(),
                                isActive: _currentStep >= 1,
                                state: _currentStep > 1
                                    ? StepState.complete
                                    : StepState.editing,
                              ),
                              Step(
                                title: const Text('Review'),
                                content: _buildStep3(),
                                isActive: _currentStep >= 2,
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          const SizedBox(
              width: 4), // Small spacing if needed or remove entirely
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Leave Request',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Submit your time off request',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Leave Type
          const Text(
            'Leave Type',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: InkWell(
              onTap: () async {
                final selected = await showModalBottomSheet<TimeoffCompany>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => SearchableTypeSheet(
                    options: _timeoffTypes,
                    selectedCode: _selectedTimeoff?.code,
                  ),
                );

                if (selected != null) {
                  setState(() => _selectedTimeoff = selected);
                  debugPrint('Selected Timeoff: ${selected.name}');
                  debugPrint(
                      'MaxDays: ${selected.maxDays} (Raw: ${selected.maxDays})');
                  debugPrint('DeductAnnual: ${selected.isDeductAnnual}');
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _selectedTimeoff?.name ??
                            _selectedTimeoff?.code ??
                            'Select Leave Type',
                        style: TextStyle(
                          fontSize: 15,
                          color: _selectedTimeoff == null
                              ? Colors.grey
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Leave Type Info Card
          if (_selectedTimeoff != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedTimeoff!.maxDays != null
                                ? 'Batas maksimal pengambilan cuti ini adalah ${_selectedTimeoff!.maxDays} hari.'
                                : 'Tidak ada batas maksimal cuti',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _selectedTimeoff!.isDeductAnnual
                            ? Icons.remove_circle_outline
                            : Icons.check_circle_outline,
                        size: 18,
                        color: _selectedTimeoff!.isDeductAnnual
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedTimeoff!.isDeductAnnual
                              ? 'Pengajuan ini akan memotong jatah cuti tahunan Anda.'
                              : 'Pengajuan ini tidak akan memotong jatah cuti tahunan Anda.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Date Range
          const Text(
            'Select Dates',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickDateRange,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.date_range,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _dateRange == null
                          ? 'Select start & end date'
                          : '${DateFormat('dd MMM yyyy').format(_dateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_dateRange!.end)}',
                      style: TextStyle(
                        color: _dateRange == null
                            ? Colors.grey.shade600
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),

          if (_selectedDates.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selected Days',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_selectedTimeoff?.maxDays != null &&
                            _selectedDates.length > _selectedTimeoff!.maxDays!)
                        ? Colors.red.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedDates.length} Days',
                    style: TextStyle(
                      color: (_selectedTimeoff?.maxDays != null &&
                              _selectedDates.length >
                                  _selectedTimeoff!.maxDays!)
                          ? Colors.red
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedDates.map((date) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('dd MMM').format(date),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeDate(date),
                        child: Icon(Icons.close,
                            size: 16,
                            color: AppColors.primary.withOpacity(0.7)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (_selectedTimeoff?.maxDays != null &&
                _selectedDates.length > _selectedTimeoff!.maxDays!)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Exceeds maximum allowed days (${_selectedTimeoff!.maxDays})',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextFormField(
              controller: _descController,
              maxLines: 5,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.5,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter reason for your leave request...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Attachment (Optional)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedFiles.isNotEmpty
                      ? AppColors.primary.withOpacity(0.5)
                      : Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                color: _selectedFiles.isNotEmpty
                    ? AppColors.primary.withOpacity(0.05)
                    : Colors.grey.shade50,
              ),
              child: _selectedFiles.isNotEmpty
                  ? Column(
                      children: _selectedFiles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: AttachmentThumbnail(
                                  fileName: file.path.split('/').last,
                                  filePath: file.path,
                                  isReadOnly: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedFiles.removeAt(index);
                                  });
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.delete_outline,
                                      size: 20, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.cloud_upload_outlined,
                              size: 28, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tap to upload file',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PDF, JPG, PNG, DOC (max 5MB)',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.08),
                  AppColors.primary.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  'Type',
                  _selectedTimeoff?.name ?? '-',
                  Icons.category_outlined,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Colors.grey.shade300),
                ),
                _buildSummaryRow(
                  'Dates',
                  _selectedDates.isEmpty
                      ? '-'
                      : '${_selectedDates.length} Days\n${_selectedDates.map((d) => DateFormat('dd MMM').format(d)).join(', ')}',
                  Icons.calendar_today_outlined,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Colors.grey.shade300),
                ),
                _buildSummaryRow(
                  'Reason',
                  _descController.text.trim().isEmpty
                      ? '-'
                      : _descController.text,
                  Icons.description_outlined,
                ),
                if (_selectedFiles.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: Colors.grey.shade300),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.attach_file,
                          size: 20, color: AppColors.primary.withOpacity(0.7)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attachments',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: _selectedFiles.map((file) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: AttachmentThumbnail(
                                    fileName: file.path.split('/').last,
                                    filePath: file.path,
                                    isReadOnly: true,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fact_check_outlined,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Approval Flow',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedTimeoff?.needsApproval == false)
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_outline,
                          size: 48, color: Colors.green.shade400),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No Approval Needed',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_approvalFlow.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.info_outline,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No approval flow found',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _approvalFlow.length,
              itemBuilder: (context, index) {
                final approver = _approvalFlow[index];
                final isLast = index == _approvalFlow.length - 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                approver.approverName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                approver.approverTitle ?? 'Approver',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isLast)
                          Icon(Icons.arrow_downward,
                              size: 18, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary.withOpacity(0.7)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/services/auth_state.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/features/leave/models/leave_model.dart'
    show EmployeeSpvApproval;
import 'package:mobile_app/features/leave/widgets/attachment_thumbnail.dart';
import 'package:mobile_app/features/permission/models/permission_model.dart';
import 'package:mobile_app/features/permission/providers/permission_provider.dart';
import 'package:mobile_app/features/permission/services/permission_service.dart';
import 'package:mobile_app/features/permission/widgets/permission_searchable_type_sheet.dart';

class PermissionFormScreen extends ConsumerStatefulWidget {
  const PermissionFormScreen({super.key});

  @override
  ConsumerState<PermissionFormScreen> createState() =>
      _PermissionFormScreenState();
}

class _PermissionFormScreenState extends ConsumerState<PermissionFormScreen> {
  int _currentStep = 0;
  final _descriptionController = TextEditingController();

  TimeOffType? _selectedType;
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final List<File> _selectedFiles = [];
  bool _isSubmitting = false;
  List<TimeOffType> _types = [];
  List<EmployeeSpvApproval> _approvalFlow = [];

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

  bool get _shouldShowStartTime {
    return _selectedType?.setting?.needStartTime ?? false;
  }

  bool get _shouldShowEndTime {
    return _selectedType?.setting?.needEndTime ?? false;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final user = ref.read(authStateProvider).user;
      final empId = user?.employee?.empId ?? '';

      final results = await Future.wait([
        PermissionService.getPermissionTypes('SU'),
        PermissionService.getApprovalFlow(empId),
      ]);

      if (mounted) {
        setState(() {
          _types = results[0] as List<TimeOffType>;
          _approvalFlow = results[1] as List<EmployeeSpvApproval>;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error fetching data: $e');
      }
    }
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (_selectedType == null) {
        _showError('Please select permission type');
        return false;
      }
      if (_selectedDate == null) {
        _showError('Please select date');
        return false;
      }
      if (_shouldShowStartTime && _startTime == null) {
        _showError('Please select start time');
        return false;
      }
      if (_shouldShowEndTime && _endTime == null) {
        _showError('Please select end time');
        return false;
      }
      if (_startTime != null && _endTime != null) {
        final start = _startTime!.hour * 60 + _startTime!.minute;
        final end = _endTime!.hour * 60 + _endTime!.minute;
        if (end <= start) {
          _showError('End time must be after start time');
          return false;
        }
      }
    } else if (step == 1) {
      if (_descriptionController.text.trim().isEmpty) {
        _showError('Please enter description');
        return false;
      }
    }
    return true;
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

  void _showError(String message) {
    _showAlert(title: 'Error', message: message, isError: true);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      // Calculate total hours
      double totalHour = 0;
      if (_startTime != null && _endTime != null) {
        final start = _startTime!.hour + _startTime!.minute / 60.0;
        final end = _endTime!.hour + _endTime!.minute / 60.0;
        totalHour = end - start;
      } else {
        totalHour = 1.0;
      }

      await PermissionService.createPermission(
        timeoffCode: _selectedType!.code,
        date: _selectedDate!,
        description: _descriptionController.text,
        timeStart: _startTime != null
            ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00'
            : null,
        timeEnd: _endTime != null
            ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00'
            : null,
        totalHour: totalHour,
        attachmentPaths: _selectedFiles.map((f) => f.path).toList(),
      );

      if (mounted) {
        ref.read(recentPermissionsProvider.notifier).refresh();
        ref.read(permissionListProvider.notifier).refresh();

        setState(
            () => _isSubmitting = false); // Allow popping before showing alert

        if (mounted) Navigator.pop(context); // Close screen first

        if (mounted) {
          _showAlert(
            title: 'Success',
            message: 'Permission request submitted successfully',
            // No onOk needed as we already popped
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false); // Ensure it's reset on error too
        _showError('Failed: $e');
      }
    } finally {
      // already handled
    }
  }

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
        backgroundColor:
            const Color(0xFF1E1E2D), // Dark background like Leave Form
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Custom Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Request Permission',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Submit your permission request',
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
              ),

              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: ClipRRect(
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
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      controlsBuilder: (context, details) {
                        return Container(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                                    side:
                                        BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    _currentStep == 0 ? 'Cancel' : 'Back',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : details.onStepContinue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2))
                                      : Text(
                                          _currentStep == 2
                                              ? 'Submit'
                                              : 'Continue',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      steps: [
                        Step(
                          title: const Text('Data'),
                          content: _buildStep1(),
                          isActive: _currentStep >= 0,
                          state: _currentStep > 0
                              ? StepState.complete
                              : StepState.editing,
                        ),
                        Step(
                          title: const Text('Detail'),
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

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Permission Type', required: true),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await showModalBottomSheet<TimeOffType>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => PermissionSearchableTypeSheet(
                options: _types,
                selectedCode: _selectedType?.code,
              ),
            );
            if (result != null) {
              setState(() {
                if (_selectedType != result) {
                  _startTime = null;
                  _endTime = null;
                }
                _selectedType = result;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.category_outlined,
                    color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedType?.name ?? 'Select Type',
                    style: TextStyle(
                      color: _selectedType != null
                          ? Colors.black87
                          : Colors.grey.shade500,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionLabel('Date', required: true),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.light().copyWith(
                    primaryColor: AppColors.primary,
                    colorScheme:
                        const ColorScheme.light(primary: AppColors.primary),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('dd MMMM yyyy').format(_selectedDate!)
                        : 'Select Date',
                    style: TextStyle(
                      color: _selectedDate != null
                          ? Colors.black87
                          : Colors.grey.shade500,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_shouldShowStartTime || _shouldShowEndTime) ...[
          Row(
            children: [
              if (_shouldShowStartTime)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('Start Time', required: true),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() => _startTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.schedule,
                                  color: Colors.grey.shade600, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _startTime != null
                                    ? _startTime!.format(context)
                                    : '--:--',
                                style: TextStyle(
                                  color: _startTime != null
                                      ? Colors.black87
                                      : Colors.grey.shade500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_shouldShowStartTime && _shouldShowEndTime)
                const SizedBox(width: 16),
              if (_shouldShowEndTime)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('End Time', required: true),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setState(() => _endTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.schedule,
                                  color: Colors.grey.shade600, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _endTime != null
                                    ? _endTime!.format(context)
                                    : '--:--',
                                style: TextStyle(
                                  color: _endTime != null
                                      ? Colors.black87
                                      : Colors.grey.shade500,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Description', required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter reason or description...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            fillColor: Colors.grey.shade50,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionLabel('Attachments'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
              ),
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
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 32, color: AppColors.primary.withOpacity(0.6)),
                      const SizedBox(height: 8),
                      Text(
                        'Click to upload files',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
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
                _selectedType?.name ?? '-',
                Icons.category_outlined,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Colors.grey.shade300),
              ),
              _buildSummaryRow(
                'Date',
                _selectedDate != null
                    ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                    : '-',
                Icons.calendar_today_outlined,
              ),
              if (_shouldShowStartTime) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Colors.grey.shade300),
                ),
                _buildSummaryRow(
                  'Start Time',
                  _startTime?.format(context) ?? '-',
                  Icons.schedule,
                ),
              ],
              if (_shouldShowEndTime) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: Colors.grey.shade300),
                ),
                _buildSummaryRow(
                  'End Time',
                  _endTime?.format(context) ?? '-',
                  Icons.schedule,
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: Colors.grey.shade300),
              ),
              _buildSummaryRow(
                'Reason',
                _descriptionController.text.trim().isEmpty
                    ? '-'
                    : _descriptionController.text,
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

        // Approval Flow Section
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

        if (_approvalFlow.isEmpty)
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
        const SizedBox(height: 24),
      ],
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

  Widget _buildSectionLabel(String label, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}

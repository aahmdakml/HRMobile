import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/core/services/profile_service.dart';

/// Bottom sheet form for adding/editing education
class EducationFormSheet extends StatefulWidget {
  final Education? education; // null for create, non-null for edit

  const EducationFormSheet({super.key, this.education});

  static Future<bool?> show(BuildContext context, {Education? education}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EducationFormSheet(education: education),
    );
  }

  @override
  State<EducationFormSheet> createState() => _EducationFormSheetState();
}

class _EducationFormSheetState extends State<EducationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _institutionController;
  late TextEditingController _majorController;
  late TextEditingController _startYearController;
  late TextEditingController _endYearController;
  late TextEditingController _gpaController;

  List<MasterOption> _levelOptions = [];
  List<Major> _majorOptions = [];

  String? _selectedMajorId;
  String _level = '';
  bool _isLoading = false;
  bool _isStillStudy = false;

  bool get isEdit => widget.education != null;

  @override
  void initState() {
    super.initState();
    _institutionController =
        TextEditingController(text: widget.education?.institution ?? '');
    _majorController =
        TextEditingController(text: widget.education?.major ?? '');
    _startYearController =
        TextEditingController(text: widget.education?.startYear ?? '');
    _endYearController =
        TextEditingController(text: widget.education?.endYear ?? '');
    _gpaController = TextEditingController(text: widget.education?.gpa ?? '');

    // infer isStillStudy if endYear is empty/null but startYear is set?
    // Or just default to false unless end year is explicitly empty on an edit.
    if (isEdit) {
      _isStillStudy = widget.education?.endYear == null ||
          widget.education!.endYear!.isEmpty;
    }

    // Load levels
    _loadLevels();

    if (widget.education != null) {
      _level = widget.education!.level;
      // We need to load majors for this level to show the dropdown correctly
      _loadMajors(_level);
    }
  }

  Future<void> _loadLevels() async {
    final res = await ProfileService.getMasterOptions('EDUCATION_OPTION');
    if (res.success && res.data != null) {
      if (mounted) {
        setState(() {
          _levelOptions = res.data!;
          // Set default if creating new
          if (_level.isEmpty && _levelOptions.isNotEmpty && !isEdit) {
            _level = _levelOptions.first.id;
            _loadMajors(_level);
          }
        });
      }
    }
  }

  Future<void> _loadMajors(String levelCode) async {
    final res = await ProfileService.getMajors(levelCode);
    if (res.success && res.data != null) {
      if (mounted) {
        setState(() {
          _majorOptions = res.data!;
          // Try to match existing major name to an ID if we have one
          if (widget.education?.major != null) {
            final match = _majorOptions
                .where((m) => m.name == widget.education!.major)
                .firstOrNull;
            if (match != null) {
              _selectedMajorId = match.id.toString();
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _institutionController.dispose();
    _majorController.dispose();
    _startYearController.dispose();
    _endYearController.dispose();
    _gpaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'edu_level': _level,
      'institution_id': 34, // Default "Other" if manual
      'institution_name': _institutionController.text.trim(),
      'major_id': _selectedMajorId,
      'major_name': _selectedMajorId == null
          ? _majorController.text.trim()
          : null, // Send name if manual (fallback)
      'edu_start': _startYearController.text.trim(),
      'edu_end': _isStillStudy ? null : _endYearController.text.trim(),
      'edu_gpa': _gpaController.text.trim().isEmpty
          ? null
          : double.tryParse(_gpaController.text.trim()),
    };

    final result = isEdit
        ? await ProfileService.updateEducation(widget.education!.id, data)
        : await ProfileService.createEducation(data);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Education updated' : 'Education added'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to save education'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Education' : 'Add Education',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Enter education details',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level
                    _buildLabel('Education Level'),
                    DropdownButtonFormField<String>(
                      value: _levelOptions.any((l) => l.id == _level)
                          ? _level
                          : null,
                      decoration: _inputDecoration(
                          'Select level', Icons.school_outlined),
                      items: _levelOptions.map((l) {
                        return DropdownMenuItem(
                            value: l.id, child: Text(l.name));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _level = v;
                            _selectedMajorId = null; // Reset major
                            _majorOptions = [];
                          });
                          _loadMajors(v);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Institution
                    _buildLabel('Institution Name'),
                    TextFormField(
                      controller: _institutionController,
                      decoration: _inputDecoration(
                          'Enter institution name', Icons.business),
                      validator: (v) =>
                          v?.trim().isEmpty == true ? 'Required' : null,
                    ),

                    const SizedBox(height: 16),

                    // Major
                    _buildLabel('Major / Field of Study'),
                    if (_majorOptions.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _selectedMajorId != null &&
                                _majorOptions.any(
                                    (m) => m.id.toString() == _selectedMajorId)
                            ? _selectedMajorId
                            : null,
                        decoration:
                            _inputDecoration('Select Major', Icons.book),
                        items: _majorOptions.map((m) {
                          return DropdownMenuItem(
                              value: m.id.toString(),
                              child: Text(
                                m.name.length > 30
                                    ? '${m.name.substring(0, 30)}...'
                                    : m.name,
                                overflow: TextOverflow.ellipsis,
                              ));
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedMajorId = v),
                        validator: (v) => v == null ? 'Required' : null,
                      )
                    else
                      TextFormField(
                        controller: _majorController,
                        decoration: _inputDecoration('Enter major', Icons.book),
                        validator: (v) =>
                            v?.trim().isEmpty == true ? 'Required' : null,
                      ),

                    const SizedBox(height: 16),

                    // Year range
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Start Year'),
                              TextFormField(
                                controller: _startYearController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                    'YYYY', Icons.calendar_today),
                                validator: (v) => v?.trim().isEmpty == true
                                    ? 'Required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('End Year'),
                              TextFormField(
                                controller: _endYearController,
                                enabled: !_isStillStudy,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                  'YYYY',
                                  Icons.calendar_today,
                                ).copyWith(
                                  fillColor: _isStillStudy
                                      ? Colors.grey[200]
                                      : Colors.grey[100],
                                ),
                                validator: (v) {
                                  if (_isStillStudy) return null;
                                  return v?.trim().isEmpty == true
                                      ? 'Required'
                                      : null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Still Studying Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _isStillStudy,
                          onChanged: (val) {
                            setState(() {
                              _isStillStudy = val ?? false;
                              if (_isStillStudy) {
                                _endYearController.clear();
                              }
                            });
                          },
                        ),
                        const Text('I am still studying here'),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // GPA
                    _buildLabel('GPA (Optional)'),
                    TextFormField(
                      controller: _gpaController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration('e.g. 3.50', Icons.grade),
                    ),

                    const SizedBox(height: 24),

                    // Save button
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isEdit ? 'Update' : 'Add Education',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textMuted),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary),
      ),
    );
  }
}

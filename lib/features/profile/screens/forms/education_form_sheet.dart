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

  String _level = 'S1';
  bool _isLoading = false;

  // Education level options
  final List<Map<String, String>> _levelOptions = [
    {'id': 'SD', 'name': 'SD (Elementary)'},
    {'id': 'SMP', 'name': 'SMP (Junior High)'},
    {'id': 'SMA', 'name': 'SMA/SMK (Senior High)'},
    {'id': 'D1', 'name': 'D1 (Diploma 1)'},
    {'id': 'D2', 'name': 'D2 (Diploma 2)'},
    {'id': 'D3', 'name': 'D3 (Diploma 3)'},
    {'id': 'D4', 'name': 'D4 (Diploma 4)'},
    {'id': 'S1', 'name': 'S1 (Bachelor)'},
    {'id': 'S2', 'name': 'S2 (Master)'},
    {'id': 'S3', 'name': 'S3 (Doctoral)'},
  ];

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

    if (widget.education != null) {
      _level = widget.education!.level;
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
      'institution_id': 1, // Default institution ID - ideally from dropdown
      'institution_name': _institutionController.text.trim(),
      'major_id': 1, // Default major ID - ideally from dropdown
      'major_name': _majorController.text.trim(),
      'edu_start': _startYearController.text.trim(),
      'edu_end': _endYearController.text.trim(),
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
                      value: _level,
                      decoration: _inputDecoration(
                          'Select level', Icons.school_outlined),
                      items: _levelOptions.map((l) {
                        return DropdownMenuItem(
                            value: l['id'], child: Text(l['name']!));
                      }).toList(),
                      onChanged: (v) => setState(() => _level = v ?? 'S1'),
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

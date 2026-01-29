import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/core/services/profile_service.dart';

/// Bottom sheet form for adding/editing a family member
class FamilyFormSheet extends StatefulWidget {
  final Family? family; // null for create, non-null for edit

  final List<Family> existingFamily; // For calculating limits

  const FamilyFormSheet(
      {super.key, this.family, this.existingFamily = const []});

  static Future<bool?> show(BuildContext context,
      {Family? family, List<Family> existingFamily = const []}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          FamilyFormSheet(family: family, existingFamily: existingFamily),
    );
  }

  @override
  State<FamilyFormSheet> createState() => _FamilyFormSheetState();
}

class _FamilyFormSheetState extends State<FamilyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _occupationController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  String _relationship = ''; // Default relationship ID
  String _relationshipName = ''; // For logic
  String _gender = 'M';
  DateTime? _birthDate;
  bool _bpjsCoverage = false;
  bool _isBpjsAutomatic = false;
  bool _isLoading = false;

  // Relationship options (matching backend)
  List<MasterOption> _relationshipOptions = [];
  List<MasterOption> _educationOptions = [];

  String? _education; // Education ID

  bool get isEdit => widget.family != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.family?.name ?? '');
    _occupationController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();

    _loadOptions();

    if (widget.family != null) {
      // Logic moved to _loadOptions to ensure options are loaded first
      _gender = widget.family!.gender ?? 'M';
      _bpjsCoverage = widget.family!.coverBpjs ?? false;
      _addressController.text = widget.family!.address ?? '';
      _phoneController.text = widget.family!.phone ?? '';
      _occupationController.text = widget.family!.occupation ?? '';

      // Parse birth date
      if (widget.family!.birthDate != null && widget.family!.birthDate != '-') {
        try {
          _birthDate = DateTime.parse(widget.family!.birthDate!);
        } catch (_) {}
      }
    }
  }

  Future<void> _loadOptions() async {
    setState(() => _isLoading = true);

    // Load Family Relationships
    final relRes = await ProfileService.getMasterOptions('FAMILY_OPTION');
    if (relRes.success && relRes.data != null) {
      if (mounted) {
        setState(() {
          _relationshipOptions = relRes.data!;
          // Match existing relationship if editing
          if (widget.family != null) {
            final match = _relationshipOptions
                .where((r) =>
                    r.name.toLowerCase() ==
                    widget.family!.relationship.toLowerCase())
                .firstOrNull;
            if (match != null) {
              _relationship = match.id;
              _relationshipName = match.name.toUpperCase();
              // Don't auto-calculate on load edit, respect saved value
              // but we need to know if it *would* be automatic to show the banner?
              // The frontend re-calculates it on load.
              _checkBpjsCoverage(initialLoad: true);
            }
          } else {
            // If new, set default? Frontend sets to empty.
            if (_relationshipOptions.isNotEmpty) {
              // Optional: _relationship = _relationshipOptions.first.id;
            }
          }
        });
      }
    }

    // Load Education Options
    final eduRes = await ProfileService.getMasterOptions('EDUCATION_OPTION');
    if (eduRes.success && eduRes.data != null) {
      if (mounted) {
        setState(() {
          _educationOptions = eduRes.data!;
          // Match existing education if editing
          if (widget.family != null && widget.family!.education != null) {
            // Try matching by ID first (most likely as it stores the code)
            var match = _educationOptions
                .where((e) => e.id == widget.family!.education)
                .firstOrNull;

            // Fallback to name match if ID fails
            match ??= _educationOptions
                .where((e) =>
                    e.name.toLowerCase() ==
                    widget.family!.education!.toLowerCase())
                .firstOrNull;

            if (match != null) {
              _education = match.id;
            }
          }
        });
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _occupationController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onRelationshipChanged(String? id) {
    if (id == null) return;
    final option = _relationshipOptions.firstWhere((e) => e.id == id);
    setState(() {
      _relationship = id;
      _relationshipName = option.name.toUpperCase();
    });

    // Auto Gender Logic
    if (_relationshipName == 'SUAMI' || _relationshipName == 'AYAH') {
      setState(() => _gender = 'M');
    } else if (_relationshipName == 'ISTRI' || _relationshipName == 'IBU') {
      setState(() => _gender = 'F');
    }

    // Auto BPJS Logic
    _checkBpjsCoverage();
  }

  void _checkBpjsCoverage({bool initialLoad = false}) {
    bool autoCover = false;
    bool isAutomatic = false;

    // Helper to count existing members of a certain type
    // Exclude current member if editing
    int countExisting(String nameRel) {
      return widget.existingFamily
          .where((f) =>
              f.relationship.toUpperCase() == nameRel &&
              (widget.family == null || f.id != widget.family!.id))
          .length;
    }

    switch (_relationshipName) {
      case 'ANAK':
        // Max 3 children covered automatically
        if (countExisting('ANAK') < 3) {
          autoCover = true;
          isAutomatic = true;
        } else {
          // 4th child+, manual logic (defaults to false usually)
          autoCover = false;
          isAutomatic = false;
        }
        break;
      case 'SUAMI':
        // Max 1 husband covered
        if (countExisting('SUAMI') < 1) {
          autoCover = true;
          isAutomatic = true;
        } else {
          autoCover = false;
          isAutomatic =
              false; // Or true but not covered? Frontend logic implies Manual switch if overflow or default false.
        }
        break;
      case 'ISTRI':
        // Max 1 wife covered
        if (countExisting('ISTRI') < 1) {
          autoCover = true;
          isAutomatic = true;
        } else {
          autoCover = false;
          isAutomatic = false;
        }
        break;
      case 'AYAH':
      case 'IBU':
        // Typically manual, sometimes auto. Frontend says:
        // Ayah/Ibu -> coverage=true, automatic=false (meaning it defaults to checked but can be unchecked? Or it IS covered?)
        // Wait, Frontend case 'AYAH': isBpjsCoverage=true; isBpjsAutomatic=false;
        // This implies it defaults to TRUE but is Manual (Switch visible).
        autoCover = true;
        isAutomatic = false;
        break;
      default:
        autoCover = true; // Default to checked?
        isAutomatic = false; // Manual
    }

    setState(() {
      _isBpjsAutomatic = isAutomatic;
      // specific logic: if automatic, force value
      if (_isBpjsAutomatic) {
        _bpjsCoverage = autoCover;
      } else if (!initialLoad) {
        // If switching to manual mode, maybe set default?
        _bpjsCoverage = autoCover;
      }
      // If initialLoad and manual, we keep the value from database (already set in loading)
    });
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select birth date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'ef_name': _nameController.text.trim(),
      'ef_relationship': _relationship,
      'ef_birthday': _birthDate!.toIso8601String().split('T').first,
      'ef_gender': _gender,
      'ef_cover_bpjs': _bpjsCoverage,
      'ef_education': _education,
      'ef_occupation': _occupationController.text.trim().isEmpty
          ? null
          : _occupationController.text.trim(),
      'ef_phone': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      'ef_address': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
    };

    final result = isEdit
        ? await ProfileService.updateFamily(widget.family!.id, data)
        : await ProfileService.createFamily(data);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(isEdit ? 'Family member updated' : 'Family member added'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to save family member'),
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
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.family_restroom,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Family Member' : 'Add Family Member',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Enter family member details',
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
                    // Name
                    _buildLabel('Full Name'),
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          _inputDecoration('Enter name', Icons.person_outline),
                      validator: (v) =>
                          v?.trim().isEmpty == true ? 'Required' : null,
                    ),

                    const SizedBox(height: 16),

                    // Relationship
                    _buildLabel('Relationship'),
                    DropdownButtonFormField<String>(
                      value:
                          _relationshipOptions.any((e) => e.id == _relationship)
                              ? _relationship
                              : null,
                      hint: const Text('Select relationship'),
                      decoration: _inputDecoration(
                          'Select relationship', Icons.family_restroom),
                      items: _relationshipOptions.map((r) {
                        return DropdownMenuItem(
                            value: r.id, child: Text(r.name));
                      }).toList(),
                      onChanged: _onRelationshipChanged,
                      validator: (v) =>
                          v == null ? 'Please select relationship' : null,
                    ),

                    const SizedBox(height: 16),

                    // Education
                    _buildLabel('Education'),
                    DropdownButtonFormField<String>(
                      value: _educationOptions.any((e) => e.id == _education)
                          ? _education
                          : null,
                      hint: const Text('Select education'),
                      decoration:
                          _inputDecoration('Select education', Icons.school),
                      items: _educationOptions.map((r) {
                        return DropdownMenuItem(
                            value: r.id, child: Text(r.name));
                      }).toList(),
                      onChanged: (v) => setState(() => _education = v),
                    ),

                    const SizedBox(height: 16),

                    const SizedBox(height: 16),

                    // Occupation
                    _buildLabel('Occupation'),
                    TextFormField(
                      controller: _occupationController,
                      decoration: _inputDecoration(
                          'Enter occupation', Icons.work_outlined),
                    ),

                    const SizedBox(height: 16),

                    // Gender
                    _buildLabel('Gender'),
                    Row(
                      children: [
                        Expanded(
                          child: _genderOption('M', 'Male', Icons.male),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _genderOption('F', 'Female', Icons.female),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Birth Date
                    _buildLabel('Birth Date'),
                    GestureDetector(
                      onTap: _selectBirthDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: AppColors.textMuted),
                            const SizedBox(width: 12),
                            Text(
                              _birthDate != null
                                  ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                                  : 'Select birth date',
                              style: TextStyle(
                                color: _birthDate != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const SizedBox(height: 16),

                    // Phone
                    _buildLabel('Phone Number'),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration:
                          _inputDecoration('Enter phone number', Icons.phone),
                    ),

                    const SizedBox(height: 16),

                    // Address
                    _buildLabel('Address'),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration:
                          _inputDecoration('Enter address', Icons.location_on),
                    ),

                    const SizedBox(height: 16),

                    // BPJS Coverage Widget
                    if (_isBpjsAutomatic)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.5),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Automatically Covered',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'This family member is automatically covered by BPJS.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _bpjsCoverage
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _bpjsCoverage
                                ? Colors.green
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.health_and_safety,
                              color: _bpjsCoverage ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'BPJS Coverage',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Switch(
                              value: _bpjsCoverage,
                              onChanged: (v) =>
                                  setState(() => _bpjsCoverage = v),
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
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
                                    isEdit ? 'Update' : 'Add Family Member',
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

  Widget _genderOption(String value, String label, IconData icon) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withAlpha(20) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

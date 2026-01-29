import 'package:flutter/material.dart';
import 'package:mobile_app/core/services/profile_service.dart';
import 'package:mobile_app/core/theme/app_colors.dart';

class PersonalDataFormSheet extends StatefulWidget {
  final PersonalData? data;

  const PersonalDataFormSheet({super.key, this.data});

  static Future<bool?> show(BuildContext context, {PersonalData? data}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PersonalDataFormSheet(data: data),
    );
  }

  @override
  State<PersonalDataFormSheet> createState() => _PersonalDataFormSheetState();
}

class _PersonalDataFormSheetState extends State<PersonalDataFormSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _ktpController;
  late TextEditingController _npwpController;
  late TextEditingController _birthPlaceController;
  late TextEditingController _birthDateController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  String? _gender;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.data?.name);
    _ktpController = TextEditingController(text: widget.data?.ktp);
    _npwpController = TextEditingController(text: widget.data?.npwp);
    _birthPlaceController =
        TextEditingController(text: widget.data?.birthPlace);
    _birthDateController = TextEditingController(text: widget.data?.birthDate);
    _phoneController = TextEditingController(text: widget.data?.phone);
    _addressController = TextEditingController(text: widget.data?.address);

    _gender = widget.data?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ktpController.dispose();
    _npwpController.dispose();
    _birthPlaceController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'emp_full_name': _nameController.text,
      'emp_nik': widget.data?.nik ?? '',
      'emp_ktp': _ktpController.text,
      'emp_npwp': _npwpController.text,
      'emp_birth_place': _birthPlaceController.text,
      'emp_birth_date': _birthDateController.text,
      'emp_gender': _gender,
      // 'emp_phone': _phoneController.text, // Managed via Contact Form
      // 'emp_address': _addressController.text, // Managed via Address Form
    };

    final result = await ProfileService.updatePersonalData(data);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal data updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to update personal data'),
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
                        Icons.person,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Personal Info',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Update your personal details',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                      decoration: _inputDecoration(
                          'Enter full name', Icons.person_outline),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // KTP
                    _buildLabel('No KTP'),
                    TextFormField(
                      controller: _ktpController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                          'Enter KTP number', Icons.badge_outlined),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // NPWP
                    _buildLabel('NPWP'),
                    TextFormField(
                      controller: _npwpController,
                      decoration:
                          _inputDecoration('Enter NPWP', Icons.card_membership),
                    ),
                    const SizedBox(height: 16),

                    // Birth Place & Date
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Birth Place'),
                              TextFormField(
                                controller: _birthPlaceController,
                                decoration: _inputDecoration(
                                    'City', Icons.location_city),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Birth Date'),
                              TextFormField(
                                controller: _birthDateController,
                                readOnly: true,
                                onTap: _selectDate,
                                decoration: _inputDecoration(
                                    'Select date', Icons.calendar_today),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gender
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Gender'),
                        DropdownButtonFormField<String>(
                          value: _gender,
                          decoration: _inputDecoration('Gender', Icons.wc),
                          items: const [
                            DropdownMenuItem(value: 'M', child: Text('Male')),
                            DropdownMenuItem(value: 'F', child: Text('Female')),
                          ],
                          onChanged: (v) => setState(() => _gender = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Phone (Read Only)
                    _buildLabel('Phone Number'),
                    TextFormField(
                      controller: _phoneController,
                      readOnly: true,
                      enabled: false,
                      decoration: _inputDecoration(
                        'Managed via Contact',
                        Icons.phone,
                      ).copyWith(
                        helperText: 'Phone can be updated in Contact menu',
                        fillColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address (Read Only)
                    _buildLabel('KTP Address'),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      readOnly: true,
                      enabled: false,
                      decoration: _inputDecoration(
                        'Managed via Address',
                        Icons.home,
                      ).copyWith(
                        helperText: 'Address can be updated in Address menu',
                        fillColor: Colors.grey[200],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Buttons
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
                                : const Text(
                                    'Update',
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

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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

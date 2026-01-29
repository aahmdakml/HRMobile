import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/core/services/profile_service.dart';

/// Bottom sheet form for adding/editing an address
class AddressFormSheet extends StatefulWidget {
  final Address? address; // null for create, non-null for edit

  const AddressFormSheet({super.key, this.address});

  static Future<bool?> show(BuildContext context, {Address? address}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressFormSheet(address: address),
    );
  }

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Location data
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _villages = [];

  // Selected values
  String? _selectedProvinceCode;
  String? _selectedCityCode;
  String? _selectedDistrictCode;
  String? _selectedVillageCode;
  bool _isPrimary = false;

  bool _isLoading = false;
  bool _isLoadingLocation = false;

  bool get isEdit => widget.address != null;

  @override
  void initState() {
    super.initState();
    _loadProvinces();

    if (widget.address != null) {
      _addressController.text = widget.address!.address;
      _postalCodeController.text = widget.address!.postalCode ?? '';
      _isPrimary = widget.address!.isPrimary;

      // Load location data for edit mode
      _loadEditData();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadProvinces() async {
    final result = await ProfileService.getProvinces();
    if (result.success && result.data != null) {
      setState(() => _provinces = result.data!);
    }
  }

  Future<void> _loadEditData() async {
    if (widget.address == null) return;

    final addr = widget.address!;
    setState(() => _isLoadingLocation = true);

    try {
      // 1. Set Province
      String? provCode = addr.provinceCode;

      // Fallback: Match by name if code is missing
      if (provCode == null && addr.province != null && _provinces.isNotEmpty) {
        final match = _provinces.firstWhere(
          (p) =>
              p['province_name'].toString().toLowerCase() ==
              addr.province!.toLowerCase(),
          orElse: () => {},
        );
        if (match.isNotEmpty) {
          provCode = match['province_code'].toString();
        }
      }

      if (provCode != null) {
        setState(() => _selectedProvinceCode = provCode);

        // 2. Load Cities
        final citiesRes = await ProfileService.getCities(provCode);
        if (citiesRes.success && citiesRes.data != null) {
          setState(() => _cities = citiesRes.data!);

          // 3. Set City
          String? cityCode = addr.cityCode;
          if (cityCode == null && addr.city != null) {
            final match = _cities.firstWhere(
              (c) =>
                  c['regency_name'].toString().toLowerCase() ==
                  addr.city!.toLowerCase(),
              orElse: () => {},
            );
            if (match.isNotEmpty) cityCode = match['regency_code'].toString();
          }

          if (cityCode != null) {
            setState(() => _selectedCityCode = cityCode);

            // 4. Load Districts
            final distRes =
                await ProfileService.getDistricts(provCode, cityCode);
            if (distRes.success && distRes.data != null) {
              setState(() => _districts = distRes.data!);

              // 5. Set District
              String? distCode = addr.districtCode;
              if (distCode == null && addr.district != null) {
                final match = _districts.firstWhere(
                  (d) =>
                      d['district_name'].toString().toLowerCase() ==
                      addr.district!.toLowerCase(),
                  orElse: () => {},
                );
                if (match.isNotEmpty)
                  distCode = match['district_code'].toString();
              }

              if (distCode != null) {
                setState(() => _selectedDistrictCode = distCode);

                // 6. Load Villages
                final villRes = await ProfileService.getVillages(
                    provCode, cityCode, distCode);
                if (villRes.success && villRes.data != null) {
                  setState(() {
                    _villages = villRes.data!;

                    // 7. Set Village
                    String? villCode = addr.villageCode;
                    if (villCode == null && addr.village != null) {
                      final match = _villages.firstWhere(
                        (v) =>
                            v['village_name'].toString().toLowerCase() ==
                            addr.village!.toLowerCase(),
                        orElse: () => {},
                      );
                      if (match.isNotEmpty)
                        villCode = match['village_code'].toString();
                    }
                    _selectedVillageCode = villCode;
                  });
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading location data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _loadCities(String provinceCode) async {
    setState(() {
      _cities = [];
      _districts = [];
      _villages = [];
      _selectedCityCode = null;
      _selectedDistrictCode = null;
      _selectedVillageCode = null;
    });

    final result = await ProfileService.getCities(provinceCode);
    if (result.success && result.data != null) {
      setState(() => _cities = result.data!);
    }
  }

  Future<void> _loadDistricts(String provinceCode, String cityCode) async {
    setState(() {
      _districts = [];
      _villages = [];
      _selectedDistrictCode = null;
      _selectedVillageCode = null;
    });

    final result = await ProfileService.getDistricts(provinceCode, cityCode);
    if (result.success && result.data != null) {
      setState(() => _districts = result.data!);
    }
  }

  Future<void> _loadVillages(
      String provinceCode, String cityCode, String districtCode) async {
    setState(() {
      _villages = [];
      _selectedVillageCode = null;
    });

    final result =
        await ProfileService.getVillages(provinceCode, cityCode, districtCode);
    if (result.success && result.data != null) {
      setState(() => _villages = result.data!);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvinceCode == null ||
        _selectedCityCode == null ||
        _selectedDistrictCode == null ||
        _selectedVillageCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all location fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'ed_address': _addressController.text.trim(),
      'province_code': _selectedProvinceCode,
      'regency_code': _selectedCityCode,
      'district_code': _selectedDistrictCode,
      'village_code': _selectedVillageCode,
      'ed_zip_code': _postalCodeController.text.trim(),
      'ed_is_primary': _isPrimary,
    };

    final result = isEdit
        ? await ProfileService.updateAddress(widget.address!.id, data)
        : await ProfileService.createAddress(data);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Address updated' : 'Address added'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to save address'),
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
                        Icons.location_on,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Edit Address' : 'Add Address',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Enter complete address details',
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
                    if (_isLoadingLocation)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      // Province
                      _buildLabel('Province'),
                      _buildDropdown(
                        value: _selectedProvinceCode,
                        items: _provinces,
                        keyField: 'province_code',
                        labelField: 'province_name',
                        hint: 'Select Province',
                        onChanged: (value) {
                          setState(() => _selectedProvinceCode = value);
                          if (value != null) _loadCities(value);
                        },
                      ),

                      const SizedBox(height: 16),

                      // City
                      _buildLabel('City/Regency'),
                      _buildDropdown(
                        value: _selectedCityCode,
                        items: _cities,
                        keyField: 'regency_code',
                        labelField: 'regency_name',
                        hint: 'Select City/Regency',
                        enabled: _selectedProvinceCode != null,
                        onChanged: (value) {
                          setState(() => _selectedCityCode = value);
                          if (value != null && _selectedProvinceCode != null) {
                            _loadDistricts(_selectedProvinceCode!, value);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // District
                      _buildLabel('District'),
                      _buildDropdown(
                        value: _selectedDistrictCode,
                        items: _districts,
                        keyField: 'district_code',
                        labelField: 'district_name',
                        hint: 'Select District',
                        enabled: _selectedCityCode != null,
                        onChanged: (value) {
                          setState(() => _selectedDistrictCode = value);
                          if (value != null &&
                              _selectedProvinceCode != null &&
                              _selectedCityCode != null) {
                            _loadVillages(_selectedProvinceCode!,
                                _selectedCityCode!, value);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Village
                      _buildLabel('Village'),
                      _buildDropdown(
                        value: _selectedVillageCode,
                        items: _villages,
                        keyField: 'village_code',
                        labelField: 'village_name',
                        hint: 'Select Village',
                        enabled: _selectedDistrictCode != null,
                        onChanged: (value) {
                          setState(() => _selectedVillageCode = value);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Full Address
                      _buildLabel('Full Address'),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter street, number, RT/RW, etc.',
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
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 10) {
                            return 'Address must be at least 10 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Postal Code
                      _buildLabel('Postal Code'),
                      TextFormField(
                        controller: _postalCodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        decoration: InputDecoration(
                          hintText: 'Enter postal code',
                          prefixIcon: Icon(Icons.local_post_office_outlined,
                              color: AppColors.textMuted),
                          filled: true,
                          fillColor: Colors.grey[100],
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter postal code';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Primary toggle
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isPrimary
                              ? Colors.amber.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                _isPrimary ? Colors.amber : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: _isPrimary ? Colors.amber : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Set as Primary Address',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    'This will be your main address',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isPrimary,
                              onChanged: (value) =>
                                  setState(() => _isPrimary = value),
                              activeColor: Colors.amber,
                            ),
                          ],
                        ),
                      ),
                    ],

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
                                    isEdit ? 'Update Address' : 'Add Address',
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

  Widget _buildDropdown({
    required String? value,
    required List<Map<String, dynamic>> items,
    required String keyField,
    required String labelField,
    required String hint,
    required void Function(String?) onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: enabled ? Colors.grey[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: AppColors.textMuted)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted),
          items: items.map((item) {
            final code = item[keyField]?.toString();
            final name = item[labelField]?.toString() ?? '';
            return DropdownMenuItem(value: code, child: Text(name));
          }).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

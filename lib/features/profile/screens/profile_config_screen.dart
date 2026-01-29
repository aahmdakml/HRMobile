import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/core/services/auth_state.dart';
import 'package:mobile_app/core/services/profile_service.dart';
import 'package:mobile_app/features/profile/screens/forms/address_form_sheet.dart';
import 'package:mobile_app/features/profile/screens/forms/contact_form_sheet.dart';
import 'package:mobile_app/features/profile/screens/forms/emergency_contact_form_sheet.dart';
import 'package:mobile_app/features/profile/screens/forms/family_form_sheet.dart';
import 'package:mobile_app/features/profile/screens/forms/education_form_sheet.dart';
import 'package:mobile_app/features/profile/screens/forms/supporting_file_form_sheet.dart';
import 'package:mobile_app/features/profile/screens/forms/personal_data_form_sheet.dart';

/// Profile Config Screen - Full profile with API data
/// Reference: /api/v1/hris/profile/*
class ProfileConfigScreen extends StatefulWidget {
  const ProfileConfigScreen({super.key});

  @override
  State<ProfileConfigScreen> createState() => _ProfileConfigScreenState();
}

class _ProfileConfigScreenState extends State<ProfileConfigScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  final List<String> _tabs = [
    'Personal',
    'Address',
    'Contact',
    'Emergency',
    'Family',
    'Education',
    'Files', // Supporting Files
  ];

  // Data state
  bool _isLoading = true;
  String? _error;
  PersonalData? _personalData;
  List<Address> _addresses = [];
  List<Contact> _contacts = [];
  List<Family> _family = [];
  List<Education> _education = [];
  List<EmergencyContact> _emergencyContacts = [];
  List<SupportingFile> _supportingFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);

    // Breathing Animation
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: Curves.easeInOut,
      ),
    );

    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all profile sections in parallel
      final results = await Future.wait([
        ProfileService.getPersonalData(),
        ProfileService.getAddresses(),
        ProfileService.getContacts(),
        ProfileService.getFamily(),
        ProfileService.getEducation(),
        ProfileService.getEmergencyContacts(),
        ProfileService.getSupportingFiles(),
      ]);

      if (!mounted) return;

      setState(() {
        _isLoading = false;

        final personalResult = results[0] as ProfileResult<PersonalData>;
        if (personalResult.success) _personalData = personalResult.data;

        final addressResult = results[1] as ProfileResult<List<Address>>;
        if (addressResult.success) _addresses = addressResult.data ?? [];

        final contactResult = results[2] as ProfileResult<List<Contact>>;
        if (contactResult.success) _contacts = contactResult.data ?? [];

        final familyResult = results[3] as ProfileResult<List<Family>>;
        if (familyResult.success) _family = familyResult.data ?? [];

        final educationResult = results[4] as ProfileResult<List<Education>>;
        if (educationResult.success) _education = educationResult.data ?? [];

        final emergencyResult =
            results[5] as ProfileResult<List<EmergencyContact>>;
        if (emergencyResult.success)
          _emergencyContacts = emergencyResult.data ?? [];

        final filesResult = results[6] as ProfileResult<List<SupportingFile>>;
        if (filesResult.success) _supportingFiles = filesResult.data ?? [];
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load profile data';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF1E1E2D), // Dark background matching header
      body: DefaultTabController(
        length: _tabs.length,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              // Dark Header with Profile Info
              SliverAppBar(
                expandedHeight: 280.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF1E1E2D),
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeaderContent(),
                  collapseMode: CollapseMode.pin,
                ),
              ),

              // Sticky TabBar Container
              SliverPersistentHeader(
                delegate: _StickyTabBarDelegate(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10), // Space for overlap
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          labelStyle: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                          indicatorColor: AppColors.primary,
                          indicatorWeight: 3,
                          indicatorSize: TabBarIndicatorSize.label,
                          tabAlignment: TabAlignment.start,
                          dividerColor: Colors.transparent,
                          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                        ),
                        const Divider(height: 1, color: AppColors.border),
                      ],
                    ),
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          // Body Content (White Background)
          body: Container(
            color: Colors.white, // Continues the white background
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildPersonalTab(),
                          _buildAddressTab(),
                          _buildContactTab(),
                          _buildEmergencyTab(),
                          _buildFamilyTab(),
                          _buildEducationTab(),
                          _buildSupportingFileTab(),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderContent() {
    // Get data from authState or loaded personalData
    final user = authState.user;
    final name = _personalData?.name ?? user?.displayName ?? 'Loading...';
    final empId = _personalData?.empId ?? user?.empId ?? '-';
    final position = user?.employee?.position ?? 'Employee';

    return SafeArea(
      child: Stack(
        children: [
          // Spotlight Glow Background (Breathing)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      radius: _breathingAnimation.value, // Breathing radius
                      colors: [
                        AppColors.primary.withValues(
                            alpha: 0.15 *
                                (2.5 -
                                    _breathingAnimation
                                        .value)), // Pulse opacity
                        const Color(0xFF1E1E2D),
                      ],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                );
              },
            ),
          ),

          // Subtle Top Light Source
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.05),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Profile Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // Avatar with Glassmorphism Effect
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(Icons.person,
                          color: Colors.white.withOpacity(0.9), size: 50),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              // Position & ID Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Text(
                  '$position • $empId',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20), // Bottom padding for overlap
            ],
          ),
        ],
      ),
    );
  }

  // _buildTabBar and _buildHeader removed as they are replaced by Sliver logic

  Widget _buildPersonalTab() {
    final data = _personalData;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildEditableCard(
            title: 'Personal Information',
            onEdit: () async {
              final result =
                  await PersonalDataFormSheet.show(context, data: data);
              if (result == true) _loadProfileData();
            },
            fields: [
              _FieldData('Nama Lengkap', data?.name ?? '-'),
              _FieldData('No KTP', data?.ktp ?? '-'),
              _FieldData('NPWP', data?.npwp ?? '-'),
              _FieldData('Tanggal Lahir', data?.birthDate ?? '-'),
              _FieldData('Tempat Lahir', data?.birthPlace ?? '-'),
              _FieldData('Jenis Kelamin', _getGenderText(data?.gender)),
              _FieldData('No. Telepon', data?.phone ?? '-'),
              _FieldData('Alamat Lengkap', data?.address ?? '-'),
            ],
          ),
        ],
      ),
    );
  }

  String _getGenderText(String? gender) {
    if (gender == 'M') return 'Laki-laki';
    if (gender == 'F') return 'Perempuan';
    return gender ?? '-';
  }

  Widget _buildAddressTab() {
    if (_addresses.isEmpty) {
      return _buildEmptyState('No addresses found', 'Add Address', () async {
        final result = await AddressFormSheet.show(context);
        if (result == true) _loadProfileData();
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ..._addresses.map((addr) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAddressCard(
                  id: addr.id,
                  address: addr.address,
                  location: [
                    addr.village,
                    addr.district,
                    addr.city,
                    addr.province,
                  ].where((e) => e != null).join(', '),
                  postalCode: addr.postalCode,
                  isPrimary: addr.isPrimary,
                  onEdit: () async {
                    final result =
                        await AddressFormSheet.show(context, address: addr);
                    if (result == true) _loadProfileData();
                  },
                ),
              )),
          const SizedBox(height: 8),
          _buildAddButton('Add Address', () async {
            final result = await AddressFormSheet.show(context);
            if (result == true) _loadProfileData();
          }),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    if (_contacts.isEmpty && _emergencyContacts.isEmpty) {
      return _buildEmptyState('No contacts found', 'Add Contact', () async {
        final result = await ContactFormSheet.show(context);
        if (result == true) _loadProfileData();
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contacts List Header
          if (_contacts.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                      width: 32,
                      child: Text('No.',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600))),
                  const SizedBox(
                      width: 40,
                      child: Center(
                          child:
                              Icon(Icons.star, size: 16, color: Colors.grey))),
                  const SizedBox(
                      width: 70,
                      child: Text('Type',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600))),
                  const Expanded(
                      child: Text('Phone / Email',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600))),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: _contacts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final c = entry.value;
                  final isPhone = c.type.toUpperCase() == 'PHONE';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      border: index < _contacts.length - 1
                          ? Border(bottom: BorderSide(color: AppColors.border))
                          : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 32,
                            child: Text('${index + 1}',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary))),
                        SizedBox(
                          width: 40,
                          child: Center(
                            child: Icon(
                              Icons.star,
                              size: 18,
                              color: c.isPrimary
                                  ? Colors.amber
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isPhone
                                  ? AppColors.success.withOpacity(0.15)
                                  : AppColors.info.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPhone ? 'Phone' : 'Email',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isPhone
                                    ? AppColors.success
                                    : AppColors.info,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 40,
                          child: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert,
                                size: 18, color: AppColors.textMuted),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final result = await ContactFormSheet.show(
                                    context,
                                    contact: c);
                                if (result == true) _loadProfileData();
                              } else if (value == 'delete') {
                                _confirmDelete(
                                  'Delete Contact',
                                  'Are you sure you want to delete this contact?',
                                  () => ProfileService.deleteContact(c.id),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined,
                                        size: 18, color: AppColors.textPrimary),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline,
                                        size: 18, color: AppColors.error),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style:
                                            TextStyle(color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 8),
          _buildAddButton('Add Contact', () async {
            final result = await ContactFormSheet.show(context);
            if (result == true) _loadProfileData();
          }),
        ],
      ),
    );
  }

  Widget _buildEmergencyTab() {
    if (_emergencyContacts.isEmpty) {
      return _buildEmptyState(
          'No emergency contacts found', 'Add Emergency Contact', () async {
        final result = await EmergencyContactFormSheet.show(context);
        if (result == true) _loadProfileData();
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ..._emergencyContacts.map((ec) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEmergencyContactCard(
                  id: ec.id,
                  name: ec.name,
                  relationship: ec.relationship,
                  phone: ec.phone,
                  address: ec.address,
                  onEdit: () async {
                    final result = await EmergencyContactFormSheet.show(context,
                        contact: ec);
                    if (result == true) _loadProfileData();
                  },
                ),
              )),
          const SizedBox(height: 8),
          _buildAddButton('Add Emergency Contact', () async {
            final result = await EmergencyContactFormSheet.show(context);
            if (result == true) _loadProfileData();
          }),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    String title,
    String content,
    Future<bool> Function() onDelete,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      final success = await onDelete();
      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted successfully')),
        );
        _loadProfileData();
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete item')),
        );
      }
    }
  }

  Widget _buildFamilyTab() {
    if (_family.isEmpty) {
      return _buildEmptyState('No family members found', 'Add Family Member',
          () async {
        final result = await FamilyFormSheet.show(context);
        if (result == true) _loadProfileData();
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ..._family.map((member) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFamilyMemberCard(
                  id: member.id,
                  name: member.name,
                  relationship: member.relationship,
                  birthDate: member.birthDate ?? '-',
                  gender: member.gender,
                  isBpjsCovered: member.coverBpjs,
                  onEdit: () async {
                    final result = await FamilyFormSheet.show(context,
                        family: member, existingFamily: _family);
                    if (result == true) _loadProfileData();
                  },
                ),
              )),
          const SizedBox(height: 8),
          _buildAddButton('Add Family Member', () async {
            final result =
                await FamilyFormSheet.show(context, existingFamily: _family);
            if (result == true) _loadProfileData();
          }),
        ],
      ),
    );
  }

  Widget _buildEducationTab() {
    if (_education.isEmpty) {
      return _buildEmptyState('No education history found', 'Add Education',
          () async {
        final result = await EducationFormSheet.show(context);
        if (result == true) _loadProfileData();
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ..._education.map((edu) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEducationCard(
                  id: edu.id,
                  level: edu.level,
                  institution: edu.institution,
                  major: edu.major ?? '-',
                  year: '${edu.startYear ?? '?'} - ${edu.endYear ?? 'Present'}',
                  gpa: edu.gpa,
                  onEdit: () async {
                    final result =
                        await EducationFormSheet.show(context, education: edu);
                    if (result == true) _loadProfileData();
                  },
                ),
              )),
          const SizedBox(height: 8),
          _buildAddButton('Add Education', () async {
            final result = await EducationFormSheet.show(context);
            if (result == true) _loadProfileData();
          }),
        ],
      ),
    );
  }

  Widget _buildSupportingFileTab() {
    if (_supportingFiles.isEmpty) {
      return _buildEmptyState('No supporting files found', 'Upload File',
          () async {
        final result = await SupportingFileFormSheet.show(context);
        if (result == true) _loadProfileData();
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ..._supportingFiles.map((file) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFileCard(
                  id: file.id,
                  fileName: file.fileName,
                  type: file.type,
                  uploadDate: file.uploadDate,
                  onEdit: () async {
                    final result =
                        await SupportingFileFormSheet.show(context, file: file);
                    if (result == true) _loadProfileData();
                  },
                  onView: () {
                    SupportingFileFormSheet.viewFile(context, file.id);
                  },
                ),
              )),
          const SizedBox(height: 8),
          _buildAddButton('Upload File', () async {
            final result = await SupportingFileFormSheet.show(context);
            if (result == true) _loadProfileData();
          }),
        ],
      ),
    );
  }

  // ============ Card Builders (Uniform Style) ============

  Widget _buildAddressCard({
    required int id,
    required String address,
    required String location,
    String? postalCode,
    bool isPrimary = false,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.location_on_outlined,
                color: AppColors.warning, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPrimary)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Primary',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  location.isNotEmpty ? location : '-',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (postalCode != null)
                  Text(
                    'Postal: $postalCode',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit?.call();
              } else if (value == 'delete') {
                _confirmDelete(
                  'Delete Address',
                  'Are you sure you want to delete this address?',
                  () => ProfileService.deleteAddress(id),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required String type,
    required String value,
    bool isPrimary = false,
  }) {
    final isPhone = type.toUpperCase() == 'PHONE';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  (isPhone ? AppColors.success : AppColors.info).withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPhone ? Icons.phone_outlined : Icons.email_outlined,
              color: isPhone ? AppColors.success : AppColors.info,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isPrimary)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Primary',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon:
                Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard({
    required int id,
    required String name,
    required String relationship,
    required String phone,
    String? address,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.emergency_outlined,
                color: AppColors.error, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$relationship • $phone',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (address != null && address.isNotEmpty)
                  Text(
                    address,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit?.call();
              } else if (value == 'delete') {
                _confirmDelete(
                  'Delete Emergency Contact',
                  'Are you sure you want to delete this emergency contact?',
                  () => ProfileService.deleteEmergencyContact(id),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard({
    required int id,
    required String fileName,
    required String type,
    String? uploadDate,
    VoidCallback? onEdit,
    VoidCallback? onView,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.description_outlined,
                color: AppColors.secondary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                if (uploadDate != null)
                  Text(
                    uploadDate,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
            onSelected: (value) {
              if (value == 'view') {
                onView?.call();
              } else if (value == 'edit') {
                onEdit?.call();
              } else if (value == 'delete') {
                _confirmDelete(
                  'Delete File',
                  'Are you sure you want to delete this file?',
                  () => ProfileService.deleteSupportingFile(id),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined,
                        size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('View'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      String message, String buttonText, VoidCallback onPressed) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            _buildAddButton(buttonText, onPressed),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableCard({
    required String title,
    required VoidCallback onEdit,
    required List<_FieldData> fields,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          ...fields.map((field) => _buildFieldRow(field.label, field.value)),
        ],
      ),
    );
  }

  Widget _buildFieldRow(String label, String value) {
    return LayoutBuilder(builder: (context, constraints) {
      // Use 35% of width for label, but min 100 max 160
      final labelWidth = (constraints.maxWidth * 0.35).clamp(100.0, 160.0);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                label,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFamilyMemberCard({
    required int id,
    required String name,
    required String relationship,
    required String birthDate,
    String? gender,
    bool isBpjsCovered = false,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$relationship • $birthDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (gender != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: gender == 'M'
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.pink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          gender == 'M' ? 'Male' : 'Female',
                          style: TextStyle(
                              fontSize: 10,
                              color: gender == 'M' ? Colors.blue : Colors.pink,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isBpjsCovered
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isBpjsCovered ? 'BPJS Covered' : 'Non-BPJS',
                        style: TextStyle(
                            fontSize: 10,
                            color: isBpjsCovered ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit?.call();
              } else if (value == 'delete') {
                _confirmDelete(
                  'Delete Family Member',
                  'Are you sure you want to delete this family member?',
                  () => ProfileService.deleteFamily(id),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard({
    required int id,
    required String level,
    required String institution,
    required String major,
    required String year,
    String? gpa,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.school_outlined, color: AppColors.info, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  institution,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '$major • $year ${gpa != null ? "• GPA: $gpa" : ""}',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit?.call();
              } else if (value == 'delete') {
                _confirmDelete(
                  'Delete Education',
                  'Are you sure you want to delete this education record?',
                  () => ProfileService.deleteEducation(id),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error ?? 'Error loading data'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProfileData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _FieldData {
  final String label;
  final String value;
  _FieldData(this.label, this.value);
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 60.0; // Height of the TabBar container

  @override
  double get minExtent => 60.0;

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

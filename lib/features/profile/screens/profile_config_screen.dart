import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/core/services/auth_state.dart';
import 'package:mobile_app/core/services/profile_service.dart';

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
    'Family',
    'Education',
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
                          _buildFamilyTab(),
                          _buildEducationTab(),
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
                        AppColors.primary.withOpacity(0.15 *
                            (2.5 - _breathingAnimation.value)), // Pulse opacity
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
      child: _buildEditableCard(
        title: 'Personal Information',
        onEdit: () {},
        fields: [
          _FieldData('Full Name', data?.name ?? '-'),
          _FieldData('NIK', data?.empId ?? '-'),
          _FieldData('Date of Birth', data?.birthDate ?? '-'),
          _FieldData('Gender', data?.gender ?? '-'),
          _FieldData('Religion', data?.religion ?? '-'),
          _FieldData('Marital Status', data?.maritalStatus ?? '-'),
          _FieldData('Blood Type', data?.bloodType ?? '-'),
        ],
      ),
    );
  }

  Widget _buildAddressTab() {
    if (_addresses.isEmpty) {
      return _buildEmptyState('No addresses found', 'Add Address');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _addresses.map((address) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildEditableCard(
              title: address.type.isNotEmpty ? address.type : 'Address',
              onEdit: () {},
              fields: [
                _FieldData('Address', address.address),
                if (address.city != null) _FieldData('City', address.city!),
                if (address.province != null)
                  _FieldData('Province', address.province!),
                if (address.postalCode != null)
                  _FieldData('Postal Code', address.postalCode!),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Regular contacts
          if (_contacts.isNotEmpty)
            _buildEditableCard(
              title: 'Contact Information',
              onEdit: () {},
              fields:
                  _contacts.map((c) => _FieldData(c.type, c.value)).toList(),
            ),

          if (_contacts.isNotEmpty && _emergencyContacts.isNotEmpty)
            const SizedBox(height: 16),

          // Emergency contacts
          ..._emergencyContacts.map((ec) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEditableCard(
                  title: 'Emergency Contact',
                  onEdit: () {},
                  fields: [
                    _FieldData('Name', ec.name),
                    _FieldData('Relationship', ec.relationship),
                    _FieldData('Phone', ec.phone),
                    if (ec.address != null) _FieldData('Address', ec.address!),
                  ],
                ),
              )),

          if (_contacts.isEmpty && _emergencyContacts.isEmpty)
            _buildEmptyState('No contacts found', 'Add Contact'),
        ],
      ),
    );
  }

  Widget _buildFamilyTab() {
    if (_family.isEmpty) {
      return _buildEmptyState('No family members found', 'Add Family Member');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ..._family.map((member) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildFamilyMemberCard(
                  name: member.name,
                  relationship: member.relationship,
                  birthDate: member.birthDate ?? '-',
                ),
              )),
          const SizedBox(height: 8),
          _buildAddButton('Add Family Member', () {}),
        ],
      ),
    );
  }

  Widget _buildEducationTab() {
    if (_education.isEmpty) {
      return _buildEmptyState('No education history found', 'Add Education');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ..._education.map((edu) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildEducationCard(
                  level: edu.level,
                  institution: edu.institution,
                  major: edu.major ?? '-',
                  year: edu.graduationYear ?? '-',
                ),
              )),
          const SizedBox(height: 8),
          _buildAddButton('Add Education', () {}),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, String buttonText) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          _buildAddButton(buttonText, () {}),
        ],
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
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
  }

  Widget _buildFamilyMemberCard({
    required String name,
    required String relationship,
    required String birthDate,
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
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationCard({
    required String level,
    required String institution,
    required String major,
    required String year,
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
                  '$major • $year',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppColors.textMuted,
            ),
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

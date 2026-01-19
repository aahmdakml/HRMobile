import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/core/models/module_item.dart';
import 'package:mobile_app/features/settings/screens/settings_screen.dart';
import 'package:mobile_app/features/profile/screens/profile_screen.dart';
import 'package:mobile_app/features/home/screens/all_modules_screen.dart';
import 'package:mobile_app/features/home/screens/edit_featured_screen.dart';

/// Home Screen (Dashboard) - Gojek-style with customizable featured modules
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Featured module IDs (user customizable)
  List<String> _featuredModuleIds = List.from(HrisModules.defaultFeaturedIds);

  // Height constants for layout calculation
  static const double _headerHeight = 80;
  static const double _featuredHeight = 300; // Height of featured section
  static const double _overlapAmount =
      120; // How much white overlaps into featured

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2D),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Stack for overlap effect - white section behind featured
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // White background (positioned behind, but overlapping)
                  Positioned(
                    top: _headerHeight + _featuredHeight - _overlapAmount,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: _overlapAmount + 50, // Extra height for visual
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                    ),
                  ),

                  // Dark content (Header + Featured) - on top
                  Column(
                    children: [
                      _buildHeader(context),
                      _buildFeaturedSection(),
                    ],
                  ),
                ],
              ),

              // White Content Section (continues from overlap)
              Container(
                width: double.infinity,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModulesSection(),
                      const SizedBox(height: 24),
                      _buildRecentActivity(),
                      const SizedBox(height: 100),
                    ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          // Profile Avatar
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withAlpha(50),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withAlpha(180),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Admin User',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Settings
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    final featuredModules = _featuredModuleIds
        .map((id) => HrisModules.getById(id))
        .whereType<ModuleItem>()
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha(200),
            ),
          ),
          const SizedBox(height: 14),

          // Featured Cards Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Large Card (first module)
              Expanded(
                flex: 5,
                child: _buildLargeFeaturedCard(
                  featuredModules.isNotEmpty ? featuredModules[0] : null,
                ),
              ),
              const SizedBox(width: 12),
              // Right Column (2 smaller cards + CUSTOMIZE button)
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildSmallFeaturedCard(
                      featuredModules.length > 1 ? featuredModules[1] : null,
                    ),
                    const SizedBox(height: 10),
                    _buildSmallFeaturedCard(
                      featuredModules.length > 2 ? featuredModules[2] : null,
                    ),
                    const SizedBox(height: 10),
                    // CUSTOMIZE Button - in same column
                    _buildCustomizeButton(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Space before white section - compact
        ],
      ),
    );
  }

  Widget _buildCustomizeButton() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push<List<String>>(
          MaterialPageRoute(
            builder: (_) => EditFeaturedScreen(
              currentFeaturedIds: _featuredModuleIds,
            ),
          ),
        );
        if (result != null) {
          setState(() {
            _featuredModuleIds = result;
          });
        }
      },
      child: Container(
        width: double.infinity,
        height: 42, // Height to align bottom with large card
        decoration: BoxDecoration(
          color: const Color.fromARGB(81, 82, 82, 82).withAlpha(100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color.fromARGB(255, 255, 255, 255).withAlpha(100)),
        ),
        child: const Center(
          child: Text(
            'CUSTOMIZE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 255, 255, 255),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeFeaturedCard(ModuleItem? module) {
    if (module == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _onModuleTap(module),
      child: Container(
        height: 222,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: module.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: module.color.withAlpha(60),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(module.icon, color: Colors.white, size: 24),
            ),
            const Spacer(),
            Text(
              module.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to open',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallFeaturedCard(ModuleItem? module) {
    if (module == null) return const SizedBox(height: 80);

    return GestureDetector(
      onTap: () => _onModuleTap(module),
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: module.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: module.color.withAlpha(60),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(module.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    module.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to open',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withAlpha(160),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesSection() {
    const displayCount = 7;
    final modulesToShow = HrisModules.allModules.take(displayCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modules',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Module Grid (4 columns, 2 rows)
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: [
            ...modulesToShow.map((module) => _buildModuleItem(module)),
            _buildMoreItem(),
          ],
        ),
      ],
    );
  }

  Widget _buildModuleItem(ModuleItem module) {
    return GestureDetector(
      onTap: () => _onModuleTap(module),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: module.color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(module.icon, color: module.color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            module.name,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMoreItem() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AllModulesScreen()),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.grid_view_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'More',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          icon: Icons.check_circle_outline,
          title: 'Clocked In',
          subtitle: 'Today at 08:30 AM',
          color: AppColors.success,
        ),
        _buildActivityItem(
          icon: Icons.event_available,
          title: 'Leave Approved',
          subtitle: 'Annual leave on 20 Jan 2026',
          color: AppColors.primary,
        ),
        _buildActivityItem(
          icon: Icons.description_outlined,
          title: 'Payslip Available',
          subtitle: 'December 2025 payslip',
          color: AppColors.info,
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
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
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onModuleTap(ModuleItem module) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${module.name} - Coming soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning! 👋';
    if (hour < 17) return 'Good Afternoon! 👋';
    return 'Good Evening! 👋';
  }
}

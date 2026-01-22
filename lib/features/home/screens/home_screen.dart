import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/core/config/role_menu_config.dart';
import 'package:mobile_app/core/services/auth_state.dart';
import 'package:mobile_app/i18n/translations.dart';
import 'package:mobile_app/features/settings/screens/settings_screen.dart';
import 'package:mobile_app/features/profile/screens/profile_screen.dart';
import 'package:mobile_app/features/home/screens/all_modules_screen.dart';
import 'package:mobile_app/features/home/screens/edit_featured_screen.dart';
import 'package:mobile_app/features/leave/screens/leave_list_screen.dart';

/// Home Screen (Dashboard) - Gojek-style with customizable featured modules
/// Uses RoleMenuConfig for role-based module access
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Featured module IDs (user customizable)
  late List<String> _featuredModuleIds;

  // All accessible modules for current role
  late List<StaffModule> _accessibleModules;

  // Height constants for layout calculation
  static const double _headerHeight = 80;
  static const double _featuredHeight = 300;
  static const double _overlapAmount = 120;

  @override
  void initState() {
    super.initState();
    _featuredModuleIds = List.from(RoleMenuConfig.getDefaultFeaturedIds());
    _accessibleModules = RoleMenuConfig.getAccessibleModules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2D),
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Sticky header
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: const Color(0xFF1E1E2D),
                elevation: 0,
                toolbarHeight: _headerHeight,
                automaticallyImplyLeading: false,
                flexibleSpace: _buildHeader(context),
              ),
            ];
          },
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Stack for overlap effect
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // White background
                    Positioned(
                      top: _featuredHeight - _overlapAmount,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: _overlapAmount + 50,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(28),
                            topRight: Radius.circular(28),
                          ),
                        ),
                      ),
                    ),

                    // Featured section
                    _buildFeaturedSection(),
                  ],
                ),

                // White content section
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildModulesSection(),
                      const SizedBox(height: 20),
                      _buildRecentActivitySection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authState = AuthState();

    return Container(
      height: _headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Profile avatar
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
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.5), width: 2),
              ),
              child: Icon(Icons.person, color: AppColors.primary, size: 24),
            ),
          ),
          const SizedBox(width: 14),

          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withAlpha(180),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  authState.username,
                  style: const TextStyle(
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return t.home.greeting.morning;
    if (hour < 17) return t.home.greeting.afternoon;
    return t.home.greeting.evening;
  }

  Widget _buildFeaturedSection() {
    // Get featured modules from accessible modules
    final featuredModules = _featuredModuleIds
        .map((id) => _accessibleModules.firstWhereOrNull((m) => m.id == id))
        .whereType<StaffModule>()
        .take(3)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.home.quickAccess,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white.withAlpha(200),
            ),
          ),
          const SizedBox(height: 14),

          // Featured cards
          SizedBox(
            height: _featuredHeight - _headerHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Big card (first featured)
                if (featuredModules.isNotEmpty)
                  Expanded(
                    flex: 5,
                    child: _buildBigFeaturedCard(featuredModules[0]),
                  ),

                const SizedBox(width: 12),

                // Small cards column
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      if (featuredModules.length > 1)
                        Expanded(
                            child: _buildSmallFeaturedCard(featuredModules[1])),
                      const SizedBox(height: 12),
                      if (featuredModules.length > 2)
                        Expanded(
                            child: _buildSmallFeaturedCard(featuredModules[2])),
                      const SizedBox(height: 12),
                      // Customize button
                      _buildCustomizeButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigFeaturedCard(StaffModule module) {
    return GestureDetector(
      onTap: () => _onModuleTap(module),
      child: Container(
        decoration: BoxDecoration(
          color: module.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: module.color.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(40),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(module.icon, color: Colors.white, size: 26),
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
              t.common.tapToOpen,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withAlpha(160),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallFeaturedCard(StaffModule module) {
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    module.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.common.tapToOpen,
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
          setState(() => _featuredModuleIds = result);
        }
      },
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF6B7280), // Solid gray for visibility
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dashboard_customize_outlined,
                color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              t.home.customize.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesSection() {
    const displayCount = 7;
    final modulesToShow = _accessibleModules.take(displayCount).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.home.modules,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AllModulesScreen()),
                  );
                },
                child: Text(
                  t.home.viewAll,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Module Grid (4 columns, 2 rows)
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            childAspectRatio: 0.72,
            children: [
              ...modulesToShow.map((module) => _buildModuleItem(module)),
              _buildMoreItem(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModuleItem(StaffModule module) {
    return GestureDetector(
      onTap: () => _onModuleTap(module),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: module.lightColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(module.icon, color: module.color, size: 26),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              module.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.grid_view_rounded,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              'More',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.home.recentActivity,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Empty state
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 40, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    t.common.noData,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onModuleTap(StaffModule module) {
    if (module.id == 'leave') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LeaveListScreen()),
      );
      return;
    }

    if (module.id == 'clock_in' || module.id == 'attendance') {
      // Navigate to Attendance tab (index 2) via MainShell if possible,
      // or push AttendanceScreen directly if independent.
      // Since Home is index 0 and Attendance is index 2 in MainShell:
      // Note: This requires access to MainShell state or a global event bus.
      // For now, pushing the screen directly or assuming MainShell context.

      // OPTION A: Push AttendanceScreen (if it works standalone)
      // Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AttendanceScreen()));

      // OPTION B: Switch Tab (Cleaner if inside MainShell)
      // We can find the MainShell ancestor?
      // For now, let's just show the snackbar for others, BUT 'leave' works.
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(module.icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text('${module.name} - ${t.common.comingSoon}'),
          ],
        ),
        backgroundColor: module.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// Extension for firstWhereOrNull
extension _ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

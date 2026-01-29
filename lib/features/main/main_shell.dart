import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/core/services/attendance_api_service.dart';
import 'package:mobile_app/core/theme/app_colors.dart';

import 'package:mobile_app/features/home/screens/home_screen.dart';
import 'package:mobile_app/features/analytics/screens/analytics_screen.dart';
import 'package:mobile_app/features/attendance/screens/attendance_screen.dart';
import 'package:mobile_app/features/profile/screens/profile_config_screen.dart';

/// Main Shell - Bottom navigation with 4 tabs
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Track which tabs have been visited for lazy loading
  final Set<int> _loadedTabs = {0}; // Home is always loaded

  // Tab screens (built lazily)
  static const List<Widget> _pages = [
    HomeScreen(),
    AnalyticsScreen(),
    AttendanceScreen(),
    ProfileConfigScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Sync attendance locations immediately after login
    _syncAttendanceData();
  }

  /// Sync attendance data on app start (background)
  Future<void> _syncAttendanceData() async {
    try {
      debugPrint('MAIN_SHELL: Syncing attendance locations...');
      // await AttendanceApiService.syncLocations();
      // Optimization: Pre-load status and validation in background
      await AttendanceApiService.preloadData();
      debugPrint('MAIN_SHELL: Sync complete');
    } catch (e) {
      debugPrint('MAIN_SHELL: Sync error: $e');
    }
  }

  /// Build page only if it has been visited
  Widget _buildPage(int index) {
    if (!_loadedTabs.contains(index)) {
      // Return empty placeholder for unvisited tabs
      return const SizedBox.shrink();
    }
    return _pages[index];
  }

  /// Handle tab change with lazy loading
  void _onTabChanged(int index) {
    setState(() {
      _loadedTabs.add(index); // Mark tab as loaded
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If not on home tab, go to home first
        if (_currentIndex != 0) {
          _onTabChanged(0);
          return;
        }

        // Show exit confirmation dialog
        final shouldExit = await _showExitConfirmation();
        if (shouldExit == true && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(_pages.length, _buildPage),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Future<bool?> _showExitConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: AppColors.warning, size: 24),
            const SizedBox(width: 10),
            const Text('Exit App'),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit the application?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics,
                label: 'Analytics',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.access_time_outlined,
                activeIcon: Icons.access_time_filled,
                label: 'Attendance',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isActive ? AppColors.primary.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

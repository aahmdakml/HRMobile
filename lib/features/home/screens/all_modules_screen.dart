import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/core/config/role_menu_config.dart';
import 'package:mobile_app/i18n/translations.dart';

/// All Modules Screen - Shows all available HRIS modules by category
/// Uses RoleMenuConfig to display role-based accessible modules
class AllModulesScreen extends StatelessWidget {
  const AllModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = RoleMenuConfig.getCategorizedModules();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.home.allModules,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...categories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              return Column(
                children: [
                  _buildSection(
                    title: category.name,
                    icon: category.icon,
                    modules: category.modules,
                    context: context,
                  ),
                  if (index < categories.length - 1) const SizedBox(height: 24),
                ],
              );
            }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<StaffModule> modules,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: modules.asMap().entries.map((entry) {
              final index = entry.key;
              final module = entry.value;
              final isLast = index == modules.length - 1;
              final isFirst = index == 0;

              return Column(
                children: [
                  _buildModuleListItem(
                    module,
                    context,
                    isFirst: isFirst,
                    isLast: isLast,
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: AppColors.border,
                      indent: 74,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleListItem(
    StaffModule module,
    BuildContext context, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onModuleTap(module, context),
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(16) : Radius.zero,
          bottom: isLast ? const Radius.circular(16) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Colored icon container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: module.lightColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  module.icon,
                  color: module.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Module info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getModuleDescription(module.id),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getModuleDescription(String moduleId) {
    // TODO: Move to translations when ready
    switch (moduleId) {
      case 'clock_in':
        return 'Clock in/out with GPS';
      case 'leave':
        return 'Request leave & permission';
      case 'permission':
        return 'Request time off permission';
      case 'payslip':
        return 'View monthly payslip';
      case 'overtime':
        return 'Request overtime';
      case 'attendance':
        return 'View attendance history';
      case 'travel_order':
        return 'Travel order documents';
      case 'reimburse':
        return 'Submit reimbursement claims';
      case 'loan':
        return 'View loan status';
      case 'profile':
        return 'View and edit your profile';
      case 'my_info':
        return 'Personal information details';
      case 'approval':
        return 'Approve requests';
      case 'approval_travel':
        return 'Approve travel orders';
      default:
        return 'Tap to open';
    }
  }

  void _onModuleTap(StaffModule module, BuildContext context) {
    // TODO: Navigate to module page when routes are ready
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

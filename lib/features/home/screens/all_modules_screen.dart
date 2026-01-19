import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/core/models/module_item.dart';

/// All Modules Screen - Shows all available HRIS modules
class AllModulesScreen extends StatelessWidget {
  const AllModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'All Modules',
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
            // Main Modules Section
            _buildSection(
              title: 'Attendance',
              modules: [
                HrisModules.getById('clock_in')!,
                HrisModules.getById('attendance')!,
                HrisModules.getById('overtime')!,
              ],
              context: context,
            ),

            const SizedBox(height: 24),

            // Leave Section
            _buildSection(
              title: 'Leave & Permission',
              modules: [HrisModules.getById('leave')!],
              context: context,
            ),

            const SizedBox(height: 24),

            // Finance Section
            _buildSection(
              title: 'Finance',
              modules: [
                HrisModules.getById('payslip')!,
                HrisModules.getById('reimburse')!,
                HrisModules.getById('loan')!,
              ],
              context: context,
            ),

            const SizedBox(height: 24),

            // Travel Section
            _buildSection(
              title: 'Travel',
              modules: [HrisModules.getById('travel')!],
              context: context,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<ModuleItem> modules,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: modules.asMap().entries.map((entry) {
              final index = entry.key;
              final module = entry.value;
              final isLast = index == modules.length - 1;

              return Column(
                children: [
                  _buildModuleListItem(module, context),
                  if (!isLast) Divider(height: 1, color: AppColors.border),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleListItem(ModuleItem module, BuildContext context) {
    return InkWell(
      onTap: () => _onModuleTap(module, context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: module.color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(module.icon, color: module.color, size: 24),
            ),
            const SizedBox(width: 14),
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
            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  String _getModuleDescription(String moduleId) {
    switch (moduleId) {
      case 'clock_in':
        return 'Clock in/out with GPS';
      case 'leave':
        return 'Request leave & permission';
      case 'payslip':
        return 'View monthly payslip';
      case 'overtime':
        return 'Request overtime';
      case 'attendance':
        return 'View attendance history';
      case 'travel':
        return 'Travel order documents';
      case 'reimburse':
        return 'Submit reimbursement claims';
      case 'loan':
        return 'View loan status';
      default:
        return '';
    }
  }

  void _onModuleTap(ModuleItem module, BuildContext context) {
    // TODO: Navigate to module page when ready
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${module.name} - Coming soon'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

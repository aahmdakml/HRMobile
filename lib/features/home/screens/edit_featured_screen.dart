import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/core/config/role_menu_config.dart';
import 'package:mobile_app/i18n/translations.dart';

/// Edit Featured Screen - Customize quick access modules
/// Uses RoleMenuConfig for accessible modules
class EditFeaturedScreen extends StatefulWidget {
  final List<String> currentFeaturedIds;

  const EditFeaturedScreen({super.key, required this.currentFeaturedIds});

  @override
  State<EditFeaturedScreen> createState() => _EditFeaturedScreenState();
}

class _EditFeaturedScreenState extends State<EditFeaturedScreen> {
  late List<String> _selectedIds;
  late List<StaffModule> _accessibleModules;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.currentFeaturedIds);
    _accessibleModules = RoleMenuConfig.getAccessibleModules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit ${t.home.quickAccess}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _canSave ? _saveAndClose : null,
            child: Text(
              t.common.save,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _canSave ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.info.withAlpha(20),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select 3 modules for quick access on your dashboard',
                    style: TextStyle(fontSize: 13, color: AppColors.info),
                  ),
                ),
              ],
            ),
          ),

          // Selected Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedIds.length == 3
                        ? AppColors.success.withAlpha(20)
                        : AppColors.warning.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_selectedIds.length} / 3',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedIds.length == 3
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Module List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _accessibleModules.length,
              itemBuilder: (context, index) {
                final module = _accessibleModules[index];
                final isSelected = _selectedIds.contains(module.id);
                final canSelect = _selectedIds.length < 3 || isSelected;

                return _buildModuleItem(module, isSelected, canSelect);
              },
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSave => _selectedIds.length == 3;

  Widget _buildModuleItem(StaffModule module, bool isSelected, bool canSelect) {
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          setState(() {
            _selectedIds.remove(module.id);
          });
        } else if (canSelect) {
          setState(() {
            _selectedIds.add(module.id);
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Module Icon with unique color
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: module.lightColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(module.icon, color: module.color, size: 24),
            ),
            const SizedBox(width: 14),

            // Module Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: canSelect || isSelected
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Position ${_selectedIds.indexOf(module.id) + 1}',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ],
                ],
              ),
            ),

            // Selection Indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _saveAndClose() {
    Navigator.pop(context, _selectedIds);
  }
}

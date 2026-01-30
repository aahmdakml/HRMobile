import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/features/leave/models/leave_model.dart';

class SearchableTypeSheet extends StatefulWidget {
  final List<TimeoffCompany> options;
  final String? selectedCode;

  const SearchableTypeSheet({
    super.key,
    required this.options,
    this.selectedCode,
  });

  @override
  State<SearchableTypeSheet> createState() => _SearchableTypeSheetState();
}

class _SearchableTypeSheetState extends State<SearchableTypeSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<TimeoffCompany> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterOptions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options
            .where((type) =>
                (type.name ?? type.code)
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                type.code.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // Slightly taller
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)), // Sharper definition
      ),
      child: Column(
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Leave Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E1E2D), // Deep Blue Text
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6), // Match app input bg
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterOptions,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Search leave types...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  isDense: true,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),

          // List
          Expanded(
            child: _filteredOptions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No leave types found',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredOptions.length,
                    itemBuilder: (context, index) {
                      final type = _filteredOptions[index];
                      final isSelected = type.code == widget.selectedCode;

                      return InkWell(
                        onTap: () => Navigator.pop(context, type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.04)
                              : Colors.transparent,
                          child: Row(
                            children: [
                              // Text Info
                              Expanded(
                                child: Text(
                                  type.name ?? type.code,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : const Color(0xFF1E1E2D),
                                  ),
                                ),
                              ),

                              // Checkmark
                              if (isSelected)
                                const Icon(Icons.check_circle,
                                    color: AppColors.primary, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

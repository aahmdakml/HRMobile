import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_app/features/permission/providers/permission_provider.dart';
import 'package:mobile_app/features/permission/screens/permission_filter_modal.dart';
import 'package:mobile_app/features/permission/widgets/permission_card.dart';
import 'package:mobile_app/features/leave/widgets/leave_skeleton_widgets.dart'; // Reuse skeletons

class PermissionHistoryScreen extends ConsumerWidget {
  const PermissionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionState = ref.watch(permissionListProvider);

    return Scaffold(
        backgroundColor: const Color(0xFFF5F5FA),
        appBar: AppBar(
          title: const Text('Permission History',
              style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // Refresh
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blueGrey),
              onPressed: () =>
                  ref.read(permissionListProvider.notifier).refresh(),
            ),
            // Filter
            Consumer(
              builder: (context, ref, child) {
                final filterState = ref.watch(permissionFilterProvider);
                final count = filterState.activeFilterCount;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.filter_list, color: Colors.blueGrey),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const PermissionFilterModal(),
                        );
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: permissionState.when(
          data: (data) {
            if (data.permissions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No history found',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(permissionListProvider.notifier).refresh(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: data.permissions.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return PermissionCard(permission: data.permissions[index]);
                },
              ),
            );
          },
          loading: () => const SkeletonLeaveList(), // Reuse Leave Skeleton
          error: (err, stack) => Center(child: Text('Error: $err')),
        ));
  }
}

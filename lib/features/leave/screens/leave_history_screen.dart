import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/leave/providers/leave_provider.dart';
import 'package:mobile_app/features/leave/widgets/leave_skeleton_widgets.dart';
import 'package:mobile_app/features/leave/widgets/leave_card.dart';
import 'package:mobile_app/features/leave/screens/leave_filter_modal.dart';

class LeaveHistoryScreen extends ConsumerWidget {
  const LeaveHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaveState = ref.watch(leaveListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        title: const Text('Leave History',
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
          Consumer(
            builder: (context, ref, child) {
              final filterState = ref.watch(leaveFilterProvider);
              final count = filterState.activeFilterCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.black),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const LeaveFilterModal(),
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
      body: leaveState.when(
        data: (data) {
          if (data.leaves.isEmpty) {
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
            onRefresh: () => ref.read(leaveListProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: data.leaves.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return LeaveCard(leave: data.leaves[index]);
              },
            ),
          );
        },
        loading: () => const SkeletonLeaveList(),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

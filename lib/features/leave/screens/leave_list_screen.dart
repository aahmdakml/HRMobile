import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/features/leave/models/leave_model.dart';
import 'package:mobile_app/features/leave/providers/leave_provider.dart';
import 'package:mobile_app/features/leave/screens/leave_form_screen.dart';

class LeaveListScreen extends ConsumerWidget {
  const LeaveListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaveState = ref.watch(leaveListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2D), // Deep Blue Background
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: const Color(0xFF1E1E2D),
                elevation: 0,
                centerTitle: true,
                title: const Text(
                  'My Leaves',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () =>
                        ref.read(leaveListProvider.notifier).refresh(),
                  ),
                ],
              ),
            ];
          },
          body: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: leaveState.when(
                data: (state) => CustomScrollView(
                  slivers: [
                    // Balance Cards (Horizontal)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Leave Balance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildBalanceSection(ref, state.balances),
                          ],
                        ),
                      ),
                    ),

                    // History Title
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),

                    // History List
                    state.leaves.isEmpty
                        ? const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.history,
                                      size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text('No leave history found',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _LeaveCard(leave: state.leaves[index]),
                              childCount: state.leaves.length > 3
                                  ? 3
                                  : state.leaves.length,
                            ),
                          ),

                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load data',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          err.toString().length > 100
                              ? '${err.toString().substring(0, 100)}...'
                              : err.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.read(leaveListProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeaveFormScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Request',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBalanceSection(WidgetRef ref, List<LeaveBalance> balances) {
    if (balances.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text('No balance data available',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref.read(leaveListProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Refresh'),
            ),
            const Text(
              '(Check DB: LeaveBalance table)',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 120, // Increased height slightly
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: balances.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final balance = balances[index];
          // Vibrant Gradients
          final List<Color> gradientColors = index % 2 == 0
              ? [const Color(0xFF6366F1), const Color(0xFF818CF8)] // Indigo
              : [const Color(0xFFEC4899), const Color(0xFFF472B6)]; // Pink

          return Container(
            width: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Year ${balance.year}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${balance.remaining}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Days Remaining',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveModel leave;

  const _LeaveCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Box with translucent background (Vibrant Touch)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _getTypeColor(leave.timeoffCode).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_getTypeIcon(leave.timeoffCode),
                          color: _getTypeColor(leave.timeoffCode), size: 26),
                    ),
                    const SizedBox(width: 16),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.timeOffType?.name ?? leave.timeoffCode,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700, // Bolder
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${_formatDate(leave.dateStart)} - ${_formatDate(leave.dateEnd)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Duration Badge (Neutral)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        '${leave.totalDays} Days',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status & Description
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            _getStatusBgColor(leave.statusName ?? leave.status),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        leave.statusName ?? leave.status,
                        style: TextStyle(
                          color:
                              _getStatusColor(leave.statusName ?? leave.status),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (leave.description.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          leave.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _getTypeColor(String code) {
    final lowerCode = code.toLowerCase();
    if (lowerCode.contains('sick') || lowerCode.contains('sakit')) {
      return const Color(0xFFEF4444); // Red
    } else if (lowerCode.contains('annual') ||
        lowerCode.contains('tahunan') ||
        lowerCode.contains('cuti')) {
      return const Color(0xFF6366F1); // Indigo
    } else if (lowerCode.contains('permission') || lowerCode.contains('izin')) {
      return const Color(0xFFF59E0B); // Amber
    } else if (lowerCode.contains('maternity') ||
        lowerCode.contains('melahirkan')) {
      return const Color(0xFFEC4899); // Pink
    }
    return const Color(0xFF3B82F6); // Blue (Default)
  }

  IconData _getTypeIcon(String code) {
    final lowerCode = code.toLowerCase();
    if (lowerCode.contains('sick') || lowerCode.contains('sakit')) {
      return Icons.medication_outlined;
    } else if (lowerCode.contains('annual') || lowerCode.contains('tahunan')) {
      return Icons.beach_access_outlined;
    } else if (lowerCode.contains('permission') || lowerCode.contains('izin')) {
      return Icons.assignment_outlined;
    }
    return Icons.work_history_outlined;
  }

  Color _getStatusColor(String status) {
    if (status.toUpperCase() == 'APPROVED' ||
        status.toUpperCase() == 'DISETUJUI') {
      return const Color(0xFF10B981); // Green
    } else if (status.toUpperCase() == 'REJECTED' ||
        status.toUpperCase() == 'DITOLAK') {
      return const Color(0xFFEF4444); // Red
    }
    return const Color(0xFFF59E0B); // Amber (Waiting)
  }

  Color _getStatusBgColor(String status) {
    return _getStatusColor(status).withOpacity(0.1);
  }
}

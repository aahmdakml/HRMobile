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
                data: (state) {
                  // Calculate Balances
                  final currentYear = DateTime.now().year;
                  final lastYear = currentYear - 1;

                  final currentBalance = state.balances
                      .firstWhere((b) => b.year == currentYear,
                          orElse: () =>
                              LeaveBalance(year: currentYear, remaining: 0))
                      .remaining;

                  final lastBalance = state.balances
                      .firstWhere((b) => b.year == lastYear,
                          orElse: () =>
                              LeaveBalance(year: lastYear, remaining: 0))
                      .remaining;

                  final totalBalance = currentBalance + lastBalance;

                  // Constants for layout (matching HomeScreen but refined for Leave)
                  const double cardHeight = 180; // Reduced to 180
                  const double overlapAmount = 80; // Reduced to 80

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 1. White Background Container (starts mid-way)
                            Positioned(
                              top: cardHeight - overlapAmount,
                              left: 0,
                              right: 0,
                              bottom: 0, // Extend to bottom of stack
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(30),
                                    topRight: Radius.circular(30),
                                  ),
                                ),
                              ),
                            ),

                            // 2. Content
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  const SizedBox(
                                      height: 10), // Space from AppBar

                                  // --- MAIN SUMMARY CARD (Purple Gradient) ---
                                  Container(
                                    height: cardHeight,
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical:
                                            18), // Reduced vertical padding to fix overflow
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFA855F7), // Purple
                                          Color(0xFF7C3AED), // Darker Violet
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFA855F7)
                                              .withOpacity(0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Total Balance',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.8),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '$totalBalance Days',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: -1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                  Icons.flight_takeoff,
                                                  color: Colors.white,
                                                  size: 24),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),

                                        // Divider
                                        Divider(
                                            color:
                                                Colors.white.withOpacity(0.2)),
                                        const SizedBox(height: 12),

                                        // Breakdown Row
                                        Row(
                                          children: [
                                            // Last Year
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: const Icon(
                                                        Icons.history,
                                                        color: Colors.white,
                                                        size: 16),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Last Year',
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(0.7),
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      Text(
                                                        '$lastBalance',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Vertical Divider
                                            Container(
                                              width: 1,
                                              height: 30,
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                            ),
                                            const SizedBox(width: 16),
                                            // Current Year
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: const Icon(
                                                        Icons
                                                            .calendar_today_outlined,
                                                        color: Colors.white,
                                                        size: 16),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'This Year',
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(0.7),
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      Text(
                                                        '$currentBalance',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // --- WHITE BODY SECTION ---
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),

                              // Action Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const LeaveFormScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text('New Leave Request'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF3F4F6),
                                    foregroundColor: AppColors.primary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // History Title
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent History',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text('View All'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12), // Increased spacing

                              // History List
                              if (state.leaves.isEmpty)
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 40),
                                  alignment: Alignment.center,
                                  child: Column(
                                    children: [
                                      Icon(Icons.history,
                                          size: 48,
                                          color: Colors.grey.shade300),
                                      const SizedBox(height: 12),
                                      Text('No leave history found',
                                          style: TextStyle(
                                              color: Colors.grey.shade500)),
                                    ],
                                  ),
                                )
                              else
                                ...state.leaves.map((leave) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom:
                                              16), // Increased spacing between cards
                                      child: _LeaveCard(leave: leave),
                                    )),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
                    const SizedBox(width: 12),
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

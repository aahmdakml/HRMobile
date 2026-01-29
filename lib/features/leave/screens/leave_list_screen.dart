import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/features/leave/models/leave_model.dart';
import 'package:mobile_app/features/leave/providers/leave_provider.dart';
import 'package:mobile_app/features/leave/screens/leave_form_screen.dart';
import 'package:mobile_app/features/leave/widgets/leave_skeleton_widgets.dart';
import 'package:mobile_app/features/leave/widgets/leave_card.dart';
import 'package:mobile_app/features/leave/screens/leave_history_screen.dart';

class LeaveListScreen extends ConsumerStatefulWidget {
  const LeaveListScreen({super.key});

  @override
  ConsumerState<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends ConsumerState<LeaveListScreen> {
  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(recentLeavesProvider);

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
                        ref.read(recentLeavesProvider.notifier).refresh(),
                  ),
                ],
              ),
            ];
          },
          body: leaveState.when(
            data: (state) {
              // Fallback for types if stateData is unexpectedly null (should rely on above checks)
              // Since we are in data state, 'state' is guaranteed valid relative to 'when', but we want to follow logic.

              // Calculate Balances
              final currentYear = DateTime.now().year;
              final lastYear = currentYear - 1;

              debugPrint(
                  'LEAVE_LIST: Balances available: ${state.balances.length}');
              for (var b in state.balances) {
                debugPrint(
                    'LEAVE_LIST: Balance Year: ${b.year}, Remaining: ${b.remaining}, Exp: ${b.expiredDate}');
              }

              final currentBalance = state.balances
                  .firstWhere((b) => b.year == currentYear,
                      orElse: () =>
                          LeaveBalance(year: currentYear, remaining: 0))
                  .remaining;

              final lastBalanceObj = state.balances.firstWhere(
                  (b) => b.year == lastYear,
                  orElse: () => LeaveBalance(year: lastYear, remaining: 0));

              final lastBalance = lastBalanceObj.remaining;

              // Check if last year balance is expired
              final isLastExpired = lastBalanceObj.expiredDate != null &&
                  lastBalanceObj.expiredDate!.isBefore(DateTime.now());

              // Only add last year balance if NOT expired
              final totalBalance =
                  currentBalance + (isLastExpired ? 0 : lastBalance);

              // Constants for layout
              const double cardHeight = 220;

              return Container(
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
                  child: Builder(
                    builder: (context) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // 1. White Background Container
                                // Implicitly provided by parent Container

                                // 2. The Main Balance Card (Purple) with Gradient
                                Container(
                                  height: cardHeight,
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  margin: const EdgeInsets.only(
                                      left: 20, right: 20, top: 20),
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
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
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
                                              if (leaveState.isLoading)
                                                const SkeletonBalanceText()
                                              else
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
                                              color:
                                                  Colors.white.withOpacity(0.2),
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
                                          color: Colors.white.withOpacity(0.2)),
                                      const SizedBox(height: 12),

                                      // Breakdown Row
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Last Year
                                          Expanded(
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                      size: 28),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
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
                                                      if (leaveState.isLoading)
                                                        const SkeletonBalanceNumber()
                                                      else
                                                        Text(
                                                          '$lastBalance',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Valid until:',
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(0.6),
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      Text(
                                                        _formatExpiry(
                                                            state.balances
                                                                .where((b) =>
                                                                    b.year ==
                                                                    lastYear)
                                                                .firstOrNull
                                                                ?.expiredDate,
                                                            currentYear - 1),
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(0.9),
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
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
                                            margin:
                                                const EdgeInsets.only(top: 8),
                                          ),
                                          const SizedBox(width: 16),
                                          // Current Year
                                          Expanded(
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                      size: 28),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
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
                                                      if (leaveState.isLoading)
                                                        const SkeletonBalanceNumber()
                                                      else
                                                        Text(
                                                          '$currentBalance',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Valid until:',
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(0.6),
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      Text(
                                                        _formatExpiry(
                                                            state.balances
                                                                .where((b) =>
                                                                    b.year ==
                                                                    currentYear)
                                                                .firstOrNull
                                                                ?.expiredDate,
                                                            currentYear),
                                                        style: TextStyle(
                                                          color: Colors.white
                                                              .withOpacity(0.9),
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
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

                            // --- WHITE BODY SECTION ---
                            Container(
                              color: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),

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
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      label: const Text('New Leave Request'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFF3F4F6),
                                        foregroundColor: AppColors.primary,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // History Title
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Recent History',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const LeaveHistoryScreen()),
                                          );
                                        },
                                        child: const Text('View All',
                                            style: TextStyle(fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // LOADING STATE FOR LIST
                                  if (leaveState.isLoading)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 20),
                                      child: SkeletonLeaveList(),
                                    )
                                  // History List (Empty)
                                  else if (state.leaves.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 40),
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
                                  // History List (Items)
                                  else
                                    ...state.leaves
                                        .take(3)
                                        .map((leave) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 10),
                                              child: LeaveCard(leave: leave),
                                            )),
                                  const SizedBox(height: 40),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
            loading: () => const SkeletonLeaveScreen(),
            error: (error, stack) => _buildErrorWidget(error, ref),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object? error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
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
              error.toString().length > 100
                  ? '${error.toString().substring(0, 100)}...'
                  : error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(recentLeavesProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatExpiry(DateTime? date, int year) {
    if (date != null) {
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
    return '-'; // Better fallback than 'loading'
  }
}

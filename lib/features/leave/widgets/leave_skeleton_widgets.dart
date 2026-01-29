import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLeaveItem extends StatelessWidget {
  const SkeletonLeaveItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 40,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 6),
                    ),
                    Container(
                      width: 150,
                      height: 12,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 4),
                    ),
                    Container(
                      width: 80,
                      height: 12,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SkeletonLeaveList extends StatelessWidget {
  const SkeletonLeaveList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: SkeletonLeaveItem(),
        ),
      ),
    );
  }
}

class SkeletonLeaveForm extends StatelessWidget {
  const SkeletonLeaveForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stepper Header Mockup
            Row(
              children: [
                Expanded(
                  child: Container(height: 40, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(height: 40, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(height: 40, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Form Fields
            _buildFieldSkeleton(width: 120),
            const SizedBox(height: 10),
            _buildInputSkeleton(),
            const SizedBox(height: 24),

            _buildFieldSkeleton(width: 100),
            const SizedBox(height: 10),
            _buildInputSkeleton(height: 50),
            const SizedBox(height: 24),

            _buildFieldSkeleton(width: 150),
            const SizedBox(height: 10),
            _buildInputSkeleton(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldSkeleton({required double width}) {
    return Container(
      width: width,
      height: 16,
      color: Colors.white,
    );
  }

  Widget _buildInputSkeleton({double height = 56}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class SkeletonApprovalTimeline extends StatelessWidget {
  const SkeletonApprovalTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBase(width: 100, height: 14), // Title "Approval Flow"
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3, // Mock 3 items
            itemBuilder: (context, index) {
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline Line & Dot
                    Column(
                      children: [
                        const SkeletonBase(
                          width: 20,
                          height: 20,
                          borderRadius: 10,
                        ),
                        if (index != 2)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: Colors.white,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            const SkeletonBase(
                              width: 36,
                              height: 36,
                              borderRadius: 18,
                            ),
                            const SizedBox(width: 12),
                            // Text Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SkeletonBase(width: 120, height: 14),
                                  const SizedBox(height: 6),
                                  const SkeletonBase(
                                      width: 80, height: 12, borderRadius: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SkeletonBase extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBase({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonBalanceText extends StatelessWidget {
  const SkeletonBalanceText({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.5),
      highlightColor: Colors.white.withOpacity(0.2),
      child: Container(
        width: 120,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class SkeletonBalanceNumber extends StatelessWidget {
  const SkeletonBalanceNumber({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.5),
      highlightColor: Colors.white.withOpacity(0.2),
      child: Container(
        width: 40,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class SkeletonLeaveScreen extends StatelessWidget {
  const SkeletonLeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Balance Card Skeleton
              Container(
                height: 220,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              width: 100, height: 20, color: Colors.white),
                          const CircleAvatar(
                              radius: 20, backgroundColor: Colors.white),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                            width: 60, height: 40, color: Colors.white),
                      ),
                      const Spacer(),
                      Container(
                          width: double.infinity,
                          height: 1,
                          color: Colors.white),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child:
                                  Container(height: 40, color: Colors.white)),
                          const SizedBox(width: 20),
                          Expanded(
                              child:
                                  Container(height: 40, color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // List Skeleton
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SkeletonLeaveList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

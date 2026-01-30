import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/features/leave/models/leave_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_app/core/config/app_config.dart';

class ApprovalTimelineWidget extends StatelessWidget {
  final List<LeaveApproval> approvalHistory;
  final String currentStatus;

  const ApprovalTimelineWidget({
    super.key,
    required this.approvalHistory,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (approvalHistory.isEmpty) return const SizedBox.shrink();

    // Sort by order to ensure correct timeline flow (1 -> 2 -> 3)
    final sortedHistory = List<LeaveApproval>.from(approvalHistory)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Approval Flow',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedHistory.length,
          itemBuilder: (context, index) {
            final item = sortedHistory[index];
            final isLast = index == sortedHistory.length - 1;

            return _buildTimelineItem(context, item, isLast);
          },
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
      BuildContext context, LeaveApproval item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line & Dot
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getStatusColor(item.status),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor(item.status).withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ]),
                child: Center(
                  child: Icon(
                    _getStatusIcon(item.status),
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade200,
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: item.approverImage != null &&
                              item.approverImage!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _getAvatarUrl(item.approverImage!),
                              fit: BoxFit.cover,
                              width: 36,
                              height: 36,
                              placeholder: (context, url) => Center(
                                child: Text(
                                  (item.approverName.isNotEmpty
                                          ? item.approverName[0]
                                          : '?')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  (item.approverName.isNotEmpty
                                          ? item.approverName[0]
                                          : '?')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                (item.approverName.isNotEmpty
                                        ? item.approverName[0]
                                        : '?')
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.approverName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                _getStatusColor(item.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.statusName.isNotEmpty
                                ? item.statusName
                                : item.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(item.status),
                            ),
                          ),
                        ),
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
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      case 'WAITING_APPROVAL':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return Icons.check;
      case 'REJECTED':
        return Icons.close;
      case 'WAITING_APPROVAL':
        return Icons.access_time;
      default:
        return Icons.question_mark;
    }
  }

  String _getAvatarUrl(String path) {
    if (path.startsWith('http')) return path;
    final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api/v1', '');
    final cleanBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;

    // Check if path already contains 'storage'
    if (cleanPath.startsWith('storage/')) {
      return '$cleanBase$cleanPath';
    }
    return '${cleanBase}storage/$cleanPath';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/core/config/app_config.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/features/leave/models/leave_model.dart';
import 'package:mobile_app/features/leave/providers/leave_provider.dart';
import 'package:mobile_app/features/leave/services/leave_service.dart';
import 'package:mobile_app/features/leave/widgets/action_success_dialog.dart';
import 'package:mobile_app/features/leave/widgets/approval_timeline_widget.dart';
import 'package:mobile_app/features/leave/widgets/attachment_thumbnail.dart';
import 'package:mobile_app/features/leave/widgets/leave_skeleton_widgets.dart';

class LeaveDetailModal extends StatefulWidget {
  final LeaveModel leave;
  final WidgetRef ref;

  const LeaveDetailModal({super.key, required this.leave, required this.ref});

  @override
  State<LeaveDetailModal> createState() => _LeaveDetailModalState();
}

class _LeaveDetailModalState extends State<LeaveDetailModal> {
  bool _isDeleting = false;
  LeaveModel? _fullLeave;
  bool _isLoadingDetail = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final detail = await LeaveService.getLeaveDetail(widget.leave.id);
      print('LEAVE_DETAIL_Fetched_URLs: ${detail.attachmentUrls}');
      if (mounted) {
        setState(() {
          _fullLeave = detail;
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
      print('Error fetching detail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final leave = _fullLeave ?? widget.leave;
    final isUnapproved = leave.status == 'WAITING_APPROVAL';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Leave Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.category, 'Type',
              leave.timeOffType?.name ?? leave.timeoffCode),
          _buildDetailRow(Icons.calendar_today, 'Date',
              '${_formatDate(leave.dateStart)} - ${_formatDate(leave.dateEnd)} (${leave.totalDays} Days)'),
          if (leave.description.isNotEmpty)
            _buildDetailRow(Icons.description, 'Reason', leave.description),
          const SizedBox(height: 16),
          const Text(
            'Attachments',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (leave.attachmentUrls.isNotEmpty)
            ...leave.attachmentUrls.map((url) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AttachmentThumbnail(
                  fileName: url.split('/').last,
                  url: _getAttachmentUrl(url),
                  isReadOnly: true,
                ),
              );
            })
          else
            const Text('No attachments',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontStyle: FontStyle.italic)),
          _buildDetailRow(
              Icons.info_outline, 'Status', leave.statusName ?? leave.status,
              color: leave.color),
          if (leave.approvalHistory != null &&
              leave.approvalHistory!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),
            ApprovalTimelineWidget(
              approvalHistory: leave.approvalHistory!,
              currentStatus: leave.status,
            ),
          ] else if (_isLoadingDetail) ...[
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),
            const SkeletonApprovalTimeline(),
          ],
          const SizedBox(height: 24),
          if (isUnapproved)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDeleting
                    ? null
                    : () async {
                        setState(() => _isDeleting = true);
                        try {
                          await widget.ref
                              .read(recentLeavesProvider.notifier)
                              .cancelLeave(leave.id);
                          widget.ref.read(leaveListProvider.notifier).refresh();
                          if (mounted) {
                            Navigator.pop(context); // Close Modal
                            showDialog(
                              context: context,
                              builder: (context) => ActionSuccessDialog(
                                title: 'Request Deleted',
                                message:
                                    'Your leave request has been successfully deleted.',
                                onOk: () => Navigator.pop(context),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isDeleting = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Failed to delete: $e'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.delete_outline),
                label: Text(_isDeleting ? 'Deleting...' : 'Delete Request'),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: color ?? AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
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

  String _getAttachmentUrl(String path) {
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

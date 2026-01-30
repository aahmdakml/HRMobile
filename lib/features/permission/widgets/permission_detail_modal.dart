import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/config/app_config.dart';
import 'package:mobile_app/core/theme/app_colors.dart';
import 'package:mobile_app/features/leave/widgets/attachment_thumbnail.dart';
import 'package:mobile_app/features/leave/widgets/leave_skeleton_widgets.dart';
import 'package:mobile_app/features/permission/models/permission_model.dart';
import 'package:mobile_app/features/permission/providers/permission_provider.dart';
import 'package:mobile_app/features/permission/services/permission_service.dart';
import 'package:mobile_app/features/permission/widgets/permission_approval_timeline_widget.dart';

class PermissionDetailModal extends ConsumerStatefulWidget {
  final PermissionModel permission;
  final WidgetRef ref;

  const PermissionDetailModal(
      {super.key, required this.permission, required this.ref});

  @override
  ConsumerState<PermissionDetailModal> createState() =>
      _PermissionDetailModalState();
}

class _PermissionDetailModalState extends ConsumerState<PermissionDetailModal> {
  bool _isDeleting = false;
  PermissionModel? _fullPermission;
  bool _isLoadingDetail = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final detail =
          await PermissionService.getPermissionDetail(widget.permission.id);
      debugPrint(
          'PERMISSION_MODAL: Fetched detail. Approvals: ${detail.approvalHistory?.length}');

      if (mounted) {
        setState(() {
          _fullPermission = detail;
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDetail = false);
      }
      debugPrint('Error fetching permission detail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final permission = _fullPermission ?? widget.permission;
    final isUnapproved = permission.status == 'WAITING_APPROVAL';

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
                'Permission Detail',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.tag,
            'Request ID',
            permission.id,
          ),
          _buildDetailRow(
            Icons.category_outlined,
            'Type',
            permission.timeOffType?.name ?? permission.timeoffCode ?? '-',
          ),
          _buildDetailRow(
            Icons.calendar_today_outlined,
            'Date',
            permission.date != null
                ? DateFormat('dd MMMM yyyy').format(permission.date!)
                : '-',
          ),
          if (permission.timeStart != null)
            _buildDetailRow(
              Icons.schedule_outlined,
              'Time',
              '${permission.timeStart} - ${permission.timeEnd ?? "?"} (${permission.totalHour} hrs)',
            ),
          if (permission.description.isNotEmpty)
            _buildDetailRow(
              Icons.description_outlined,
              'Description',
              permission.description,
            ),
          const SizedBox(height: 16),
          const Text(
            'Attachments',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (permission.attachmentUrls.isNotEmpty)
            ...permission.attachmentUrls.map((url) {
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
            Icons.info_outline,
            'Status',
            permission.statusName ?? permission.status,
            color: _getStatusColor(permission.status),
          ),
          if (permission.approvalHistory != null &&
              permission.approvalHistory!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),
            PermissionApprovalTimelineWidget(
              approvalHistory: permission.approvalHistory!,
            ),
          ] else if (_isLoadingDetail) ...[
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),
            const SkeletonApprovalTimeline(),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No approval history available.',
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (isUnapproved)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDeleting ? null : _handleCancel,
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
                label: Text(_isDeleting ? 'Cancelling...' : 'Cancel Request'),
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
                    color: color ?? const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'WAITING_APPROVAL':
        return Colors.orange;
      case 'CANCELED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
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

  void _showAlert({
    required String title,
    required String message,
    bool isError = false,
    VoidCallback? onOk,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError ? Colors.red : AppColors.primary,
            ),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              onOk?.call();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancel() async {
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Permission?'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await ref
            .read(recentPermissionsProvider.notifier)
            .cancelPermission(widget.permission.id);
        ref
            .read(permissionListProvider.notifier)
            .refresh(); // Update history too
        if (mounted) {
          Navigator.pop(context); // Close modal first

          if (mounted) {
            _showAlert(
              title: 'Success',
              message: 'Permission request cancelled successfully',
              // No onOk needed as we already popped
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          _showAlert(
              title: 'Error', message: 'Failed to cancel: $e', isError: true);
        }
      }
    }
  }
}

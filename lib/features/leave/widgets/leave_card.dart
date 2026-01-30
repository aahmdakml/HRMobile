import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/leave/models/leave_model.dart';
import 'package:mobile_app/features/leave/widgets/leave_detail_modal.dart';

class LeaveCard extends ConsumerWidget {
  final LeaveModel leave;

  const LeaveCard({super.key, required this.leave});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => LeaveDetailModal(leave: leave, ref: ref),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: No Surat & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'No. ${leave.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            _getStatusBgColor(leave.statusName ?? leave.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        leave.statusName ?? leave.status,
                        style: TextStyle(
                          color:
                              _getStatusColor(leave.statusName ?? leave.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    height: 1,
                    color: Colors.grey.shade100,
                  ),
                ),
                // Body: Icon & Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Box
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                            _getTypeColor(leave.timeoffCode).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          _getTypeIcon(leave.timeoffCode),
                          color: _getTypeColor(leave.timeoffCode),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.timeOffType?.name ?? leave.timeoffCode,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${_formatDate(leave.dateStart)} - ${_formatDate(leave.dateEnd)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 14, color: Colors.grey.shade500),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${leave.totalDays} Days',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
      return const Color(0xFFEF4444);
    } else if (lowerCode.contains('annual') ||
        lowerCode.contains('tahunan') ||
        lowerCode.contains('cuti')) {
      return const Color(0xFF6366F1);
    } else if (lowerCode.contains('permission') || lowerCode.contains('izin')) {
      return const Color(0xFFF59E0B);
    } else if (lowerCode.contains('maternity') ||
        lowerCode.contains('melahirkan')) {
      return const Color(0xFFEC4899);
    }
    return const Color(0xFF3B82F6);
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
      return const Color(0xFF10B981);
    } else if (status.toUpperCase() == 'REJECTED' ||
        status.toUpperCase() == 'DITOLAK') {
      return const Color(0xFFEF4444);
    }
    return const Color(0xFFF59E0B);
  }

  Color _getStatusBgColor(String status) {
    return _getStatusColor(status).withOpacity(0.1);
  }
}

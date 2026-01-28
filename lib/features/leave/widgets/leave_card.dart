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
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _getTypeColor(leave.timeoffCode).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getTypeIcon(leave.timeoffCode),
                        color: _getTypeColor(leave.timeoffCode),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            _getStatusBgColor(leave.statusName ?? leave.status),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        leave.statusName ?? leave.status,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _getStatusColor(leave.statusName ?? leave.status),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        leave.timeOffType?.name ?? leave.timeoffCode,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${_formatDate(leave.dateStart)} - ${_formatDate(leave.dateEnd)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${leave.totalDays} Days',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 12, color: Colors.grey.shade300),
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

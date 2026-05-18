import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_spacing.dart';
import '../common/app_empty_state.dart';
import '../common/staggered_list_item.dart';

/// Extracted widget: scrollable list of attendance records with empty-state.
///
/// Receives data via constructor — no direct Firestore access.
class AttendanceHistoryList extends StatelessWidget {
  final List<AttendanceModel> records;
  final Future<void> Function()? onRefresh;
  final UserRole? userRole; // For supervisor-only actions
  final Future<void> Function(AttendanceModel)? onMarkAttendance; // Supervisor action
  final Future<void> Function(String)? onRemoveAttendance; // Supervisor action

  const AttendanceHistoryList({
    super.key,
    required this.records,
    this.onRefresh,
    this.userRole,
    this.onMarkAttendance,
    this.onRemoveAttendance,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return _buildEmptyState();

    final child = ListView.builder(
      padding: EdgeInsets.all(AppSpacing.xl),
      itemCount: records.length,
      itemBuilder: (context, index) => StaggeredListItem(
        index: index,
        child: _buildRecordTile(records[index]),
      ),
    );

    return onRefresh != null
        ? RefreshIndicator(
            onRefresh: onRefresh!,
            color: AppColors.primary,
            child: child,
          )
        : child;
  }

  Widget _buildRecordTile(AttendanceModel record) {
    final isToday = _isToday(record.timestamp);
    final isThisWeek = _isThisWeek(record.timestamp);
    final isSupervisor = userRole != null &&
        (userRole == UserRole.supervisor ||
            userRole == UserRole.manager ||
            userRole == UserRole.coo ||
            userRole == UserRole.director);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          border:
              isToday ? Border.all(color: AppColors.success, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(AppSpacing.md),
          leading: Container(
            padding: EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.success.withValues(alpha: 0.1)
                  : isThisWeek
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.grey300.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              isToday
                  ? Icons.today_rounded
                  : Icons.check_circle_outline_rounded,
              color: isToday
                  ? AppColors.success
                  : isThisWeek
                      ? AppColors.primary
                      : AppColors.textSecondary,
              size: 24,
            ),
          ),
          title: Text(
            DateFormat('EEEE, MMMM d, y').format(record.timestamp),
            style: AppTypography.bodyMediumStyle
                .copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.xs),
              Text(
                DateFormat('h:mm a').format(record.timestamp),
                style: AppTypography.bodyStyle
                    .copyWith(color: AppColors.textSecondary),
              ),
              if (isToday) ...[
                SizedBox(height: AppSpacing.xs),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(AppSpacing.base),
                  ),
                  child: Text(
                    'Today',
                    style: AppTypography.captionStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnPrimary),
                  ),
                ),
              ],
            ],
          ),
          trailing: isSupervisor
              ? PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'remove' && onRemoveAttendance != null) {
                      await onRemoveAttendance!(record.id);
                    }
                    // Verify/Unverify options commented out
                    // else if (value == 'verify' && onMarkAttendance != null) {
                    //   await onMarkAttendance!(record);
                    // }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_rounded,
                              color: AppColors.error, size: 18),
                          SizedBox(width: AppSpacing.sm),
                          const Text('Remove'),
                        ],
                      ),
                    ),
                    // Commented out: Verify/Unverify feature
                    // PopupMenuItem(
                    //   value: 'verify',
                    //   child: Row(
                    //     mainAxisSize: MainAxisSize.min,
                    //     children: [
                    //       Icon(Icons.check_circle_rounded,
                    //           color: AppColors.success, size: 18),
                    //       SizedBox(width: AppSpacing.sm),
                    //       const Text('Verify'),
                    //     ],
                    //   ),
                    // ),
                  ],
                  icon: Icon(Icons.more_vert_rounded,
                      color: AppColors.textSecondary),
                )
              : Text(
                  _getRelativeTime(record.timestamp),
                  style: AppTypography.captionStyle,
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const AppEmptyState(
      icon: Icons.event_busy_rounded,
      title: 'No Attendance Records',
      subtitle: 'Start marking your attendance to see your history here.',
    );
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  static String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }
}

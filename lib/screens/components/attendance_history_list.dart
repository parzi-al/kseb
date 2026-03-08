import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/attendance_model.dart';
import '../../utils/app_colors.dart';

/// Extracted widget: scrollable list of attendance records with empty-state.
///
/// Receives data via constructor — no direct Firestore access.
class AttendanceHistoryList extends StatelessWidget {
  final List<AttendanceModel> records;
  final Future<void> Function()? onRefresh;

  const AttendanceHistoryList({
    super.key,
    required this.records,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return _buildEmptyState();

    final child = ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: records.length,
      itemBuilder: (context, index) => _buildRecordTile(records[index]),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
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
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.success.withValues(alpha: 0.1)
                  : isThisWeek
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.grey300.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                DateFormat('h:mm a').format(record.timestamp),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (isToday) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnDark,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: Text(
            _getRelativeTime(record.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryWithLowOpacity,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy_rounded,
                  size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 32),
            Text(
              'No Attendance Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start marking your attendance to see your history here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
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

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';

/// Displays attendance statistics in a 2x2 grid of cards.
///
/// Receives data via constructor — no direct Firestore access.
/// All values are scoped to the configured fiscal/calendar year.
class AttendanceStatsCard extends StatelessWidget {
  final int thisMonth;
  final int thisYear;
  final bool isMarkedToday;

  const AttendanceStatsCard({
    super.key,
    required this.thisMonth,
    required this.thisYear,
    required this.isMarkedToday,
  });

  @override
  Widget build(BuildContext context) {
    final pct = AttendanceConstants.workingDaysInYear > 0
        ? ((thisYear / AttendanceConstants.workingDaysInYear) * 100)
            .clamp(0.0, 100.0)
            .toStringAsFixed(0)
        : '0';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'This Month',
                '$thisMonth days',
                Icons.calendar_month_rounded,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'This Year',
                '$thisYear days',
                Icons.calendar_today_rounded,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Attendance %',
                '$pct%',
                Icons.percent_rounded,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Status',
                isMarkedToday ? 'Marked' : 'Not Marked',
                Icons.today_rounded,
                isMarkedToday ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

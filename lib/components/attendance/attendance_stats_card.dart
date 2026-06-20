import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_spacing.dart';

/// Displays attendance statistics in a 2x2 grid of cards.
///
/// Receives data via constructor — no direct Firestore access.
/// All values are scoped to the configured fiscal/calendar year.
class AttendanceStatsCard extends StatelessWidget {
  final int thisMonth;
  final int thisYear;
  final bool isMarkedToday;
  final String monthLabel;
  final String yearLabel;

  const AttendanceStatsCard({
    super.key,
    required this.thisMonth,
    required this.thisYear,
    required this.isMarkedToday,
    this.monthLabel = 'This Month',
    this.yearLabel = 'This Year',
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
                monthLabel,
                '$thisMonth days',
                Icons.calendar_month_rounded,
                Colors.blue,
              ),
            ),
            SizedBox(width: AppSpacing.base),
            Expanded(
              child: _buildStatCard(
                yearLabel,
                '$thisYear days',
                Icons.calendar_today_rounded,
                Colors.green,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.base),
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
            SizedBox(width: AppSpacing.base),
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
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
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
            padding: EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(height: AppSpacing.base),
          Text(
            title,
            style: AppTypography.captionStyle,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTypography.bodyMediumStyle
                .copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

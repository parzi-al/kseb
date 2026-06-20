import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_typography.dart';

class AttendanceCalendar extends StatelessWidget {
  const AttendanceCalendar({
    super.key,
    required this.attendanceMap,
    required this.holidays,
    required this.focusedDay,
    this.selectedDay,
    this.onDaySelected,
    this.onPageChanged,
  });

  final Map<DateTime, bool> attendanceMap;
  final Set<DateTime> holidays;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime selectedDay, DateTime focusedDay)? onDaySelected;
  final void Function(DateTime focusedDay)? onPageChanged;

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final days = _visibleMonthDays(focusedDay);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(height: AppSpacing.lg),
          _buildWeekdayHeader(),
          SizedBox(height: AppSpacing.sm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: AppSpacing.xs,
              crossAxisSpacing: AppSpacing.xs,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              if (day == null) return const SizedBox.shrink();
              return _buildDayCell(day);
            },
          ),
          SizedBox(height: AppSpacing.lg),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final canGoPrevious = focusedDay.month > 1;
    final canGoNext = focusedDay.month < 12;

    return Row(
      children: [
        Icon(
          Icons.calendar_month_rounded,
          color: AppColors.primary,
          size: AppTypography.iconSizeLg,
        ),
        SizedBox(width: AppSpacing.base),
        Expanded(
          child: Text(
            '${_monthNames[focusedDay.month - 1]} ${focusedDay.year}',
            style: AppTypography.subheadingStyle,
          ),
        ),
        _navButton(
          icon: Icons.chevron_left_rounded,
          enabled: canGoPrevious,
          onTap: () => _changeMonth(-1),
        ),
        SizedBox(width: AppSpacing.xs),
        _navButton(
          icon: Icons.chevron_right_rounded,
          enabled: canGoNext,
          onTap: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primaryWithLowOpacity : AppColors.grey100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.primary : AppColors.textTertiary,
          size: AppTypography.iconSizeLg,
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    return Row(
      children: [
        for (final weekday in _weekdays)
          Expanded(
            child: Center(
              child: Text(
                weekday,
                style: AppTypography.captionStyle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: weekday == 'Sat' || weekday == 'Sun'
                      ? AppColors.error.withValues(alpha: 0.7)
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDayCell(DateTime day) {
    final isSelected = _isSameDay(selectedDay, day);
    final isToday = _isSameDay(DateTime.now(), day);
    final hasAttendance = _hasAttendance(day);
    final isHoliday = _hasHoliday(day);
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    Color textColor = AppColors.textPrimary;
    Color backgroundColor = Colors.transparent;
    Color borderColor = Colors.transparent;

    if (isSelected) {
      textColor = AppColors.textOnPrimary;
      backgroundColor = AppColors.primary;
    } else if (isToday) {
      textColor = AppColors.primary;
      backgroundColor = AppColors.primary.withValues(alpha: 0.08);
      borderColor = AppColors.primary.withValues(alpha: 0.45);
    } else if (hasAttendance) {
      textColor = AppColors.success;
      backgroundColor = AppColors.success.withValues(alpha: 0.1);
      borderColor = AppColors.success.withValues(alpha: 0.35);
    } else if (isHoliday) {
      textColor = AppColors.warning;
      backgroundColor = AppColors.warning.withValues(alpha: 0.1);
    } else if (isWeekend) {
      textColor = AppColors.error.withValues(alpha: 0.65);
    }

    return InkWell(
      onTap: () => onDaySelected?.call(day, focusedDay),
      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: AppTypography.bodyMediumStyle.copyWith(
                color: textColor,
                fontWeight: isSelected || isToday || hasAttendance
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: hasAttendance ? AppColors.success : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: hasAttendance
                    ? [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.35),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.sm,
        children: [
          _buildLegendItem(color: AppColors.success, label: 'Present'),
          _buildLegendItem(color: AppColors.warning, label: 'Holiday'),
          _buildLegendItem(color: AppColors.primary, label: 'Today'),
          _buildLegendItem(
            color: AppColors.textSecondary,
            label: 'Absent',
            isAbsent: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool isAbsent = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: isAbsent ? Colors.transparent : color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.captionStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _changeMonth(int delta) {
    final next = DateTime(focusedDay.year, focusedDay.month + delta, 1);
    if (next.year != focusedDay.year) return;
    onPageChanged?.call(next);
  }

  List<DateTime?> _visibleMonthDays(DateTime date) {
    final first = DateTime(date.year, date.month, 1);
    final last = DateTime(date.year, date.month + 1, 0);
    final leadingEmptyCells = first.weekday - DateTime.monday;
    final days = <DateTime?>[
      for (var i = 0; i < leadingEmptyCells; i++) null,
      for (var day = 1; day <= last.day; day++)
        DateTime(date.year, date.month, day),
    ];

    while (days.length % 7 != 0) {
      days.add(null);
    }

    return days;
  }

  bool _hasAttendance(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    if (attendanceMap[dateOnly] == true) return true;
    return attendanceMap.keys.any((date) => _isSameDay(date, day));
  }

  bool _hasHoliday(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    if (holidays.contains(dateOnly)) return true;
    return holidays.any((date) => _isSameDay(date, day));
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

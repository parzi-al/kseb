import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_spacing.dart';

/// Extracted calendar widget showing attendance markers and public holidays.
///
/// Receives data via constructor — no direct Firestore access.
class AttendanceCalendar extends StatelessWidget {
  /// Dates on which attendance was marked (normalised to midnight).
  final Map<DateTime, bool> attendanceMap;

  /// Public holiday dates (normalised to midnight).
  final Set<DateTime> holidays;

  /// Currently focused day in the calendar.
  final DateTime focusedDay;

  /// Currently selected day (user tapped).
  final DateTime? selectedDay;

  /// Called when user selects a day.
  final void Function(DateTime selectedDay, DateTime focusedDay)? onDaySelected;

  /// Called when the visible month page changes.
  final void Function(DateTime focusedDay)? onPageChanged;

  const AttendanceCalendar({
    super.key,
    required this.attendanceMap,
    required this.holidays,
    required this.focusedDay,
    this.selectedDay,
    this.onDaySelected,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              SizedBox(width: AppSpacing.base),
              Text(
                'Attendance History',
                style: TextStyle(
                  fontSize: AppTypography.fontSizeXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          TableCalendar(
            firstDay: DateTime(DateTime.now().year, 1, 1),
            lastDay: DateTime(DateTime.now().year, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
              ),
              weekendTextStyle: TextStyle(
                color: AppColors.error.withValues(alpha: 0.7),
              ),
              outsideDaysVisible: false,
              defaultTextStyle: TextStyle(
                color: AppColors.textPrimary,
              ),
              markerDecoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                fontSize: AppTypography.fontSizeLG,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: AppColors.primary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: AppColors.primary,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: AppColors.error.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            onDaySelected: onDaySelected,
            onPageChanged: onPageChanged,
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildCalendarDay(day, false, false);
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildCalendarDay(day, true, false);
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildCalendarDay(day, false, true);
              },
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          _buildLegend(),
        ],
      ),
    );
  }

  /// Build individual calendar day cell.
  Widget _buildCalendarDay(DateTime day, bool isToday, bool isSelected) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    final hasAttendance = attendanceMap[dateOnly] == true;
    final isHoliday = holidays.contains(dateOnly);
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    Color? backgroundColor;
    Color? borderColor;
    Color textColor = AppColors.textPrimary;

    if (isSelected) {
      backgroundColor = AppColors.primary;
      textColor = AppColors.textOnPrimary;
      if (hasAttendance) {
        borderColor = AppColors.success;
      }
    } else if (hasAttendance) {
      backgroundColor = AppColors.success.withValues(alpha: 0.25);
      borderColor = AppColors.success;
      textColor = AppColors.success;
    } else if (isToday) {
      backgroundColor = AppColors.primary.withValues(alpha: 0.2);
      borderColor = AppColors.primary;
    } else if (isHoliday) {
      backgroundColor = AppColors.warning.withValues(alpha: 0.15);
      textColor = AppColors.warning;
    } else if (isWeekend) {
      textColor = AppColors.error.withValues(alpha: 0.6);
    }

    return Container(
      margin: EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2)
            : null,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: isToday || isSelected || hasAttendance
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: AppTypography.fontSizeBase,
              ),
            ),
            if (hasAttendance && !isSelected)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.5),
                        blurRadius: 2,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                color: AppColors.success,
                label: 'Present',
              ),
              _buildLegendItem(
                color: AppColors.warning,
                label: 'Holiday',
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                color: AppColors.primary,
                label: 'Today',
              ),
              _buildLegendItem(
                color: AppColors.textSecondary,
                label: 'Absent',
                isAbsent: true,
              ),
            ],
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
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isAbsent ? Colors.transparent : color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.fontSizeSM,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

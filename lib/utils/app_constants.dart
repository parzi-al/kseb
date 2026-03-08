/// Centralised constants for the attendance module.
///
/// All configurable attendance-related values live here so they can be
/// edited without touching business logic (FR-010).
abstract final class AttendanceConstants {
  /// Earliest hour attendance can be marked (inclusive).
  static const int attendanceStartHour = 6;

  /// Latest hour attendance can be marked (exclusive).
  static const int attendanceEndHour = 22;

  /// Total working days assumed in a year (for yearly progress calculation).
  static const int workingDaysInYear = 240;

  /// The month the fiscal/attendance year starts.
  ///
  /// - `1`  → Calendar year (Jan–Dec)
  /// - `4`  → Indian fiscal year (Apr–Mar)
  ///
  /// Change this single value to switch between fiscal-year and calendar-year
  /// accounting for all attendance statistics.
  static const int fiscalYearStartMonth = 1;

  /// Returns the start of the fiscal year that contains [date].
  ///
  /// Example with [fiscalYearStartMonth] = 4 (April):
  ///   - 2026-06-15 → 2026-04-01
  ///   - 2026-02-10 → 2025-04-01 (still in previous fiscal year)
  static DateTime fiscalYearStart(DateTime date) {
    if (date.month >= fiscalYearStartMonth) {
      return DateTime(date.year, fiscalYearStartMonth, 1);
    }
    return DateTime(date.year - 1, fiscalYearStartMonth, 1);
  }

  /// Returns the start of the **next** fiscal year after [date]'s fiscal year.
  static DateTime fiscalYearEnd(DateTime date) {
    final start = fiscalYearStart(date);
    return DateTime(start.year + 1, fiscalYearStartMonth, 1);
  }

  /// Valid attendance status values.
  static const Set<String> validStatuses = {'present', 'absent', 'leave'};

  /// Returns the set of public holidays for the given [year],
  /// each normalised to midnight.
  ///
  /// Currently hard-coded for Indian public holidays.
  /// The data source can be swapped to Firestore or remote config later
  /// without changing consumers.
  static Set<DateTime> getPublicHolidays(int year) {
    return {
      // Republic Day
      DateTime(year, 1, 26),
      // Holi (approximate — varies by lunar calendar)
      DateTime(year, 3, 14),
      // Good Friday
      DateTime(year, 4, 18),
      // Eid al-Fitr (approximate — varies by lunar calendar)
      DateTime(year, 4, 1),
      // May Day
      DateTime(year, 5, 1),
      // Independence Day
      DateTime(year, 8, 15),
      // Janmashtami (approximate)
      DateTime(year, 8, 26),
      // Gandhi Jayanti
      DateTime(year, 10, 2),
      // Dussehra (approximate)
      DateTime(year, 10, 13),
      // Diwali (approximate)
      DateTime(year, 11, 1),
      // Guru Nanak Jayanti (approximate)
      DateTime(year, 11, 15),
      // Christmas
      DateTime(year, 12, 25),
    };
  }
}

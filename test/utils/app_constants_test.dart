import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/utils/app_constants.dart';

void main() {
  group('Fiscal year helpers (calendar year, Jan–Dec)', () {
    // fiscalYearStartMonth is 1 (January) → standard calendar year.

    test('fiscalYearStart returns Jan 1 of the same year', () {
      final date = DateTime(2025, 7, 15);
      final start = AttendanceConstants.fiscalYearStart(date);
      expect(start, DateTime(2025, 1, 1));
    });

    test('fiscalYearStart returns Jan 1 for early-year dates too', () {
      final date = DateTime(2025, 2, 10);
      final start = AttendanceConstants.fiscalYearStart(date);
      expect(start, DateTime(2025, 1, 1));
    });

    test('fiscalYearStart returns Jan 1 when date is exactly Jan 1', () {
      final date = DateTime(2025, 1, 1);
      final start = AttendanceConstants.fiscalYearStart(date);
      expect(start, DateTime(2025, 1, 1));
    });

    test('fiscalYearEnd returns Jan 1 of next year', () {
      final date = DateTime(2025, 7, 15);
      final end = AttendanceConstants.fiscalYearEnd(date);
      expect(end, DateTime(2026, 1, 1));
    });

    test('fiscalYearEnd returns Jan 1 of next year for early dates', () {
      final date = DateTime(2025, 2, 10);
      final end = AttendanceConstants.fiscalYearEnd(date);
      expect(end, DateTime(2026, 1, 1));
    });

    test('fiscalYearStart and fiscalYearEnd span exactly one year', () {
      final date = DateTime(2025, 8, 20);
      final start = AttendanceConstants.fiscalYearStart(date);
      final end = AttendanceConstants.fiscalYearEnd(date);
      final diff = end.difference(start).inDays;
      expect(diff, inInclusiveRange(365, 366));
    });

    test('March 31 falls in current calendar year', () {
      final date = DateTime(2025, 3, 31);
      final start = AttendanceConstants.fiscalYearStart(date);
      final end = AttendanceConstants.fiscalYearEnd(date);
      expect(start, DateTime(2025, 1, 1));
      expect(end, DateTime(2026, 1, 1));
    });

    test('December 31 falls in current calendar year', () {
      final date = DateTime(2025, 12, 31);
      final start = AttendanceConstants.fiscalYearStart(date);
      expect(start, DateTime(2025, 1, 1));
    });
  });
}

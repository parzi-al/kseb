import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';
import '../utils/app_constants.dart';

/// Thrown when attendance has already been marked for the current day.
class AttendanceAlreadyMarkedException implements Exception {
  final String message;
  const AttendanceAlreadyMarkedException([
    this.message = 'Attendance already marked for today.',
  ]);
  @override
  String toString() => message;
}

class AttendanceService {
  final FirebaseFirestore _firestore;
  static const String _attendanceCollection = 'attendance';

  /// Creates an [AttendanceService].
  ///
  /// [firestore] defaults to [FirebaseFirestore.instance] in production.
  /// Pass a [FakeFirebaseFirestore] instance in tests.
  AttendanceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Mark attendance for a user.
  /// Returns true if successful, throws [AttendanceAlreadyMarkedException] if already marked.
  Future<bool> markAttendance({
    required String userId,
    String? worksheetId,
    String? verifiedBy,
    String status = 'present',
  }) async {
    // Validate status
    const validStatuses = {'present', 'absent', 'leave'};
    if (!validStatuses.contains(status)) {
      throw ArgumentError.value(
          status, 'status', 'Must be one of: ${validStatuses.join(', ')}');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if attendance already marked today
    final existingAttendance = await _firestore
        .collection(_attendanceCollection)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: Timestamp.fromDate(today))
        .limit(1)
        .get();

    if (existingAttendance.docs.isNotEmpty) {
      throw const AttendanceAlreadyMarkedException();
    }

    // Mark attendance
    await _firestore.collection(_attendanceCollection).add({
      'userId': userId,
      'worksheetId': worksheetId,
      'date': Timestamp.fromDate(today),
      'verifiedBy': verifiedBy,
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return true;
  }

  /// Get attendance count for a user in a specific month
  Future<int> getMonthlyAttendanceCount({
    required String userId,
    required int year,
    required int month,
  }) async {
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 1);

    final snapshot = await _firestore
        .collection(_attendanceCollection)
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('date', isLessThan: Timestamp.fromDate(monthEnd))
        .where('status', isEqualTo: 'present')
        .get();

    return snapshot.docs.length;
  }

  /// Get total attendance count for a user
  Future<int> getTotalAttendanceCount(String userId) async {
    final snapshot = await _firestore
        .collection(_attendanceCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'present')
        .get();

    return snapshot.docs.length;
  }

  /// Get attendance records for a user in a date range
  Stream<QuerySnapshot> getAttendanceStream({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore
        .collection(_attendanceCollection)
        .where('userId', isEqualTo: userId);

    if (startDate != null) {
      query = query.where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('date', isLessThan: Timestamp.fromDate(endDate));
    }

    return query.orderBy('date', descending: true).snapshots();
  }

  /// Get all attendance records for a team on a specific date.
  ///
  /// Returns [AttendanceModel] instances (FR-003).
  Future<List<AttendanceModel>> getTeamAttendance({
    required List<String> userIds,
    required DateTime date,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (userIds.isEmpty) {
      return [];
    }

    // Firestore 'in' queries are limited to 10 items
    final List<AttendanceModel> allAttendance = [];

    for (int i = 0; i < userIds.length; i += 10) {
      final batch = userIds.skip(i).take(10).toList();

      final snapshot = await _firestore
          .collection(_attendanceCollection)
          .where('userId', whereIn: batch)
          .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
          .get();

      allAttendance.addAll(
        snapshot.docs.map((doc) => AttendanceModel.fromFirestore(doc)),
      );
    }

    return allAttendance;
  }

  /// Verify attendance record (FR-011).
  ///
  /// Updates ONLY the [verifiedBy] field. The `status` field is NOT changed.
  /// NOTE: This feature is currently commented out for supervisors.
  Future<void> verifyAttendance({
    required String attendanceId,
    required String verifiedBy,
  }) async {
    await _firestore
        .collection(_attendanceCollection)
        .doc(attendanceId)
        .update({
      'verifiedBy': verifiedBy,
    });
  }

  /// Mark attendance for a team member (supervisor only).
  /// Allows supervisors to mark attendance for their team members on any date.
  Future<void> markAttendanceForTeamMember({
    required String userId,
    required DateTime date,
    String status = 'present',
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    // Check if attendance already marked for this date
    final existingAttendance = await _firestore
        .collection(_attendanceCollection)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
        .limit(1)
        .get();

    if (existingAttendance.docs.isNotEmpty) {
      throw Exception('Attendance already marked for this date');
    }

    // Mark attendance
    await _firestore.collection(_attendanceCollection).add({
      'userId': userId,
      'date': Timestamp.fromDate(normalizedDate),
      'status': status,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Remove attendance record (supervisor only).
  /// Allows supervisors to remove attendance records for their team members.
  Future<void> removeAttendance(String attendanceId) async {
    await _firestore
        .collection(_attendanceCollection)
        .doc(attendanceId)
        .delete();
  }

  /// Delete attendance record
  Future<void> deleteAttendance(String attendanceId) async {
    await _firestore
        .collection(_attendanceCollection)
        .doc(attendanceId)
        .delete();
  }

  /// Get all attendance records for a user, sorted by date descending (FR-002).
  ///
  /// This is the method [AttendanceHistoryScreen] MUST use instead of direct
  /// Firestore queries.
  Future<List<AttendanceModel>> getAttendanceHistory(String userId) async {
    final snapshot = await _firestore
        .collection(_attendanceCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => AttendanceModel.fromFirestore(doc))
        .toList();
  }

  /// Check if attendance is marked for today
  Future<bool> isAttendanceMarkedToday(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final snapshot = await _firestore
        .collection(_attendanceCollection)
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: Timestamp.fromDate(today))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Get attendance statistics for a user.
  ///
  /// Uses [AttendanceConstants.fiscalYearStartMonth] to determine year
  /// boundaries — configurable between calendar year and fiscal year.
  Future<Map<String, dynamic>> getUserAttendanceStats(String userId) async {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final fyStart = AttendanceConstants.fiscalYearStart(now);
    final fyEnd = AttendanceConstants.fiscalYearEnd(now);

    // Get all attendance records for the user (single query)
    final allSnapshot = await _firestore
        .collection(_attendanceCollection)
        .where('userId', isEqualTo: userId)
        .get();

    // Filter in code to avoid multiple indexes
    final allDocs = allSnapshot.docs;

    // Count this month
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final thisMonth = allDocs.where((doc) {
      final date = (doc.data()['date'] as Timestamp).toDate();
      final status = doc.data()['status'];
      return status == 'present' &&
          date.isAfter(currentMonth.subtract(const Duration(days: 1))) &&
          date.isBefore(monthEnd);
    }).length;

    // Count this fiscal/calendar year
    final thisYear = allDocs.where((doc) {
      final date = (doc.data()['date'] as Timestamp).toDate();
      final status = doc.data()['status'];
      return status == 'present' &&
          date.isAfter(fyStart.subtract(const Duration(days: 1))) &&
          date.isBefore(fyEnd);
    }).length;

    // Check if marked today
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = today.add(const Duration(days: 1));
    final isMarkedToday = allDocs.any((doc) {
      final date = (doc.data()['date'] as Timestamp).toDate();
      return date.isAfter(today.subtract(const Duration(days: 1))) &&
          date.isBefore(todayEnd);
    });

    return {
      'thisMonth': thisMonth,
      'thisYear': thisYear,
      'isMarkedToday': isMarkedToday,
    };
  }
}

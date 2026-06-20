import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';

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

  String _attendanceDocId(String userId, DateTime date) {
    final safeUserId = Uri.encodeComponent(userId);
    final day =
        '${date.year.toString().padLeft(4, '0')}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return '${safeUserId}_$day';
  }

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

    final attendanceRef = _firestore
        .collection(_attendanceCollection)
        .doc(_attendanceDocId(userId, today));

    await _firestore.runTransaction((transaction) async {
      final existingAttendance = await transaction.get(attendanceRef);
      if (existingAttendance.exists) {
        throw const AttendanceAlreadyMarkedException();
      }

      // Deterministic document IDs make duplicate daily writes impossible even
      // when the UI double-submits before the first write finishes.
      transaction.set(attendanceRef, {
        'userId': userId,
        'worksheetId': worksheetId,
        'date': Timestamp.fromDate(today),
        'verifiedBy': verifiedBy,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
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
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Get total attendance count for a user
  Future<int> getTotalAttendanceCount(String userId) async {
    final snapshot = await _firestore
        .collection(_attendanceCollection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'present')
        .count()
        .get();

    return snapshot.count ?? 0;
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

    final attendanceRef = _firestore
        .collection(_attendanceCollection)
        .doc(_attendanceDocId(userId, normalizedDate));

    await _firestore.runTransaction((transaction) async {
      final existingAttendance = await transaction.get(attendanceRef);
      if (existingAttendance.exists) {
        throw Exception('Attendance already marked for this date');
      }

      transaction.set(attendanceRef, {
        'userId': userId,
        'worksheetId': null,
        'date': Timestamp.fromDate(normalizedDate),
        'verifiedBy': null,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
      });
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
  Future<List<AttendanceModel>> getAttendanceHistory(
    String userId, {
    int? year,
    int? month,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_attendanceCollection)
        .where('userId', isEqualTo: userId);

    if (year != null) {
      final start = DateTime(year, month ?? 1, 1);
      final end = month != null
          ? DateTime(year, month + 1, 1)
          : DateTime(year + 1, 1, 1);
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end));
    }

    final snapshot = await query.get();

    final records =
        snapshot.docs.map((doc) => AttendanceModel.fromFirestore(doc)).toList();

    records.sort((a, b) => b.date.compareTo(a.date));
    return records;
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
  /// [referenceDate] controls the month/year summary window. Yearly stats use
  /// the calendar year containing [referenceDate] (Jan 1 to Dec 31).
  Future<Map<String, dynamic>> getUserAttendanceStats(
    String userId, {
    DateTime? referenceDate,
  }) async {
    final now = DateTime.now();
    final reference = referenceDate ?? now;
    final currentMonth = DateTime(reference.year, reference.month, 1);
    final yearStart = DateTime(reference.year, 1, 1);
    final yearEnd = DateTime(reference.year + 1, 1, 1);

    // Get all attendance records for the user (single query)
    final allSnapshot = await _firestore
        .collection(_attendanceCollection)
        .where('userId', isEqualTo: userId)
        .get();

    // Filter in code to avoid multiple indexes
    final allRecords = allSnapshot.docs
        .map((doc) => AttendanceModel.fromFirestore(doc))
        .toList();

    // Count this month
    final monthEnd = DateTime(reference.year, reference.month + 1, 1);
    final thisMonth = allRecords.where((record) {
      final date = record.date;
      return record.status == 'present' &&
          date.isAfter(currentMonth.subtract(const Duration(days: 1))) &&
          date.isBefore(monthEnd);
    }).length;

    // Count this calendar year
    final thisYear = allRecords.where((record) {
      final date = record.date;
      return record.status == 'present' &&
          date.isAfter(yearStart.subtract(const Duration(days: 1))) &&
          date.isBefore(yearEnd);
    }).length;

    // Check if marked today
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = today.add(const Duration(days: 1));
    final isMarkedToday = allRecords.any((record) {
      final date = record.date;
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

import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _attendanceCollection = 'attendance';

  /// Mark attendance for a user
  /// Returns true if successful, throws exception if already marked
  Future<bool> markAttendance({
    required String userId,
    String? worksheetId,
    String? verifiedBy,
  }) async {
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
      throw Exception('Attendance already marked for today');
    }

    // Mark attendance
    await _firestore.collection(_attendanceCollection).add({
      'userId': userId,
      'worksheetId': worksheetId,
      'date': Timestamp.fromDate(today),
      'verifiedBy': verifiedBy,
      'status': 'present',
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

  /// Get all attendance records for a team on a specific date
  Future<List<Map<String, dynamic>>> getTeamAttendance({
    required List<String> userIds,
    required DateTime date,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (userIds.isEmpty) {
      return [];
    }

    // Firestore 'in' queries are limited to 10 items
    // If more than 10 users, we need to batch the queries
    final List<Map<String, dynamic>> allAttendance = [];

    for (int i = 0; i < userIds.length; i += 10) {
      final batch = userIds.skip(i).take(10).toList();

      final snapshot = await _firestore
          .collection(_attendanceCollection)
          .where('userId', whereIn: batch)
          .where('date', isEqualTo: Timestamp.fromDate(normalizedDate))
          .get();

      allAttendance.addAll(
        snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }),
      );
    }

    return allAttendance;
  }

  /// Update attendance status (for supervisors/managers)
  Future<void> updateAttendanceStatus({
    required String attendanceId,
    required String status,
    required String verifiedBy,
  }) async {
    await _firestore.collection(_attendanceCollection).doc(attendanceId).update({
      'status': status,
      'verifiedBy': verifiedBy,
    });
  }

  /// Delete attendance record
  Future<void> deleteAttendance(String attendanceId) async {
    await _firestore.collection(_attendanceCollection).doc(attendanceId).delete();
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

  /// Get attendance statistics for a user
  Future<Map<String, dynamic>> getUserAttendanceStats(String userId) async {
    final now = DateTime.now();
    final currentYear = DateTime(now.year, 1, 1);
    final currentMonth = DateTime(now.year, now.month, 1);

    // Get all attendance records for the user (single query)
    final allSnapshot = await _firestore
        .collection(_attendanceCollection)
        .where('userId', isEqualTo: userId)
        .get();

    // Filter in code to avoid multiple indexes
    final allDocs = allSnapshot.docs;
    
    // Count total present days
    final total = allDocs
        .where((doc) => doc.data()['status'] == 'present')
        .length;

    // Count this month
    final monthEnd = DateTime(now.year, now.month + 1, 1);
    final thisMonth = allDocs.where((doc) {
      final date = (doc.data()['date'] as Timestamp).toDate();
      final status = doc.data()['status'];
      return status == 'present' && 
             date.isAfter(currentMonth.subtract(const Duration(days: 1))) &&
             date.isBefore(monthEnd);
    }).length;

    // Count this year
    final yearEnd = DateTime(now.year + 1, 1, 1);
    final thisYear = allDocs.where((doc) {
      final date = (doc.data()['date'] as Timestamp).toDate();
      final status = doc.data()['status'];
      return status == 'present' && 
             date.isAfter(currentYear.subtract(const Duration(days: 1))) &&
             date.isBefore(yearEnd);
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
      'total': total,
      'thisMonth': thisMonth,
      'thisYear': thisYear,
      'isMarkedToday': isMarkedToday,
    };
  }
}

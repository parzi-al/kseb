import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/models/attendance_model.dart';
import 'package:kseb/services/attendance_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late AttendanceService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = AttendanceService(firestore: fakeFirestore);
  });

  // ---------------------------------------------------------------------------
  // US1: markAttendance
  // ---------------------------------------------------------------------------
  group('markAttendance', () {
    test('creates attendance record and returns true', () async {
      final result = await service.markAttendance(userId: 'user1');

      expect(result, true);

      // Verify document was created
      final snap = await fakeFirestore.collection('attendance').get();
      expect(snap.docs.length, 1);

      final data = snap.docs.first.data();
      expect(data['userId'], 'user1');
      expect(data['status'], 'present');
      expect(data['worksheetId'], isNull);
      expect(data['verifiedBy'], isNull);
    });

    test('normalises date to midnight', () async {
      await service.markAttendance(userId: 'user1');

      final snap = await fakeFirestore.collection('attendance').get();
      final dateTs = snap.docs.first.data()['date'] as Timestamp;
      final date = dateTs.toDate();
      final now = DateTime.now();

      expect(date, DateTime(now.year, now.month, now.day));
    });

    test('throws AttendanceAlreadyMarkedException on duplicate', () async {
      await service.markAttendance(userId: 'user1');

      expect(
        () => service.markAttendance(userId: 'user1'),
        throwsA(isA<AttendanceAlreadyMarkedException>()),
      );
    });

    test('throws ArgumentError for invalid status', () async {
      expect(
        () => service.markAttendance(userId: 'user1', status: 'invalid'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts status parameter', () async {
      await service.markAttendance(userId: 'user1', status: 'present');

      final snap = await fakeFirestore.collection('attendance').get();
      expect(snap.docs.first.data()['status'], 'present');
    });

    test('passes optional worksheetId and verifiedBy', () async {
      await service.markAttendance(
        userId: 'user1',
        worksheetId: 'ws-1',
        verifiedBy: 'sup-1',
      );

      final data = (await fakeFirestore.collection('attendance').get())
          .docs
          .first
          .data();
      expect(data['worksheetId'], 'ws-1');
      expect(data['verifiedBy'], 'sup-1');
    });

    test('double-tap produces exactly one record (SC-004)', () async {
      // Simulate two rapid calls — second should throw
      await service.markAttendance(userId: 'user1');

      try {
        await service.markAttendance(userId: 'user1');
      } on AttendanceAlreadyMarkedException {
        // expected
      }

      final snap = await fakeFirestore.collection('attendance').get();
      expect(snap.docs.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // US1: isAttendanceMarkedToday
  // ---------------------------------------------------------------------------
  group('isAttendanceMarkedToday', () {
    test('returns false when no record exists', () async {
      final result = await service.isAttendanceMarkedToday('user1');
      expect(result, false);
    });

    test('returns true when record exists for today', () async {
      await service.markAttendance(userId: 'user1');
      final result = await service.isAttendanceMarkedToday('user1');
      expect(result, true);
    });

    test('returns false for different user', () async {
      await service.markAttendance(userId: 'user1');
      final result = await service.isAttendanceMarkedToday('user2');
      expect(result, false);
    });
  });

  // ---------------------------------------------------------------------------
  // US1: getUserAttendanceStats
  // ---------------------------------------------------------------------------
  group('getUserAttendanceStats', () {
    test('returns zeros when no records exist', () async {
      final stats = await service.getUserAttendanceStats('user1');

      expect(stats['thisMonth'], 0);
      expect(stats['thisYear'], 0);
      expect(stats['isMarkedToday'], false);
    });

    test('returns correct counts with records', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Add today's record
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(today),
        'timestamp': Timestamp.fromDate(now),
      });

      // Add another record in this month
      final thisMonthDate = DateTime(now.year, now.month, 1);
      if (thisMonthDate != today) {
        await fakeFirestore.collection('attendance').add({
          'userId': 'user1',
          'status': 'present',
          'date': Timestamp.fromDate(thisMonthDate),
          'timestamp': Timestamp.fromDate(thisMonthDate),
        });
      }

      final stats = await service.getUserAttendanceStats('user1');

      expect(stats['thisMonth'], greaterThanOrEqualTo(1));
      expect(stats['thisYear'], greaterThanOrEqualTo(1));
      expect(stats['isMarkedToday'], true);
    });

    test('ignores records from other users', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await fakeFirestore.collection('attendance').add({
        'userId': 'user2',
        'status': 'present',
        'date': Timestamp.fromDate(today),
        'timestamp': Timestamp.fromDate(now),
      });

      final stats = await service.getUserAttendanceStats('user1');
      expect(stats['thisMonth'], 0);
      expect(stats['thisYear'], 0);
    });
  });

  // ---------------------------------------------------------------------------
  // US2: getAttendanceHistory
  // ---------------------------------------------------------------------------
  group('getAttendanceHistory', () {
    test('returns empty list when no records exist', () async {
      final result = await service.getAttendanceHistory('user1');
      expect(result, isEmpty);
    });

    test('returns List<AttendanceModel> sorted by date descending', () async {
      final now = DateTime.now();
      final day1 = DateTime(now.year, now.month, 1);
      final day2 = DateTime(now.year, now.month, 2);
      final day3 = DateTime(now.year, now.month, 3);

      // Insert out of order
      for (final d in [day2, day1, day3]) {
        await fakeFirestore.collection('attendance').add({
          'userId': 'user1',
          'status': 'present',
          'date': Timestamp.fromDate(d),
          'timestamp': Timestamp.fromDate(d),
        });
      }

      final result = await service.getAttendanceHistory('user1');

      expect(result, hasLength(3));
      expect(result[0].date, day3);
      expect(result[1].date, day2);
      expect(result[2].date, day1);
    });

    test('only returns records for the specified user', () async {
      final date = DateTime(2026, 1, 15);
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(date),
        'timestamp': Timestamp.fromDate(date),
      });
      await fakeFirestore.collection('attendance').add({
        'userId': 'user2',
        'status': 'present',
        'date': Timestamp.fromDate(date),
        'timestamp': Timestamp.fromDate(date),
      });

      final result = await service.getAttendanceHistory('user1');
      expect(result, hasLength(1));
      expect(result.first.userId, 'user1');
    });

    test('returns AttendanceModel instances with all fields', () async {
      final date = DateTime(2026, 3, 10);
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(date),
        'timestamp': Timestamp.fromDate(date),
        'worksheetId': 'ws-99',
        'verifiedBy': 'sup-1',
      });

      final result = await service.getAttendanceHistory('user1');
      expect(result, hasLength(1));
      final record = result.first;
      expect(record, isA<AttendanceModel>());
      expect(record.userId, 'user1');
      expect(record.status, 'present');
      expect(record.worksheetId, 'ws-99');
      expect(record.verifiedBy, 'sup-1');
    });
  });

  // ---------------------------------------------------------------------------
  // US2: getMonthlyAttendanceCount
  // ---------------------------------------------------------------------------
  group('getMonthlyAttendanceCount', () {
    test('returns 0 when no records exist', () async {
      final count = await service.getMonthlyAttendanceCount(
        userId: 'user1',
        year: 2026,
        month: 3,
      );
      expect(count, 0);
    });

    test('returns correct count for given month', () async {
      // March has 2 present records
      for (final day in [5, 12]) {
        await fakeFirestore.collection('attendance').add({
          'userId': 'user1',
          'status': 'present',
          'date': Timestamp.fromDate(DateTime(2026, 3, day)),
          'timestamp': Timestamp.fromDate(DateTime(2026, 3, day)),
        });
      }

      // April record — should NOT count
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(DateTime(2026, 4, 1)),
        'timestamp': Timestamp.fromDate(DateTime(2026, 4, 1)),
      });

      final count = await service.getMonthlyAttendanceCount(
        userId: 'user1',
        year: 2026,
        month: 3,
      );
      expect(count, 2);
    });

    test('excludes absent records', () async {
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'absent',
        'date': Timestamp.fromDate(DateTime(2026, 3, 5)),
        'timestamp': Timestamp.fromDate(DateTime(2026, 3, 5)),
      });
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(DateTime(2026, 3, 6)),
        'timestamp': Timestamp.fromDate(DateTime(2026, 3, 6)),
      });

      final count = await service.getMonthlyAttendanceCount(
        userId: 'user1',
        year: 2026,
        month: 3,
      );
      expect(count, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // US2: getTotalAttendanceCount
  // ---------------------------------------------------------------------------
  group('getTotalAttendanceCount', () {
    test('returns 0 when no records exist', () async {
      final count = await service.getTotalAttendanceCount('user1');
      expect(count, 0);
    });

    test('counts only present records', () async {
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'timestamp': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'absent',
        'date': Timestamp.fromDate(DateTime(2026, 1, 2)),
        'timestamp': Timestamp.fromDate(DateTime(2026, 1, 2)),
      });
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'leave',
        'date': Timestamp.fromDate(DateTime(2026, 1, 3)),
        'timestamp': Timestamp.fromDate(DateTime(2026, 1, 3)),
      });
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(DateTime(2026, 2, 1)),
        'timestamp': Timestamp.fromDate(DateTime(2026, 2, 1)),
      });

      final count = await service.getTotalAttendanceCount('user1');
      expect(count, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // US2: getAttendanceStream
  // ---------------------------------------------------------------------------
  group('getAttendanceStream', () {
    test('emits snapshot for userId', () async {
      final stream = service.getAttendanceStream(userId: 'user1');

      // First emission should be empty
      final first = await stream.first;
      expect(first.docs, isEmpty);
    });

    test('respects date range filter', () async {
      // Pre-populate data
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(DateTime(2026, 3, 15)),
        'timestamp': Timestamp.fromDate(DateTime(2026, 3, 15)),
      });
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(DateTime(2026, 4, 15)),
        'timestamp': Timestamp.fromDate(DateTime(2026, 4, 15)),
      });

      final stream = service.getAttendanceStream(
        userId: 'user1',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 4, 1),
      );

      final snapshot = await stream.first;
      expect(snapshot.docs.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // US3: getTeamAttendance
  // ---------------------------------------------------------------------------
  group('getTeamAttendance', () {
    test('returns correct records for given userIds and date', () async {
      final date = DateTime(2026, 3, 8);
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(date),
        'timestamp': Timestamp.fromDate(date),
      });
      await fakeFirestore.collection('attendance').add({
        'userId': 'user2',
        'status': 'present',
        'date': Timestamp.fromDate(date),
        'timestamp': Timestamp.fromDate(date),
      });
      // Different date — should NOT be included
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(DateTime(2026, 3, 7)),
        'timestamp': Timestamp.fromDate(DateTime(2026, 3, 7)),
      });

      final result = await service.getTeamAttendance(
        userIds: ['user1', 'user2'],
        date: date,
      );

      expect(result, hasLength(2));
      expect(result, everyElement(isA<AttendanceModel>()));
    });

    test('normalises date to midnight', () async {
      final date = DateTime(2026, 3, 8);
      await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(date),
        'timestamp': Timestamp.fromDate(date),
      });

      // Query with time component — should still match
      final result = await service.getTeamAttendance(
        userIds: ['user1'],
        date: DateTime(2026, 3, 8, 14, 30),
      );

      expect(result, hasLength(1));
    });

    test('returns empty list for empty userIds', () async {
      final result = await service.getTeamAttendance(
        userIds: [],
        date: DateTime(2026, 3, 8),
      );

      expect(result, isEmpty);
    });

    test('handles batch query for >10 users', () async {
      final date = DateTime(2026, 3, 8);
      // Create 12 users with attendance
      for (int i = 1; i <= 12; i++) {
        await fakeFirestore.collection('attendance').add({
          'userId': 'user$i',
          'status': 'present',
          'date': Timestamp.fromDate(date),
          'timestamp': Timestamp.fromDate(date),
        });
      }

      final userIds = List.generate(12, (i) => 'user${i + 1}');

      final result = await service.getTeamAttendance(
        userIds: userIds,
        date: date,
      );

      // All 12 users should be returned across 2 batches
      expect(result, hasLength(12));
    });
  });

  // ---------------------------------------------------------------------------
  // US3: verifyAttendance
  // ---------------------------------------------------------------------------
  group('verifyAttendance', () {
    test('updates ONLY verifiedBy field, status unchanged (FR-011)', () async {
      // Create a record with status present and no verifiedBy
      final docRef = await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(DateTime(2026, 3, 8)),
        'timestamp': Timestamp.fromDate(DateTime(2026, 3, 8)),
        'verifiedBy': null,
      });

      await service.verifyAttendance(
        attendanceId: docRef.id,
        verifiedBy: 'supervisor1',
      );

      // Read back the document
      final updated =
          await fakeFirestore.collection('attendance').doc(docRef.id).get();
      final data = updated.data()!;

      expect(data['verifiedBy'], 'supervisor1');
      expect(data['status'], 'present'); // Status unchanged (FR-011)
      expect(data['userId'], 'user1'); // Other fields unchanged
    });

    test('can verify an already verified record with different supervisor',
        () async {
      final docRef = await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(DateTime(2026, 3, 8)),
        'timestamp': Timestamp.fromDate(DateTime(2026, 3, 8)),
        'verifiedBy': 'supervisor1',
      });

      await service.verifyAttendance(
        attendanceId: docRef.id,
        verifiedBy: 'supervisor2',
      );

      final updated =
          await fakeFirestore.collection('attendance').doc(docRef.id).get();
      expect(updated.data()!['verifiedBy'], 'supervisor2');
      expect(updated.data()!['status'], 'present');
    });
  });

  // ---------------------------------------------------------------------------
  // deleteAttendance (T020)
  // ---------------------------------------------------------------------------
  group('deleteAttendance', () {
    test('deletes document by attendanceId', () async {
      final docRef = await fakeFirestore.collection('attendance').add({
        'userId': 'user1',
        'status': 'present',
        'date': Timestamp.fromDate(DateTime(2026, 3, 8)),
        'timestamp': Timestamp.fromDate(DateTime(2026, 3, 8)),
      });

      // Verify it exists
      var snap = await fakeFirestore.collection('attendance').get();
      expect(snap.docs, hasLength(1));

      await service.deleteAttendance(docRef.id);

      snap = await fakeFirestore.collection('attendance').get();
      expect(snap.docs, isEmpty);
    });
  });
}

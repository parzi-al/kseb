import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/models/attendance_model.dart';

void main() {
  group('AttendanceModel', () {
    group('constructor', () {
      test('creates with default status "present"', () {
        final model = AttendanceModel(
          id: '1',
          userId: 'user1',
          date: DateTime(2026, 3, 8, 14, 30),
          timestamp: DateTime(2026, 3, 8, 14, 30),
        );

        expect(model.status, 'present');
        expect(model.worksheetId, isNull);
        expect(model.verifiedBy, isNull);
      });

      test('normalises date to midnight', () {
        final model = AttendanceModel(
          id: '1',
          userId: 'user1',
          date: DateTime(2026, 3, 8, 14, 30, 45),
          timestamp: DateTime(2026, 3, 8, 14, 30, 45),
        );

        expect(model.date, DateTime(2026, 3, 8));
        expect(model.date.hour, 0);
        expect(model.date.minute, 0);
        expect(model.date.second, 0);
      });

      test('accepts valid status values', () {
        for (final status in ['present', 'absent', 'leave']) {
          final model = AttendanceModel(
            id: '1',
            userId: 'user1',
            date: DateTime(2026, 3, 8),
            timestamp: DateTime(2026, 3, 8),
            status: status,
          );
          expect(model.status, status);
        }
      });

      test('throws ArgumentError for invalid status', () {
        expect(
          () => AttendanceModel(
            id: '1',
            userId: 'user1',
            date: DateTime(2026, 3, 8),
            timestamp: DateTime(2026, 3, 8),
            status: 'invalid',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('preserves all fields including nullable ones', () {
        final model = AttendanceModel(
          id: 'doc-123',
          userId: 'user-abc',
          worksheetId: 'ws-456',
          date: DateTime(2026, 3, 8),
          verifiedBy: 'supervisor-789',
          status: 'present',
          timestamp: DateTime(2026, 3, 8, 8, 15, 32),
        );

        expect(model.id, 'doc-123');
        expect(model.userId, 'user-abc');
        expect(model.worksheetId, 'ws-456');
        expect(model.verifiedBy, 'supervisor-789');
        expect(model.timestamp, DateTime(2026, 3, 8, 8, 15, 32));
      });
    });

    group('fromFirestore', () {
      late FakeFirebaseFirestore fakeFirestore;

      setUp(() {
        fakeFirestore = FakeFirebaseFirestore();
      });

      test('deserialises all fields from Firestore document', () async {
        final date = DateTime(2026, 3, 8);
        final ts = DateTime(2026, 3, 8, 8, 15, 32);

        await fakeFirestore.collection('attendance').doc('doc1').set({
          'userId': 'user1',
          'worksheetId': 'ws1',
          'date': Timestamp.fromDate(date),
          'verifiedBy': 'supervisor1',
          'status': 'present',
          'timestamp': Timestamp.fromDate(ts),
        });

        final doc =
            await fakeFirestore.collection('attendance').doc('doc1').get();
        final model = AttendanceModel.fromFirestore(doc);

        expect(model.id, 'doc1');
        expect(model.userId, 'user1');
        expect(model.worksheetId, 'ws1');
        expect(model.date, date);
        expect(model.verifiedBy, 'supervisor1');
        expect(model.status, 'present');
        expect(model.timestamp, ts);
      });

      test('handles null worksheetId and verifiedBy', () async {
        final date = DateTime(2026, 3, 8);
        final ts = DateTime(2026, 3, 8, 8, 0);

        await fakeFirestore.collection('attendance').doc('doc2').set({
          'userId': 'user2',
          'worksheetId': null,
          'date': Timestamp.fromDate(date),
          'verifiedBy': null,
          'status': 'present',
          'timestamp': Timestamp.fromDate(ts),
        });

        final doc =
            await fakeFirestore.collection('attendance').doc('doc2').get();
        final model = AttendanceModel.fromFirestore(doc);

        expect(model.worksheetId, isNull);
        expect(model.verifiedBy, isNull);
      });

      test('defaults status to "present" when missing', () async {
        final date = DateTime(2026, 3, 8);
        final ts = DateTime(2026, 3, 8, 8, 0);

        await fakeFirestore.collection('attendance').doc('doc3').set({
          'userId': 'user3',
          'date': Timestamp.fromDate(date),
          'timestamp': Timestamp.fromDate(ts),
        });

        final doc =
            await fakeFirestore.collection('attendance').doc('doc3').get();
        final model = AttendanceModel.fromFirestore(doc);

        expect(model.status, 'present');
      });
    });

    group('toMap', () {
      test('serialises all fields correctly', () {
        final date = DateTime(2026, 3, 8);
        final ts = DateTime(2026, 3, 8, 8, 15, 32);
        final model = AttendanceModel(
          id: 'doc1',
          userId: 'user1',
          worksheetId: 'ws1',
          date: date,
          verifiedBy: 'supervisor1',
          status: 'present',
          timestamp: ts,
        );

        final map = model.toMap();

        expect(map['userId'], 'user1');
        expect(map['worksheetId'], 'ws1');
        expect(map['date'], Timestamp.fromDate(date));
        expect(map['verifiedBy'], 'supervisor1');
        expect(map['status'], 'present');
        expect(map['timestamp'], Timestamp.fromDate(ts));
        // id should NOT be in the map (it's the document ID)
        expect(map.containsKey('id'), false);
      });

      test('serialises null fields as null', () {
        final model = AttendanceModel(
          id: 'doc2',
          userId: 'user2',
          date: DateTime(2026, 3, 8),
          timestamp: DateTime(2026, 3, 8, 8, 0),
        );

        final map = model.toMap();

        expect(map['worksheetId'], isNull);
        expect(map['verifiedBy'], isNull);
      });
    });

    group('roundtrip', () {
      late FakeFirebaseFirestore fakeFirestore;

      setUp(() {
        fakeFirestore = FakeFirebaseFirestore();
      });

      test('toMap → fromFirestore roundtrip preserves data', () async {
        final original = AttendanceModel(
          id: 'roundtrip',
          userId: 'user-rt',
          worksheetId: 'ws-rt',
          date: DateTime(2026, 6, 15, 10, 30),
          verifiedBy: 'sup-rt',
          status: 'present',
          timestamp: DateTime(2026, 6, 15, 10, 30, 0),
        );

        await fakeFirestore
            .collection('attendance')
            .doc('roundtrip')
            .set(original.toMap());

        final doc =
            await fakeFirestore.collection('attendance').doc('roundtrip').get();
        final restored = AttendanceModel.fromFirestore(doc);

        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.worksheetId, original.worksheetId);
        expect(restored.date, DateTime(2026, 6, 15)); // normalised
        expect(restored.verifiedBy, original.verifiedBy);
        expect(restored.status, original.status);
        expect(restored.timestamp, original.timestamp);
      });
    });

    group('fromMap', () {
      test('deserialises all fields from map', () {
        final date = DateTime(2026, 3, 8);
        final ts = DateTime(2026, 3, 8, 8, 15, 32);

        final model = AttendanceModel.fromMap({
          'userId': 'user1',
          'worksheetId': 'ws1',
          'date': Timestamp.fromDate(date),
          'verifiedBy': 'supervisor1',
          'status': 'present',
          'timestamp': Timestamp.fromDate(ts),
        }, 'doc1');

        expect(model.id, 'doc1');
        expect(model.userId, 'user1');
        expect(model.worksheetId, 'ws1');
        expect(model.date, date);
        expect(model.verifiedBy, 'supervisor1');
        expect(model.status, 'present');
        expect(model.timestamp, ts);
      });

      test('handles null optional fields', () {
        final model = AttendanceModel.fromMap({
          'userId': 'user2',
          'date': Timestamp.fromDate(DateTime(2026, 3, 8)),
          'timestamp': Timestamp.fromDate(DateTime(2026, 3, 8, 8, 0)),
        }, 'doc2');

        expect(model.worksheetId, isNull);
        expect(model.verifiedBy, isNull);
        expect(model.status, 'present'); // default
      });

      test('handles string dates (non-Timestamp)', () {
        final model = AttendanceModel.fromMap({
          'userId': 'user3',
          'date': '2026-03-08',
          'timestamp': '2026-03-08T08:15:32.000',
        }, 'doc3');

        expect(model.date, DateTime(2026, 3, 8));
        expect(model.timestamp.year, 2026);
      });

      test('handles null date and timestamp with fallback', () {
        final now = DateTime.now();
        final model = AttendanceModel.fromMap({
          'userId': 'user4',
          'date': null,
          'timestamp': null,
        }, 'doc4');

        // Should fallback to DateTime.now() — just verify it's today
        expect(model.date.year, now.year);
        expect(model.date.month, now.month);
        expect(model.date.day, now.day);
      });
    });

    group('fromFirestore string dates', () {
      late FakeFirebaseFirestore fakeFirestore;

      setUp(() {
        fakeFirestore = FakeFirebaseFirestore();
      });

      test('handles string date values in Firestore', () async {
        await fakeFirestore.collection('attendance').doc('str-date').set({
          'userId': 'user5',
          'date': '2026-05-20',
          'timestamp': '2026-05-20T10:30:00.000',
          'status': 'present',
        });

        final doc =
            await fakeFirestore.collection('attendance').doc('str-date').get();
        final model = AttendanceModel.fromFirestore(doc);

        expect(model.date, DateTime(2026, 5, 20));
        expect(model.timestamp.year, 2026);
      });

      test('handles null date in Firestore (falls back to now)', () async {
        await fakeFirestore.collection('attendance').doc('null-date').set({
          'userId': 'user6',
          'status': 'present',
          'date': null,
          'timestamp': null,
        });

        final doc =
            await fakeFirestore.collection('attendance').doc('null-date').get();
        final now = DateTime.now();
        final model = AttendanceModel.fromFirestore(doc);

        expect(model.date.year, now.year);
        expect(model.date.month, now.month);
        expect(model.date.day, now.day);
      });
    });
  });
}

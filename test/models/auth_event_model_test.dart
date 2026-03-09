import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/models/auth_event_model.dart';

void main() {
  group('AuthEventType', () {
    test('firestoreValue returns correct snake_case strings', () {
      expect(AuthEventType.loginSuccess.firestoreValue, 'login_success');
      expect(AuthEventType.loginFailure.firestoreValue, 'login_failure');
      expect(AuthEventType.logout.firestoreValue, 'logout');
      expect(AuthEventType.idleTimeout.firestoreValue, 'idle_timeout');
      expect(AuthEventType.forceLogout.firestoreValue, 'force_logout');
    });

    test('fromString parses all valid values', () {
      expect(AuthEventType.fromString('login_success'),
          AuthEventType.loginSuccess);
      expect(AuthEventType.fromString('login_failure'),
          AuthEventType.loginFailure);
      expect(AuthEventType.fromString('logout'), AuthEventType.logout);
      expect(
          AuthEventType.fromString('idle_timeout'), AuthEventType.idleTimeout);
      expect(
          AuthEventType.fromString('force_logout'), AuthEventType.forceLogout);
    });

    test('fromString throws on unknown value', () {
      expect(
          () => AuthEventType.fromString('unknown'), throwsA(isArgumentError));
    });

    test('roundtrip: firestoreValue → fromString', () {
      for (final type in AuthEventType.values) {
        expect(AuthEventType.fromString(type.firestoreValue), type);
      }
    });
  });

  group('AuthEventModel', () {
    group('constructor', () {
      test('creates with all required fields', () {
        final event = AuthEventModel(
          email: 'test@kseb.in',
          eventType: AuthEventType.loginSuccess,
          timestamp: DateTime(2026, 3, 9),
        );

        expect(event.email, 'test@kseb.in');
        expect(event.eventType, AuthEventType.loginSuccess);
        expect(event.timestamp, DateTime(2026, 3, 9));
        expect(event.userId, isNull);
        expect(event.id, isNull);
        expect(event.deviceInfo, isNull);
        expect(event.sessionToken, isNull);
        expect(event.metadata, isNull);
      });

      test('creates with all optional fields', () {
        final event = AuthEventModel(
          id: 'evt1',
          userId: 'user1',
          email: 'test@kseb.in',
          eventType: AuthEventType.loginFailure,
          timestamp: DateTime(2026, 3, 9),
          deviceInfo: 'Pixel 7 / Android 15',
          sessionToken: 'sess_123',
          metadata: {'errorCode': 'wrong-password'},
        );

        expect(event.id, 'evt1');
        expect(event.userId, 'user1');
        expect(event.deviceInfo, 'Pixel 7 / Android 15');
        expect(event.sessionToken, 'sess_123');
        expect(event.metadata, {'errorCode': 'wrong-password'});
      });
    });

    group('fromMap', () {
      test('parses map with Timestamp', () {
        final map = {
          'userId': 'u1',
          'email': 'worker@kseb.in',
          'eventType': 'logout',
          'timestamp': Timestamp.fromDate(DateTime(2026, 3, 9, 10, 30)),
          'deviceInfo': 'iPhone 15',
          'sessionToken': 'sess_456',
          'metadata': null,
        };

        final event = AuthEventModel.fromMap(map, 'doc1');

        expect(event.id, 'doc1');
        expect(event.userId, 'u1');
        expect(event.email, 'worker@kseb.in');
        expect(event.eventType, AuthEventType.logout);
        expect(event.timestamp, DateTime(2026, 3, 9, 10, 30));
      });

      test('parses map with DateTime', () {
        final ts = DateTime(2026, 3, 9, 12, 0);
        final map = {
          'email': 'a@b.com',
          'eventType': 'idle_timeout',
          'timestamp': ts,
        };

        final event = AuthEventModel.fromMap(map);
        expect(event.eventType, AuthEventType.idleTimeout);
        expect(event.timestamp, ts);
        expect(event.id, isNull);
      });

      test('defaults email to empty string when missing', () {
        final map = {
          'eventType': 'login_success',
          'timestamp': Timestamp.fromDate(DateTime(2026, 1, 1)),
        };
        final event = AuthEventModel.fromMap(map);
        expect(event.email, '');
      });
    });

    group('toTestMap', () {
      test('serializes all fields correctly', () {
        final event = AuthEventModel(
          userId: 'u1',
          email: 'test@kseb.in',
          eventType: AuthEventType.loginSuccess,
          timestamp: DateTime(2026, 3, 9),
          sessionToken: 'sess_1',
          metadata: {'key': 'value'},
        );

        final map = event.toTestMap();
        expect(map['userId'], 'u1');
        expect(map['email'], 'test@kseb.in');
        expect(map['eventType'], 'login_success');
        expect(map['timestamp'], isA<Timestamp>());
        expect(map['sessionToken'], 'sess_1');
        expect(map['metadata'], {'key': 'value'});
      });

      test('omits metadata when null', () {
        final event = AuthEventModel(
          email: 'test@kseb.in',
          eventType: AuthEventType.logout,
          timestamp: DateTime(2026, 3, 9),
        );

        final map = event.toTestMap();
        expect(map.containsKey('metadata'), isFalse);
      });
    });

    group('fromFirestore', () {
      test('roundtrip: toTestMap → Firestore → fromFirestore', () async {
        final fakeFirestore = FakeFirebaseFirestore();
        final event = AuthEventModel(
          userId: 'u1',
          email: 'test@kseb.in',
          eventType: AuthEventType.forceLogout,
          timestamp: DateTime(2026, 3, 9, 14, 0),
          sessionToken: 'sess_789',
        );

        // Write to fake Firestore
        final docRef =
            await fakeFirestore.collection('auth_events').add(event.toTestMap());

        // Read back
        final doc = await docRef.get();
        final parsed = AuthEventModel.fromFirestore(doc);

        expect(parsed.id, docRef.id);
        expect(parsed.userId, 'u1');
        expect(parsed.email, 'test@kseb.in');
        expect(parsed.eventType, AuthEventType.forceLogout);
        expect(parsed.sessionToken, 'sess_789');
      });
    });
  });
}

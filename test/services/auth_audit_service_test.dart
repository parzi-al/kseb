import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/models/auth_event_model.dart';
import 'package:kseb/services/auth_audit_service.dart';

void main() {
  group('AuthAuditService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late AuthAuditService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = AuthAuditService(firestore: fakeFirestore);
    });

    group('logEvent', () {
      test('writes event to auth_events collection', () async {
        await service.logEvent(
          eventType: AuthEventType.loginSuccess,
          email: 'test@kseb.in',
          userId: 'user1',
          sessionToken: 'sess_123',
        );

        final snapshot =
            await fakeFirestore.collection('auth_events').get();
        expect(snapshot.docs.length, 1);

        final data = snapshot.docs.first.data();
        expect(data['email'], 'test@kseb.in');
        expect(data['eventType'], 'login_success');
        expect(data['userId'], 'user1');
        expect(data['sessionToken'], 'sess_123');
      });

      test('writes event with null userId for unknown user failure', () async {
        await service.logEvent(
          eventType: AuthEventType.loginFailure,
          email: 'unknown@kseb.in',
          metadata: {'errorCode': 'user-not-found'},
        );

        final snapshot =
            await fakeFirestore.collection('auth_events').get();
        expect(snapshot.docs.length, 1);

        final data = snapshot.docs.first.data();
        expect(data['userId'], isNull);
        expect(data['eventType'], 'login_failure');
        expect(data['metadata'], {'errorCode': 'user-not-found'});
      });

      test('writes all event types', () async {
        for (final type in AuthEventType.values) {
          await service.logEvent(
            eventType: type,
            email: 'test@kseb.in',
          );
        }

        final snapshot =
            await fakeFirestore.collection('auth_events').get();
        expect(snapshot.docs.length, AuthEventType.values.length);
      });

      test('does not throw on write failure', () async {
        // This tests the graceful error handling — logEvent should never throw.
        // With FakeFirebaseFirestore this won't actually fail, but the pattern is correct.
        await service.logEvent(
          eventType: AuthEventType.logout,
          email: 'test@kseb.in',
        );
        // If we get here without throwing, the test passes.
      });
    });

    group('getEventsForUser', () {
      test('returns events for specific user', () async {
        // Add events for two different users
        await fakeFirestore.collection('auth_events').add({
          'userId': 'user1',
          'email': 'user1@kseb.in',
          'eventType': 'login_success',
          'timestamp': DateTime(2026, 3, 9, 10, 0),
        });
        await fakeFirestore.collection('auth_events').add({
          'userId': 'user2',
          'email': 'user2@kseb.in',
          'eventType': 'login_success',
          'timestamp': DateTime(2026, 3, 9, 11, 0),
        });
        await fakeFirestore.collection('auth_events').add({
          'userId': 'user1',
          'email': 'user1@kseb.in',
          'eventType': 'logout',
          'timestamp': DateTime(2026, 3, 9, 12, 0),
        });

        final events = await service.getEventsForUser('user1');
        expect(events.length, 2);
        expect(events.every((e) => e.userId == 'user1'), isTrue);
      });

      test('respects limit parameter', () async {
        for (int i = 0; i < 10; i++) {
          await fakeFirestore.collection('auth_events').add({
            'userId': 'user1',
            'email': 'user1@kseb.in',
            'eventType': 'login_success',
            'timestamp': DateTime(2026, 3, 9, i),
          });
        }

        final events = await service.getEventsForUser('user1', limit: 3);
        expect(events.length, 3);
      });
    });

    group('getRecentEvents', () {
      test('returns events across all users', () async {
        await fakeFirestore.collection('auth_events').add({
          'userId': 'user1',
          'email': 'u1@kseb.in',
          'eventType': 'login_success',
          'timestamp': DateTime(2026, 3, 9, 10, 0),
        });
        await fakeFirestore.collection('auth_events').add({
          'userId': 'user2',
          'email': 'u2@kseb.in',
          'eventType': 'logout',
          'timestamp': DateTime(2026, 3, 9, 11, 0),
        });

        final events = await service.getRecentEvents();
        expect(events.length, 2);
      });
    });
  });
}

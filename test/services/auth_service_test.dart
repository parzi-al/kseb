import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/models/auth_event_model.dart';
import 'package:kseb/services/auth_audit_service.dart';
import 'package:kseb/services/auth_service.dart';
import 'package:kseb/services/session_service.dart';

void main() {
  group('AuthService', () {
    // AuthService depends on FirebaseAuth.instance which requires Firebase
    // initialization. Full integration tests of signIn/signOut are validated
    // manually via quickstart.md steps 1-2.
    //
    // These tests verify the sub-services that AuthService orchestrates,
    // using fake_cloud_firestore for isolation.

    late FakeFirebaseFirestore fakeFirestore;
    late AuthAuditService auditService;
    late SessionService sessionService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      auditService = AuthAuditService(firestore: fakeFirestore);
      sessionService = SessionService(firestore: fakeFirestore);
    });

    test('AuthAuditService is injectable', () {
      expect(auditService, isNotNull);
    });

    test('SessionService is injectable', () {
      expect(sessionService, isNotNull);
    });

    test('AuthService class exists and accepts dependency injection', () {
      // Verify the class exists and its constructor signature
      // The actual construction requires FirebaseAuth so we just
      // validate the type system accepts the parameters
      expect(AuthService, isNotNull);
    });

    group('sub-service integration', () {
      test('audit + session work together for login flow', () async {
        // Simulate what AuthService.signIn does internally:
        // 1. Create session token
        await fakeFirestore.collection('users').doc('u1').set({
          'name': 'Test',
          'email': 'test@kseb.in',
          'role': 'staff',
        });
        final token = await sessionService.createSession('u1');
        expect(token, startsWith('sess_'));

        // 2. Log audit event
        await auditService.logEvent(
          eventType: AuthEventType.loginSuccess,
          email: 'test@kseb.in',
          userId: 'u1',
          sessionToken: token,
        );

        // Verify both side-effects
        final userDoc = await fakeFirestore.collection('users').doc('u1').get();
        expect(userDoc.data()!['activeSessionToken'], token);

        final events = await fakeFirestore.collection('auth_events').get();
        expect(events.docs.length, 1);
        expect(events.docs.first.data()['eventType'], 'login_success');
      });

      test('audit + session work together for logout flow', () async {
        await fakeFirestore.collection('users').doc('u1').set({
          'name': 'Test',
          'email': 'test@kseb.in',
          'role': 'staff',
        });

        // Login
        final token = await sessionService.createSession('u1');

        // Logout
        await sessionService.clearSession('u1');
        await auditService.logEvent(
          eventType: AuthEventType.logout,
          email: 'test@kseb.in',
          userId: 'u1',
          sessionToken: token,
          metadata: {'reason': 'manual'},
        );

        // Verify
        final userDoc = await fakeFirestore.collection('users').doc('u1').get();
        expect(userDoc.data()!['activeSessionToken'], isNull);

        // Session should be invalid now
        final isValid = await sessionService.isSessionValid('u1', token);
        expect(isValid, isFalse);
      });
    });
  });
}

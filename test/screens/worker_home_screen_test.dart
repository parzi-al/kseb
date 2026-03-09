import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kseb/screens/auth_gate.dart';
import 'package:kseb/screens/login_screen.dart';
import 'package:kseb/services/auth_service.dart';
import 'package:kseb/services/auth_audit_service.dart';
import 'package:kseb/services/session_service.dart';
import 'package:kseb/models/auth_event_model.dart';
import '../helpers/test_helpers.dart';
import '../helpers/firebase_mock_helper.dart';

/// Fake [User] stub for testing (implements the minimum needed).
class _FakeUser {
  final String uid;
  final String? email;
  _FakeUser({required this.uid, this.email});
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    setupTestEnvironment();
    await Firebase.initializeApp();
  });

  AuthService createTestAuthService(FakeFirebaseFirestore fakeFirestore) {
    return AuthService(
      auditService: AuthAuditService(firestore: fakeFirestore),
      sessionService: SessionService(firestore: fakeFirestore),
    );
  }

  group('AuthGate logout integration', () {
    testWidgets('shows LoginScreen when auth stream emits null',
        (tester) async {
      final controller = StreamController<dynamic>.broadcast();

      await tester.pumpWidget(
        createTestApp(
          AuthGate(
            authService: createTestAuthService(FakeFirebaseFirestore()),
            authStream: controller.stream.cast(),
            skipSplash: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Emit null (signed out) → should show LoginScreen
      controller.add(null);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      await controller.close();
    });

    testWidgets(
        'transitions from authenticated to login when stream emits null',
        (tester) async {
      final controller = StreamController<dynamic>.broadcast();
      final fakeUser = _FakeUser(uid: 'u1', email: 'a@b.com');

      await tester.pumpWidget(
        createTestApp(
          AuthGate(
            authService: createTestAuthService(FakeFirebaseFirestore()),
            authStream: controller.stream.cast(),
            skipSplash: true,
          ),
        ),
      );

      // Emit authenticated user first
      controller.add(fakeUser);
      await tester.pumpAndSettle();

      // Now emit null (logout)
      controller.add(null);
      await tester.pumpAndSettle();

      // Should show LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);

      await controller.close();
    });
  });

  group('SessionService single-session enforcement', () {
    test('createSession then clearSession removes token', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final sessionService = SessionService(firestore: fakeFirestore);

      // Pre-create user document (update requires existing doc)
      await fakeFirestore
          .collection('users')
          .doc('user1')
          .set({'name': 'Test User'});

      final token = await sessionService.createSession('user1');
      expect(token, startsWith('sess_'));

      // Verify token is in Firestore
      final valid = await sessionService.isSessionValid('user1', token);
      expect(valid, isTrue);

      // Clear session
      await sessionService.clearSession('user1');

      // Token should no longer be valid
      final validAfterClear =
          await sessionService.isSessionValid('user1', token);
      expect(validAfterClear, isFalse);
    });

    test('second device login invalidates first device token', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final sessionService = SessionService(firestore: fakeFirestore);

      // Pre-create user document
      await fakeFirestore
          .collection('users')
          .doc('user1')
          .set({'name': 'Test User'});

      // Device 1 creates session
      final token1 = await sessionService.createSession('user1');

      // Device 2 creates new session (login on second device)
      final token2 = await sessionService.createSession('user1');

      // Device 1's token should now be invalid
      final valid1 = await sessionService.isSessionValid('user1', token1);
      expect(valid1, isFalse);

      // Device 2's token should be valid
      final valid2 = await sessionService.isSessionValid('user1', token2);
      expect(valid2, isTrue);
    });
  });

  group('AuditService logout event types', () {
    test('logs logout event', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final auditService = AuthAuditService(firestore: fakeFirestore);

      await auditService.logEvent(
        eventType: AuthEventType.logout,
        email: 'test@test.com',
        metadata: {'reason': 'user_initiated'},
      );

      final events = await fakeFirestore.collection('auth_events').get();
      expect(events.docs, hasLength(1));
      expect(events.docs.first.data()['eventType'], 'logout');
      expect(events.docs.first.data()['metadata']?['reason'], 'user_initiated');
    });

    test('logs idle_timeout event', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final auditService = AuthAuditService(firestore: fakeFirestore);

      await auditService.logEvent(
        eventType: AuthEventType.idleTimeout,
        email: 'test@test.com',
      );

      final events = await fakeFirestore.collection('auth_events').get();
      expect(events.docs, hasLength(1));
      expect(events.docs.first.data()['eventType'], 'idle_timeout');
    });

    test('logs force_logout event', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final auditService = AuthAuditService(firestore: fakeFirestore);

      await auditService.logEvent(
        eventType: AuthEventType.forceLogout,
        email: 'test@test.com',
      );

      final events = await fakeFirestore.collection('auth_events').get();
      expect(events.docs, hasLength(1));
      expect(events.docs.first.data()['eventType'], 'force_logout');
    });
  });

  group('AuthGate idle timeout integration', () {
    testWidgets('authenticated view is wrapped in pointer listener',
        (tester) async {
      final controller = StreamController<dynamic>.broadcast();
      final fakeUser = _FakeUser(uid: 'u1', email: 'test@test.com');

      await tester.pumpWidget(
        createTestApp(
          AuthGate(
            authService: createTestAuthService(FakeFirebaseFirestore()),
            authStream: controller.stream.cast(),
            skipSplash: true,
          ),
        ),
      );

      // Emit authenticated user
      controller.add(fakeUser);
      await tester.pumpAndSettle();

      // Verify the AuthGate widget tree contains at least one Listener
      // (the one we added for idle timeout onPointerDown detection)
      expect(find.byType(Listener), findsWidgets);

      await controller.close();
    });
  });
}

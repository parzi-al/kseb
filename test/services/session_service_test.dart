import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/services/session_service.dart';

void main() {
  group('SessionService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late SessionService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = SessionService(firestore: fakeFirestore);
    });

    Future<void> _createUserDoc(String userId) async {
      await fakeFirestore.collection('users').doc(userId).set({
        'name': 'Test User',
        'email': 'test@kseb.in',
        'phone': '1234567890',
        'role': 'staff',
      });
    }

    group('createSession', () {
      test('returns a session token with correct format', () async {
        await _createUserDoc('user1');
        final token = await service.createSession('user1');

        expect(token, isNotEmpty);
        expect(token, startsWith('sess_'));
      });

      test('writes token to user document', () async {
        await _createUserDoc('user1');
        final token = await service.createSession('user1');

        final doc = await fakeFirestore.collection('users').doc('user1').get();
        expect(doc.data()!['activeSessionToken'], token);
      });

      test('generates unique tokens on each call', () async {
        await _createUserDoc('user1');
        final token1 = await service.createSession('user1');
        // Small delay to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 10));
        final token2 = await service.createSession('user1');

        expect(token1, isNot(token2));
      });
    });

    group('clearSession', () {
      test('sets activeSessionToken to null', () async {
        await _createUserDoc('user1');
        await service.createSession('user1');

        await service.clearSession('user1');

        final doc = await fakeFirestore.collection('users').doc('user1').get();
        expect(doc.data()!['activeSessionToken'], isNull);
      });
    });

    group('isSessionValid', () {
      test('returns true when tokens match', () async {
        await _createUserDoc('user1');
        final token = await service.createSession('user1');

        final isValid = await service.isSessionValid('user1', token);
        expect(isValid, isTrue);
      });

      test('returns false when tokens differ (another device logged in)',
          () async {
        await _createUserDoc('user1');
        final token1 = await service.createSession('user1');
        // Simulate another device logging in
        await Future.delayed(const Duration(milliseconds: 10));
        await service.createSession('user1'); // overwrites with new token

        final isValid = await service.isSessionValid('user1', token1);
        expect(isValid, isFalse);
      });

      test('returns false when user doc does not exist', () async {
        final isValid =
            await service.isSessionValid('nonexistent', 'some_token');
        expect(isValid, isFalse);
      });

      test('returns false when activeSessionToken is null (logged out)',
          () async {
        await _createUserDoc('user1');
        await service.createSession('user1');
        await service.clearSession('user1');

        final isValid = await service.isSessionValid('user1', 'any_token');
        expect(isValid, isFalse);
      });
    });
  });
}

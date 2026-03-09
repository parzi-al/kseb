import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/services/login_rate_limiter.dart';

void main() {
  group('LoginRateLimiter', () {
    late LoginRateLimiter limiter;

    setUp(() {
      limiter = LoginRateLimiter();
    });

    tearDown(() {
      limiter.dispose();
    });

    test('initial state: no failures, no cooldown', () {
      expect(limiter.failedAttempts, 0);
      expect(limiter.isInCooldown, isFalse);
      expect(limiter.remainingSeconds, 0);
    });

    test('recordFailure increments failedAttempts', () {
      limiter.recordFailure();
      expect(limiter.failedAttempts, 1);

      limiter.recordFailure();
      expect(limiter.failedAttempts, 2);
    });

    test('no cooldown below threshold (< 3 failures)', () {
      limiter.recordFailure();
      limiter.recordFailure();
      expect(limiter.failedAttempts, 2);
      expect(limiter.isInCooldown, isFalse);
    });

    test('cooldown of 5s after 3 failures', () {
      for (int i = 0; i < 3; i++) {
        limiter.recordFailure();
      }
      expect(limiter.failedAttempts, 3);
      expect(limiter.isInCooldown, isTrue);
      expect(limiter.remainingSeconds, 5);
    });

    test('cooldown of 15s after 5 failures', () {
      for (int i = 0; i < 5; i++) {
        limiter.recordFailure();
      }
      expect(limiter.failedAttempts, 5);
      expect(limiter.isInCooldown, isTrue);
      expect(limiter.remainingSeconds, 15);
    });

    test('cooldown of 30s after 8 failures', () {
      for (int i = 0; i < 8; i++) {
        limiter.recordFailure();
      }
      expect(limiter.failedAttempts, 8);
      expect(limiter.isInCooldown, isTrue);
      expect(limiter.remainingSeconds, 30);
    });

    test('cooldown stays at 30s for more than 8 failures', () {
      for (int i = 0; i < 12; i++) {
        limiter.recordFailure();
      }
      expect(limiter.failedAttempts, 12);
      expect(limiter.isInCooldown, isTrue);
      expect(limiter.remainingSeconds, 30);
    });

    test('reset clears all state', () {
      for (int i = 0; i < 5; i++) {
        limiter.recordFailure();
      }
      expect(limiter.isInCooldown, isTrue);

      limiter.reset();

      expect(limiter.failedAttempts, 0);
      expect(limiter.isInCooldown, isFalse);
      expect(limiter.remainingSeconds, 0);
    });

    test('cooldownStream emits remaining seconds', () async {
      final emitted = <int>[];
      final sub = limiter.cooldownStream.listen(emitted.add);

      // 3 failures → 5s cooldown
      for (int i = 0; i < 3; i++) {
        limiter.recordFailure();
      }

      // Give it a moment for the initial emission
      await Future.delayed(const Duration(milliseconds: 50));

      expect(emitted.isNotEmpty, isTrue);
      expect(emitted.last, 5); // Initial emission is 5 seconds

      await sub.cancel();
    });

    test('reset emits 0 on cooldownStream', () async {
      final emitted = <int>[];
      final sub = limiter.cooldownStream.listen(emitted.add);

      for (int i = 0; i < 3; i++) {
        limiter.recordFailure();
      }

      await Future.delayed(const Duration(milliseconds: 50));

      limiter.reset();

      await Future.delayed(const Duration(milliseconds: 50));

      expect(emitted.last, 0);

      await sub.cancel();
    });

    test('4 failures uses the 3-failure threshold (5s)', () {
      for (int i = 0; i < 4; i++) {
        limiter.recordFailure();
      }
      expect(limiter.failedAttempts, 4);
      expect(limiter.isInCooldown, isTrue);
      expect(limiter.remainingSeconds, 5);
    });

    test('7 failures uses the 5-failure threshold (15s)', () {
      for (int i = 0; i < 7; i++) {
        limiter.recordFailure();
      }
      expect(limiter.failedAttempts, 7);
      expect(limiter.isInCooldown, isTrue);
      expect(limiter.remainingSeconds, 15);
    });
  });
}

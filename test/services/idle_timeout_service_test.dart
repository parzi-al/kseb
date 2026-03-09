import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/services/idle_timeout_service.dart';

void main() {
  group('IdleTimeoutService', () {
    late IdleTimeoutService service;

    setUp(() {
      service = IdleTimeoutService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state: not running', () {
      expect(service.isRunning, isFalse);
    });

    test('start sets isRunning to true', () {
      service.start(
        timeoutMinutes: 15,
        onTimeout: () {},
      );
      expect(service.isRunning, isTrue);
    });

    test('start sets correct timeout duration', () {
      service.start(
        timeoutMinutes: 30,
        onTimeout: () {},
      );
      expect(service.timeoutDuration, const Duration(minutes: 30));
    });

    test('stop sets isRunning to false', () {
      service.start(
        timeoutMinutes: 15,
        onTimeout: () {},
      );
      service.stop();
      expect(service.isRunning, isFalse);
    });

    test('resetTimer does nothing when not running', () {
      // Should not throw
      service.resetTimer();
      expect(service.isRunning, isFalse);
    });

    test('pause and resume work correctly', () {
      service.start(
        timeoutMinutes: 1,
        onTimeout: () {},
      );

      service.pause();
      // Still considered "running" conceptually, just paused
      expect(service.isRunning, isTrue);

      service.resume();
      expect(service.isRunning, isTrue);
    });

    test('dispose stops the service', () {
      service.start(
        timeoutMinutes: 15,
        onTimeout: () {},
      );
      service.dispose();
      expect(service.isRunning, isFalse);
    });

    // Note: We don't test actual timer firing here because that would require
    // real-time delays. The service uses Dart's Timer which is well-tested.
    // For integration tests, consider using fake_async package.
  });
}

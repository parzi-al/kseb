import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/screens/splash_screen.dart';
import 'package:kseb/utils/animation_constants.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('SplashScreen', () {
    testWidgets('renders lightning bolt icon and KSEB text', (tester) async {
      await tester.pumpWidget(
        createTestApp(const SplashScreen(testMode: true)),
      );
      // Let the first frame render
      await tester.pump();

      // Icon should be present (lightning bolt / flash_on)
      expect(find.byIcon(Icons.flash_on), findsOneWidget);

      // "KSEB" text should be present
      expect(find.text(AnimationConstants.appName), findsOneWidget);

      // Clean up pending timers by pumping through entire sequence
      await tester.pump(AnimationConstants.splashMinDuration);
      await tester.pump(AnimationConstants.splashCrossFadeDuration);
      await tester.pump(AnimationConstants.splashMaxDuration);
      await tester.pumpAndSettle();
    });

    testWidgets('shows splash content initially', (tester) async {
      await tester.pumpWidget(
        createTestApp(const SplashScreen(testMode: true)),
      );
      await tester.pump();

      // The splash screen should be visible
      expect(find.byType(SplashScreen), findsOneWidget);

      // Clean up
      await tester.pump(AnimationConstants.splashMinDuration);
      await tester.pump(AnimationConstants.splashCrossFadeDuration);
      await tester.pump(AnimationConstants.splashMaxDuration);
      await tester.pumpAndSettle();
    });

    testWidgets('transitions to destination after min duration',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(const SplashScreen(testMode: true)),
      );
      await tester.pump();

      // Auth resolves at 100ms, sequence completes at 1500ms
      // Pump past auth resolution
      await tester.pump(const Duration(milliseconds: 200));
      // Pump to end of sequence
      await tester.pump(const Duration(milliseconds: 1400));
      // Pump through cross-fade
      await tester.pump(AnimationConstants.splashCrossFadeDuration);
      // Let navigation settle
      await tester.pump(AnimationConstants.splashMaxDuration);
      await tester.pumpAndSettle();

      // After transition, splash should have navigated away
      expect(find.byType(SplashScreen), findsNothing);
      expect(find.text('Test Destination'), findsOneWidget);
    });

    testWidgets('reduce-motion shows static frame without animation',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: createTestTheme(),
            home: const SplashScreen(testMode: true),
          ),
        ),
      );
      await tester.pump();

      // Icons and text should render (static frame)
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
      expect(find.text(AnimationConstants.appName), findsOneWidget);

      // Auth resolves at 100ms — pump past it
      await tester.pump(const Duration(milliseconds: 200));
      // With reduced motion the sequence value was set to 1.0 instantly,
      // so tryTransition should navigate immediately
      await tester.pump(AnimationConstants.splashMaxDuration);
      await tester.pumpAndSettle();

      // Should have navigated away
      expect(find.byType(SplashScreen), findsNothing);
    });

    testWidgets('shows loading indicator if auth exceeds max duration',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const SplashScreen(testMode: true, simulateSlowAuth: true),
        ),
      );
      await tester.pump();

      // Pump past max duration
      await tester.pump(AnimationConstants.splashMaxDuration);
      await tester.pump(const Duration(milliseconds: 100));

      // Loading indicator should now be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Clean up by reaching auth resolution time
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(AnimationConstants.splashCrossFadeDuration);
      await tester.pumpAndSettle();
    });
  });
}

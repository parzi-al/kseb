import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/screens/splash_screen.dart';
import 'package:kseb/utils/animation_constants.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('SplashScreen (pure animation widget)', () {
    testWidgets('renders lightning bolt icon and KSEB text', (tester) async {
      await tester.pumpWidget(
        createTestApp(const SplashScreen()),
      );
      await tester.pump();

      // Icon should be present (lightning bolt / flash_on)
      expect(find.byIcon(Icons.flash_on), findsOneWidget);

      // "KSEB" text should be present
      expect(find.text(AnimationConstants.appName), findsOneWidget);

      // Clean up pending timers
      await tester.pump(AnimationConstants.splashMinDuration);
      await tester.pumpAndSettle();
    });

    testWidgets('shows splash content initially', (tester) async {
      await tester.pumpWidget(
        createTestApp(const SplashScreen()),
      );
      await tester.pump();

      // The splash screen should be visible
      expect(find.byType(SplashScreen), findsOneWidget);

      // Clean up
      await tester.pump(AnimationConstants.splashMinDuration);
      await tester.pumpAndSettle();
    });

    testWidgets('animation plays through full sequence', (tester) async {
      await tester.pumpWidget(
        createTestApp(const SplashScreen()),
      );
      await tester.pump();

      // Pump through the full animation
      await tester.pump(AnimationConstants.splashMinDuration);
      await tester.pumpAndSettle();

      // Icon and text should still be visible after animation
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
      expect(find.text(AnimationConstants.appName), findsOneWidget);
    });

    testWidgets('reduce-motion shows static frame without animation',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: createTestTheme(),
            home: const SplashScreen(),
          ),
        ),
      );
      await tester.pump();

      // Icons and text should render (static frame)
      expect(find.byIcon(Icons.flash_on), findsOneWidget);
      expect(find.text(AnimationConstants.appName), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });
}

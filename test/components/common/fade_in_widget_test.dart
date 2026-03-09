import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/components/common/fade_in_widget.dart';
import 'package:kseb/utils/animation_constants.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('FadeInWidget', () {
    testWidgets('child fades in over contentFadeInDuration', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const FadeInWidget(
            child: Text('Fading'),
          ),
        ),
      );

      // Should find a FadeTransition
      expect(
        find.descendant(
          of: find.byType(FadeInWidget),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );

      // Initially the opacity should be 0
      final fadeInitial = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(FadeInWidget),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fadeInitial.opacity.value, closeTo(0.0, 0.01));

      // Pump through the full animation
      await tester.pump(AnimationConstants.contentFadeInDuration);
      await tester.pumpAndSettle();

      // After animation, opacity should be 1.0
      final fadeFinal = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(FadeInWidget),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fadeFinal.opacity.value, closeTo(1.0, 0.01));
    });

    testWidgets('custom duration override works', (tester) async {
      const customDuration = Duration(milliseconds: 500);

      await tester.pumpWidget(
        createTestApp(
          const FadeInWidget(
            duration: customDuration,
            child: Text('Custom'),
          ),
        ),
      );

      // Initially opacity should be 0
      final fadeInitial = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(FadeInWidget),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fadeInitial.opacity.value, closeTo(0.0, 0.01));

      // Pump halfway through custom duration
      await tester.pump(const Duration(milliseconds: 250));
      final fadeMiddle = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(FadeInWidget),
          matching: find.byType(FadeTransition),
        ),
      );
      // Should be partially faded in
      expect(fadeMiddle.opacity.value, greaterThan(0.0));
      expect(fadeMiddle.opacity.value, lessThan(1.0));

      // Pump to full duration
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
    });

    testWidgets('reduce-motion shows instantly', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: createTestTheme(),
            home: Scaffold(
              body: const FadeInWidget(
                child: Text('Instant'),
              ),
            ),
          ),
        ),
      );

      // With reduce-motion, opacity should be 1.0 immediately
      await tester.pump();

      final fade = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(FadeInWidget),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fade.opacity.value, closeTo(1.0, 0.01));
    });
  });
}

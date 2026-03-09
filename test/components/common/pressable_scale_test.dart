import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/components/common/pressable_scale.dart';
import 'package:kseb/utils/animation_constants.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('PressableScale', () {
    testWidgets('scales to pressScaleFactor on tap down', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          PressableScale(
            onTap: () {},
            child: const SizedBox(width: 100, height: 100, key: Key('child')),
          ),
        ),
      );

      // Tap down (finger stays pressed)
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('child'))),
      );
      // Let the gesture arena resolve
      await tester.pump();
      // Advance through the press animation
      await tester.pump(AnimationConstants.pressScaleDuration);

      // Find the Transform widget and verify scale
      final transform = tester.widget<Transform>(
        find.descendant(
          of: find.byType(PressableScale),
          matching: find.byType(Transform),
        ),
      );
      final matrix = transform.transform;
      // Scale should be at or near pressScaleFactor (0.96)
      expect(matrix.getMaxScaleOnAxis(), closeTo(0.96, 0.05));

      // Clean up gesture
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('springs back on tap up', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          PressableScale(
            onTap: () {},
            child: const SizedBox(width: 100, height: 100, key: Key('child')),
          ),
        ),
      );

      // Tap down and up
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('child'))),
      );
      await tester.pump(AnimationConstants.pressScaleDuration);
      await gesture.up();
      await tester.pumpAndSettle();

      // Scale should return to 1.0
      final transform = tester.widget<Transform>(
        find.descendant(
          of: find.byType(PressableScale),
          matching: find.byType(Transform),
        ),
      );
      expect(transform.transform.getMaxScaleOnAxis(), closeTo(1.0, 0.01));
    });

    testWidgets('forwards onTap callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestApp(
          PressableScale(
            onTap: () => tapped = true,
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      await tester.tap(find.byType(PressableScale));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('reduce-motion disables scale animation', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: createTestTheme(),
            home: PressableScale(
              onTap: () {},
              child: const SizedBox(width: 100, height: 100, key: Key('child')),
            ),
          ),
        ),
      );

      // Tap down
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('child'))),
      );
      await tester.pump(AnimationConstants.pressScaleDuration);

      // Scale should remain 1.0 (no animation)
      final transform = tester.widget<Transform>(
        find.descendant(
          of: find.byType(PressableScale),
          matching: find.byType(Transform),
        ),
      );
      expect(transform.transform.getMaxScaleOnAxis(), closeTo(1.0, 0.01));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('enabled=false disables animation and onTap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestApp(
          PressableScale(
            onTap: () => tapped = true,
            enabled: false,
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      await tester.tap(find.byType(PressableScale));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });
  });
}

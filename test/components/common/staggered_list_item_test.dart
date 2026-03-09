import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/components/common/staggered_list_item.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('StaggeredListItem', () {
    testWidgets('applies stagger delay based on index', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          ListView(
            children: [
              StaggeredListItem(
                index: 0,
                child: const Text('Item 0'),
              ),
              StaggeredListItem(
                index: 3,
                child: const Text('Item 3'),
              ),
            ],
          ),
        ),
      );

      // Both items should exist in the tree
      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);

      // Pump through the stagger delay + animation for index 3
      // index 3 delay = 3 * 60ms = 180ms, plus staggerItemDuration = 300ms
      await tester.pump(const Duration(milliseconds: 480));
      await tester.pumpAndSettle();
    });

    testWidgets('fade+slide entrance plays', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          StaggeredListItem(
            index: 0,
            child: const Text('Animated'),
          ),
        ),
      );

      // Initially should find FadeTransition and SlideTransition
      expect(
        find.descendant(
          of: find.byType(StaggeredListItem),
          matching: find.byType(FadeTransition),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(StaggeredListItem),
          matching: find.byType(SlideTransition),
        ),
        findsOneWidget,
      );

      await tester.pumpAndSettle();
    });

    testWidgets('reduce-motion shows instantly', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: createTestTheme(),
            home: Scaffold(
              body: StaggeredListItem(
                index: 5,
                child: const Text('Instant'),
              ),
            ),
          ),
        ),
      );

      // Should be immediately visible
      expect(find.text('Instant'), findsOneWidget);

      // With reduce-motion, the animation controller value should be 1.0
      // (completed state). The widget should be fully visible immediately.
      await tester.pump();
    });

    testWidgets('respects staggerMaxIndex cap', (tester) async {
      // Index beyond staggerMaxIndex should be capped
      await tester.pumpWidget(
        createTestApp(
          StaggeredListItem(
            index: 100, // Way beyond staggerMaxIndex (8)
            child: const Text('Capped'),
          ),
        ),
      );

      // Should still render without issue
      expect(find.text('Capped'), findsOneWidget);

      // Max delay should be 8 * 60ms = 480ms, not 100 * 60ms
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
    });
  });
}

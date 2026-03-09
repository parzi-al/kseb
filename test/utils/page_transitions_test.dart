import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/utils/animation_constants.dart';
import 'package:kseb/utils/page_transitions.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('AppRoute', () {
    test('transitionDuration matches AnimationConstants', () {
      final route = AppRoute<void>(
        builder: (_) => const SizedBox(),
      );
      expect(
        route.transitionDuration,
        AnimationConstants.pageTransitionDuration,
      );
    });

    test('reverseTransitionDuration matches AnimationConstants', () {
      final route = AppRoute<void>(
        builder: (_) => const SizedBox(),
      );
      expect(
        route.reverseTransitionDuration,
        AnimationConstants.pageTransitionDuration,
      );
    });

    testWidgets('navigates with slide+fade transition', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme().copyWith(
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                for (final platform in TargetPlatform.values)
                  platform: const AppPageTransition(),
              },
            ),
          ),
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  AppRoute<void>(
                    builder: (_) => const Scaffold(
                      body: Text('Destination'),
                    ),
                  ),
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      // Tap to navigate
      await tester.tap(find.text('Navigate'));
      await tester.pump();

      // During transition, destination should be appearing
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Destination'), findsOneWidget);

      // After full transition
      await tester.pumpAndSettle();
      expect(find.text('Destination'), findsOneWidget);
      expect(find.text('Navigate'), findsNothing);
    });
  });

  group('AppPageTransition', () {
    testWidgets('buildTransitions returns ScaleTransition + FadeTransition',
        (tester) async {
      const builder = AppPageTransition();

      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme(),
          home: Builder(
            builder: (context) {
              final animation = AnimationController(
                vsync: tester,
                duration: AnimationConstants.pageTransitionDuration,
              );
              addTearDown(animation.dispose);

              final secondaryAnimation = AnimationController(
                vsync: tester,
                duration: AnimationConstants.pageTransitionDuration,
              );
              addTearDown(secondaryAnimation.dispose);

              // Create a mock route for testing
              final route = AppRoute<void>(
                builder: (_) => const SizedBox(),
              );

              final result = builder.buildTransitions<void>(
                route,
                context,
                animation,
                secondaryAnimation,
                const Text('Child'),
              );

              // Should produce a ScaleTransition wrapping a FadeTransition
              expect(result, isA<ScaleTransition>());
              final scale = result as ScaleTransition;
              expect(scale.child, isA<FadeTransition>());
              final fade = scale.child as FadeTransition;
              expect(fade.child, isA<Text>());

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('reduce-motion returns child directly', (tester) async {
      const builder = AppPageTransition();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: createTestTheme(),
            home: Builder(
              builder: (context) {
                final animation = AnimationController(
                  vsync: tester,
                  duration: AnimationConstants.pageTransitionDuration,
                );
                addTearDown(animation.dispose);

                final secondaryAnimation = AnimationController(
                  vsync: tester,
                  duration: AnimationConstants.pageTransitionDuration,
                );
                addTearDown(secondaryAnimation.dispose);

                final route = AppRoute<void>(
                  builder: (_) => const SizedBox(),
                );

                final child = const Text('Instant');
                final result = builder.buildTransitions<void>(
                  route,
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                );

                // Should return child directly when reduce-motion is on
                expect(result, same(child));

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('reverse animation works (back navigation)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createTestTheme().copyWith(
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                for (final platform in TargetPlatform.values)
                  platform: const AppPageTransition(),
              },
            ),
          ),
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  AppRoute<void>(
                    builder: (ctx) => ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Go Back'),
                    ),
                  ),
                );
              },
              child: const Text('Go Forward'),
            ),
          ),
        ),
      );

      // Navigate forward
      await tester.tap(find.text('Go Forward'));
      await tester.pumpAndSettle();
      expect(find.text('Go Back'), findsOneWidget);

      // Navigate back
      await tester.tap(find.text('Go Back'));
      await tester.pumpAndSettle();
      expect(find.text('Go Forward'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/utils/animation_constants.dart';

void main() {
  group('AnimationConstants', () {
    // ── Splash Screen Constants ───────────────────────────────────
    test('splashMinDuration is 1500ms', () {
      expect(
        AnimationConstants.splashMinDuration,
        const Duration(milliseconds: 1500),
      );
    });

    test('splashMaxDuration is 2500ms', () {
      expect(
        AnimationConstants.splashMaxDuration,
        const Duration(milliseconds: 2500),
      );
    });

    test('splashIconScaleDuration is 800ms', () {
      expect(
        AnimationConstants.splashIconScaleDuration,
        const Duration(milliseconds: 800),
      );
    });

    test('splashTextSlideDuration is 500ms', () {
      expect(
        AnimationConstants.splashTextSlideDuration,
        const Duration(milliseconds: 500),
      );
    });

    test('splashCrossFadeDuration is 400ms', () {
      expect(
        AnimationConstants.splashCrossFadeDuration,
        const Duration(milliseconds: 400),
      );
    });

    // ── Page Transition Constants ─────────────────────────────────
    test('pageTransitionDuration is 250ms', () {
      expect(
        AnimationConstants.pageTransitionDuration,
        const Duration(milliseconds: 250),
      );
    });

    test('pageTransitionCurve is easeOut', () {
      expect(AnimationConstants.pageTransitionCurve, Curves.easeOut);
    });

    // ── Press-Scale Constants ─────────────────────────────────────
    test('pressScaleFactor is 0.96', () {
      expect(AnimationConstants.pressScaleFactor, 0.96);
    });

    test('pressScaleDuration is 120ms', () {
      expect(
        AnimationConstants.pressScaleDuration,
        const Duration(milliseconds: 120),
      );
    });

    test('pressScaleCurve is easeOutBack', () {
      expect(AnimationConstants.pressScaleCurve, Curves.easeOutBack);
    });

    // ── Content Fade-In Constants ─────────────────────────────────
    test('contentFadeInDuration is 250ms', () {
      expect(
        AnimationConstants.contentFadeInDuration,
        const Duration(milliseconds: 250),
      );
    });

    // ── Staggered List Constants ──────────────────────────────────
    test('staggerDelayPerItem is 60ms', () {
      expect(
        AnimationConstants.staggerDelayPerItem,
        const Duration(milliseconds: 60),
      );
    });

    test('staggerMaxIndex is 8', () {
      expect(AnimationConstants.staggerMaxIndex, 8);
    });

    test('staggerItemDuration is 300ms', () {
      expect(
        AnimationConstants.staggerItemDuration,
        const Duration(milliseconds: 300),
      );
    });

    test('staggerSlideOffset is 0.08', () {
      expect(AnimationConstants.staggerSlideOffset, 0.08);
    });

    test('staggerCurve is easeOut', () {
      expect(AnimationConstants.staggerCurve, Curves.easeOut);
    });

    // ── Configurable Strings ──────────────────────────────────────
    test('appName is KSEB', () {
      expect(AnimationConstants.appName, 'KSEB');
    });

    // ── Relationships ─────────────────────────────────────────────
    test('splashMinDuration is less than splashMaxDuration', () {
      expect(
        AnimationConstants.splashMinDuration,
        lessThan(AnimationConstants.splashMaxDuration),
      );
    });

    test('splashIconScale + textSlide fits within splashMinDuration', () {
      final totalAnimTime = AnimationConstants.splashIconScaleDuration +
          AnimationConstants.splashTextSlideDuration;
      expect(totalAnimTime,
          lessThanOrEqualTo(AnimationConstants.splashMinDuration));
    });
  });

  group('respectMotion', () {
    testWidgets('returns normal duration when animations are enabled',
        (tester) async {
      const testDuration = Duration(milliseconds: 300);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              final result = respectMotion(context, testDuration);
              expect(result, testDuration);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('returns Duration.zero when animations are disabled',
        (tester) async {
      const testDuration = Duration(milliseconds: 300);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              final result = respectMotion(context, testDuration);
              expect(result, Duration.zero);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('handles zero duration input gracefully', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              final result = respectMotion(context, Duration.zero);
              expect(result, Duration.zero);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });
}

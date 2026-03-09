import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/utils/app_spacing.dart';

void main() {
  group('AppSpacing — Spacing Scale', () {
    test('spacing values are monotonically increasing', () {
      final values = [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.base,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.page,
      ];
      for (var i = 0; i < values.length - 1; i++) {
        expect(values[i] < values[i + 1], isTrue,
            reason: 'Spacing at index $i should be less than index ${i + 1}');
      }
    });

    test('xs is 4.0', () => expect(AppSpacing.xs, 4.0));
    test('sm is 8.0', () => expect(AppSpacing.sm, 8.0));
    test('md is 12.0', () => expect(AppSpacing.md, 12.0));
    test('base is 16.0', () => expect(AppSpacing.base, 16.0));
    test('lg is 20.0', () => expect(AppSpacing.lg, 20.0));
    test('xl is 24.0', () => expect(AppSpacing.xl, 24.0));
    test('xxl is 32.0', () => expect(AppSpacing.xxl, 32.0));
    test('page is 40.0', () => expect(AppSpacing.page, 40.0));
  });

  group('AppSpacing — Border Radius Scale', () {
    test('radius values are monotonically increasing', () {
      final values = [
        AppSpacing.radiusSm,
        AppSpacing.radiusMd,
        AppSpacing.radiusDefault,
        AppSpacing.radiusLg,
        AppSpacing.radiusPill,
      ];
      for (var i = 0; i < values.length - 1; i++) {
        expect(values[i] < values[i + 1], isTrue,
            reason: 'Radius at index $i should be less than index ${i + 1}');
      }
    });

    test('radiusSm is 8.0', () => expect(AppSpacing.radiusSm, 8.0));
    test('radiusMd is 12.0', () => expect(AppSpacing.radiusMd, 12.0));
    test('radiusDefault is 16.0', () => expect(AppSpacing.radiusDefault, 16.0));
    test('radiusLg is 20.0', () => expect(AppSpacing.radiusLg, 20.0));
    test('radiusPill is 100.0', () => expect(AppSpacing.radiusPill, 100.0));
  });

  group('AppSpacing — Shadow Presets', () {
    test('shadowNone is empty', () {
      expect(AppSpacing.shadowNone, isEmpty);
    });

    test('shadowLight has 2 layers', () {
      expect(AppSpacing.shadowLight.length, 2);
    });

    test('shadowMedium has 2 layers', () {
      expect(AppSpacing.shadowMedium.length, 2);
    });

    test('shadowHeavy has 2 layers', () {
      expect(AppSpacing.shadowHeavy.length, 2);
    });
  });
}

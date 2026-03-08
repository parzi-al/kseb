import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/utils/app_typography.dart';
import 'package:kseb/utils/app_colors.dart';

void main() {
  group('AppTypography — Font Size Scale', () {
    test('font sizes are monotonically increasing', () {
      final sizes = [
        AppTypography.fontSizeXS,
        AppTypography.fontSizeSM,
        AppTypography.fontSizeBase,
        AppTypography.fontSizeLG,
        AppTypography.fontSizeXL,
        AppTypography.fontSize2XL,
        AppTypography.fontSize3XL,
        AppTypography.fontSize4XL,
      ];
      for (var i = 0; i < sizes.length - 1; i++) {
        expect(sizes[i] < sizes[i + 1], isTrue,
            reason: 'Font size at index $i should be less than index ${i + 1}');
      }
    });

    test('fontSizeXS is 11.0', () {
      expect(AppTypography.fontSizeXS, 11.0);
    });
    test('fontSizeSM is 12.0', () {
      expect(AppTypography.fontSizeSM, 12.0);
    });
    test('fontSizeBase is 14.0', () {
      expect(AppTypography.fontSizeBase, 14.0);
    });
    test('fontSizeLG is 16.0', () {
      expect(AppTypography.fontSizeLG, 16.0);
    });
    test('fontSizeXL is 18.0', () {
      expect(AppTypography.fontSizeXL, 18.0);
    });
    test('fontSize2XL is 20.0', () {
      expect(AppTypography.fontSize2XL, 20.0);
    });
    test('fontSize3XL is 24.0', () {
      expect(AppTypography.fontSize3XL, 24.0);
    });
    test('fontSize4XL is 28.0', () {
      expect(AppTypography.fontSize4XL, 28.0);
    });
  });

  group('AppTypography — Named TextStyles', () {
    test('displayLargeStyle: 28sp w800 textPrimary', () {
      final s = AppTypography.displayLargeStyle;
      expect(s.fontSize, AppTypography.fontSize4XL);
      expect(s.fontWeight, FontWeight.w800);
      expect(s.color, AppColors.textPrimary);
    });

    test('displayStyle: 24sp w700 textPrimary', () {
      final s = AppTypography.displayStyle;
      expect(s.fontSize, AppTypography.fontSize3XL);
      expect(s.fontWeight, FontWeight.w700);
      expect(s.color, AppColors.textPrimary);
    });

    test('titleStyle: 20sp w700 textPrimary', () {
      final s = AppTypography.titleStyle;
      expect(s.fontSize, AppTypography.fontSize2XL);
      expect(s.fontWeight, FontWeight.w700);
      expect(s.color, AppColors.textPrimary);
    });

    test('headingStyle: 18sp w600 textPrimary', () {
      final s = AppTypography.headingStyle;
      expect(s.fontSize, AppTypography.fontSizeXL);
      expect(s.fontWeight, FontWeight.w600);
      expect(s.color, AppColors.textPrimary);
    });

    test('subheadingStyle: 16sp w600 textPrimary', () {
      final s = AppTypography.subheadingStyle;
      expect(s.fontSize, AppTypography.fontSizeLG);
      expect(s.fontWeight, FontWeight.w600);
      expect(s.color, AppColors.textPrimary);
    });

    test('bodyMediumStyle: 14sp w500 textPrimary', () {
      final s = AppTypography.bodyMediumStyle;
      expect(s.fontSize, AppTypography.fontSizeBase);
      expect(s.fontWeight, FontWeight.w500);
      expect(s.color, AppColors.textPrimary);
    });

    test('bodyStyle: 14sp w400 textPrimary', () {
      final s = AppTypography.bodyStyle;
      expect(s.fontSize, AppTypography.fontSizeBase);
      expect(s.fontWeight, FontWeight.w400);
      expect(s.color, AppColors.textPrimary);
    });

    test('captionStyle: 12sp w400 textSecondary', () {
      final s = AppTypography.captionStyle;
      expect(s.fontSize, AppTypography.fontSizeSM);
      expect(s.fontWeight, FontWeight.w400);
      expect(s.color, AppColors.textSecondary);
    });
  });
}

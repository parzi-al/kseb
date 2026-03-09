import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/utils/app_colors.dart';

void main() {
  group('AppColors — Primary Palette', () {
    test('primary is #FF6B35', () {
      expect(AppColors.primary, const Color(0xFFFF6B35));
    });
    test('primaryLight is #FF8A65', () {
      expect(AppColors.primaryLight, const Color(0xFFFF8A65));
    });
    test('primaryDark is #E64A19', () {
      expect(AppColors.primaryDark, const Color(0xFFE64A19));
    });
  });

  group('AppColors — Secondary & Accent', () {
    test('secondary is #6C5CE7', () {
      expect(AppColors.secondary, const Color(0xFF6C5CE7));
    });
    test('accent is #00D4AA', () {
      expect(AppColors.accent, const Color(0xFF00D4AA));
    });
    test('purple is #9B59B6', () {
      expect(AppColors.purple, const Color(0xFF9B59B6));
    });
  });

  group('AppColors — Status Colors', () {
    test('success is #27AE60', () {
      expect(AppColors.success, const Color(0xFF27AE60));
    });
    test('warning is #F39C12', () {
      expect(AppColors.warning, const Color(0xFFF39C12));
    });
    test('error is #E74C3C', () {
      expect(AppColors.error, const Color(0xFFE74C3C));
    });
    test('info is #3498DB', () {
      expect(AppColors.info, const Color(0xFF3498DB));
    });
  });

  group('AppColors — Neutral Scale', () {
    test('white is #FFFFFF', () {
      expect(AppColors.white, const Color(0xFFFFFFFF));
    });
    test('black is #1A1A1A', () {
      expect(AppColors.black, const Color(0xFF1A1A1A));
    });
    test('grey50 is #FCFCFC', () {
      expect(AppColors.grey50, const Color(0xFFFCFCFC));
    });
    test('grey100 is #F8F9FA', () {
      expect(AppColors.grey100, const Color(0xFFF8F9FA));
    });
    test('grey200 is #E9ECEF', () {
      expect(AppColors.grey200, const Color(0xFFE9ECEF));
    });
    test('grey300 is #DEE2E6', () {
      expect(AppColors.grey300, const Color(0xFFDEE2E6));
    });
    test('grey400 is #CED4DA', () {
      expect(AppColors.grey400, const Color(0xFFCED4DA));
    });
    test('grey500 is #6C757D', () {
      expect(AppColors.grey500, const Color(0xFF6C757D));
    });
    test('grey600 is #495057', () {
      expect(AppColors.grey600, const Color(0xFF495057));
    });
    test('grey700 is #343A40', () {
      expect(AppColors.grey700, const Color(0xFF343A40));
    });
    test('grey800 is #212529', () {
      expect(AppColors.grey800, const Color(0xFF212529));
    });
    test('grey900 is #1A1A1A', () {
      expect(AppColors.grey900, const Color(0xFF1A1A1A));
    });
  });

  group('AppColors — Semantic Aliases', () {
    test('background maps to white', () {
      expect(AppColors.background, AppColors.white);
    });
    test('surface maps to white', () {
      expect(AppColors.surface, AppColors.white);
    });
    test('surfaceVariant maps to grey50', () {
      expect(AppColors.surfaceVariant, AppColors.grey50);
    });
    test('textPrimary maps to grey800', () {
      expect(AppColors.textPrimary, AppColors.grey800);
    });
    test('textSecondary maps to grey500', () {
      expect(AppColors.textSecondary, AppColors.grey500);
    });
    test('textOnPrimary maps to white', () {
      expect(AppColors.textOnPrimary, AppColors.white);
    });
  });

  group('AppColors — Dashboard Card Colors', () {
    test('has 4 entries in correct order', () {
      expect(AppColors.dashboardCardColors.length, 4);
      expect(AppColors.dashboardCardColors[0], const Color(0xFF6C5CE7));
      expect(AppColors.dashboardCardColors[1], const Color(0xFF00D4AA));
      expect(AppColors.dashboardCardColors[2], const Color(0xFF3498DB));
      expect(AppColors.dashboardCardColors[3], const Color(0xFFFF6B35));
    });
  });
}

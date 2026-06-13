import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Decoration tokens and responsive helpers for the AumLux design system.
///
/// Provides card decoration presets and BuildContext extensions for
/// responsive scaling of spacing, padding, and font sizes.
abstract final class AppDecorations {
  // ── Card Decorations ──────────────────────────────────────────────

  /// Standard card decoration — surface bg, 16px radius, 2-layer light shadow.
  static BoxDecoration get modernCardDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        boxShadow: AppSpacing.shadowLight,
      );

  /// Colored-border card variant — surface bg, 16px radius, accent border, 1-layer shadow.
  static BoxDecoration modernCardDecorationWithColor(Color color) =>
      BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
}

/// Responsive scaling helpers as BuildContext extensions.
///
/// Usage:
/// ```dart
/// context.responsivePadding(AppSpacing.xl)
/// context.responsiveTextStyle(AppTypography.headingStyle)
/// ```
extension ResponsiveExtensions on BuildContext {
  double _screenHeight() => MediaQuery.of(this).size.height;
  double _screenWidth() => MediaQuery.of(this).size.width;

  /// Linear scale based on screen height relative to iPhone 14 (844px).
  double responsiveHeight(double baseHeight) {
    return baseHeight * (_screenHeight() / 844.0);
  }

  /// Linear scale based on screen width relative to iPhone 14 (390px).
  double responsiveWidth(double baseWidth) {
    return baseWidth * (_screenWidth() / 390.0);
  }

  /// 3-tier step scaling for padding.
  /// <700: ×0.6, <800: ×0.8, ≥800: ×1.0
  double responsivePadding(double basePadding) {
    final h = _screenHeight();
    if (h < 700) return basePadding * 0.6;
    if (h < 800) return basePadding * 0.8;
    return basePadding;
  }

  /// 3-tier step scaling for spacing.
  /// <700: ×0.5, <800: ×0.75, ≥800: ×1.0
  double responsiveSpacing(double baseSpacing) {
    final h = _screenHeight();
    if (h < 700) return baseSpacing * 0.5;
    if (h < 800) return baseSpacing * 0.75;
    return baseSpacing;
  }

  /// 3-tier step scaling for font sizes.
  /// <700: ×0.85, <800: ×0.92, ≥800: ×1.0
  double responsiveFontSize(double baseFontSize) {
    final h = _screenHeight();
    if (h < 700) return baseFontSize * 0.85;
    if (h < 800) return baseFontSize * 0.92;
    return baseFontSize;
  }

  /// Apply responsive font scaling to a TextStyle.
  TextStyle responsiveTextStyle(TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontSize: responsiveFontSize(baseStyle.fontSize ?? 14.0),
    );
  }
}

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography token system for the KSEB design system.
///
/// Provides named TextStyles and font size constants.
/// All screen and widget code should reference these tokens
/// instead of creating inline TextStyle constructors.
abstract final class AppTypography {
  // ── Font Size Scale ───────────────────────────────────────────────
  static const double fontSizeXS = 11.0;
  static const double fontSizeSM = 12.0;
  static const double fontSizeBase = 14.0;
  static const double fontSizeLG = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSize2XL = 20.0;
  static const double fontSize3XL = 24.0;
  static const double fontSize4XL = 28.0;

  // ── Named TextStyles ──────────────────────────────────────────────

  /// Hero text, KSEB branding — 28sp w800
  static TextStyle get displayLargeStyle => TextStyle(
        fontSize: fontSize4XL,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      );

  /// User name, large numbers — 24sp w700
  static TextStyle get displayStyle => TextStyle(
        fontSize: fontSize3XL,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      );

  /// Section titles — 20sp w700
  static TextStyle get titleStyle => TextStyle(
        fontSize: fontSize2XL,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      );

  /// AppBar titles, section headers — 18sp w600
  static TextStyle get headingStyle => TextStyle(
        fontSize: fontSizeXL,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      );

  /// Sub-section headers — 16sp w600
  static TextStyle get subheadingStyle => TextStyle(
        fontSize: fontSizeLG,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      );

  /// Emphasized body text — 14sp w500
  static TextStyle get bodyMediumStyle => TextStyle(
        fontSize: fontSizeBase,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      );

  /// Default body text — 14sp w400
  static TextStyle get bodyStyle => TextStyle(
        fontSize: fontSizeBase,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w400,
      );

  /// Labels, secondary info — 12sp w400
  static TextStyle get captionStyle => TextStyle(
        fontSize: fontSizeSM,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w400,
      );
}

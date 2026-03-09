import 'package:flutter/material.dart';

/// Color token system for the KSEB design system.
///
/// Contains ONLY color tokens. Typography, spacing, decorations,
/// and responsive helpers have been extracted to their own modules.
/// See: [AppTypography], [AppSpacing], [AppDecorations].
abstract final class AppColors {
  // ── Primary Palette ───────────────────────────────────────────────
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8A65);
  static const Color primaryDark = Color(0xFFE64A19);

  // ── Secondary & Accent ────────────────────────────────────────────
  static const Color secondary = Color(0xFF6C5CE7);
  static const Color accent = Color(0xFF00D4AA);
  static const Color purple = Color(0xFF9B59B6);

  // ── Status Colors ─────────────────────────────────────────────────
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // ── Neutral Scale ─────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1A1A1A);
  static const Color grey50 = Color(0xFFFCFCFC);
  static const Color grey100 = Color(0xFFF8F9FA);
  static const Color grey200 = Color(0xFFE9ECEF);
  static const Color grey300 = Color(0xFFDEE2E6);
  static const Color grey400 = Color(0xFFCED4DA);
  static const Color grey500 = Color(0xFF6C757D);
  static const Color grey600 = Color(0xFF495057);
  static const Color grey700 = Color(0xFF343A40);
  static const Color grey800 = Color(0xFF212529);
  static const Color grey900 = Color(0xFF1A1A1A);

  // ── Semantic Aliases ──────────────────────────────────────────────
  static const Color background = white;
  static const Color surface = white;
  static const Color surfaceVariant = grey50;
  static const Color cardShadow = Color(0x08000000);

  // ── Text Colors ───────────────────────────────────────────────────
  static const Color textPrimary = grey800;
  static const Color textSecondary = grey500;
  static const Color textTertiary = grey400;
  static const Color textOnPrimary = white;
  static const Color textOnDark = white;
  static const Color textPlaceholder = grey400;

  // ── Opacity Variants (computed) ───────────────────────────────────
  static Color get primaryWithLowOpacity => primary.withValues(alpha: 0.08);
  static Color get primaryWithMediumOpacity => primary.withValues(alpha: 0.12);
  static Color get primaryWithHighOpacity => primary.withValues(alpha: 0.16);

  static Color get whiteWithLowOpacity => white.withValues(alpha: 0.1);
  static Color get greyWithLowOpacity => grey200.withValues(alpha: 0.5);
  static Color get shadowLight => black.withValues(alpha: 0.04);
  static Color get shadowMedium => black.withValues(alpha: 0.08);
  static Color get shadowDark => black.withValues(alpha: 0.12);

  // ── Dashboard Card Colors (ordered list) ──────────────────────────
  static const List<Color> dashboardCardColors = [
    Color(0xFF6C5CE7), // Purple — Attendance
    Color(0xFF00D4AA), // Teal — History
    Color(0xFF3498DB), // Blue — Worksheet
    Color(0xFFFF6B35), // Orange — Material
  ];

  // ── Status Colors for Stats ───────────────────────────────────────
  static const List<Color> statColors = [
    info,
    success,
  ];

  // ── Gradients ─────────────────────────────────────────────────────
  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryLight],
      );

  static LinearGradient get surfaceGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [white, grey50],
      );

  static LinearGradient cardGradient(Color color) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0.04),
        ],
      );

  // ── Backward-compatibility aliases ────────────────────────────────
  // These delegate to AppTypography / AppSpacing / AppDecorations.
  // Existing code will still compile. Remove once migration is complete.

  @Deprecated('Use AppTypography.fontSizeXS')
  static const double fontSizeXS = 11.0;
  @Deprecated('Use AppTypography.fontSizeSM')
  static const double fontSizeSM = 12.0;
  @Deprecated('Use AppTypography.fontSizeBase')
  static const double fontSizeBase = 14.0;
  @Deprecated('Use AppTypography.fontSizeLG')
  static const double fontSizeLG = 16.0;
  @Deprecated('Use AppTypography.fontSizeXL')
  static const double fontSizeXL = 18.0;
  @Deprecated('Use AppTypography.fontSize2XL')
  static const double fontSize2XL = 20.0;
  @Deprecated('Use AppTypography.fontSize3XL')
  static const double fontSize3XL = 24.0;
  @Deprecated('Use AppTypography.fontSize4XL')
  static const double fontSize4XL = 28.0;

  @Deprecated('Use AppTypography.captionStyle')
  static TextStyle get captionStyle => TextStyle(
        fontSize: fontSizeSM,
        color: textSecondary,
        fontWeight: FontWeight.w400,
      );

  @Deprecated('Use AppTypography.bodyStyle')
  static TextStyle get bodyStyle => TextStyle(
        fontSize: fontSizeBase,
        color: textPrimary,
        fontWeight: FontWeight.w400,
      );

  @Deprecated('Use AppTypography.bodyMediumStyle')
  static TextStyle get bodyMediumStyle => TextStyle(
        fontSize: fontSizeBase,
        color: textPrimary,
        fontWeight: FontWeight.w500,
      );

  @Deprecated('Use AppTypography.subheadingStyle')
  static TextStyle get subheadingStyle => TextStyle(
        fontSize: fontSizeLG,
        color: textPrimary,
        fontWeight: FontWeight.w600,
      );

  @Deprecated('Use AppTypography.headingStyle')
  static TextStyle get headingStyle => TextStyle(
        fontSize: fontSizeXL,
        color: textPrimary,
        fontWeight: FontWeight.w600,
      );

  @Deprecated('Use AppTypography.titleStyle')
  static TextStyle get titleStyle => TextStyle(
        fontSize: fontSize2XL,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      );

  @Deprecated('Use AppTypography.displayStyle')
  static TextStyle get displayStyle => TextStyle(
        fontSize: fontSize3XL,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      );

  @Deprecated('Use AppTypography.displayLargeStyle')
  static TextStyle get displayLargeStyle => TextStyle(
        fontSize: fontSize4XL,
        color: textPrimary,
        fontWeight: FontWeight.w800,
      );

  @Deprecated('Use context.responsiveHeight()')
  static double getResponsiveHeight(BuildContext context, double baseHeight) {
    final screenHeight = MediaQuery.of(context).size.height;
    return baseHeight * (screenHeight / 844.0);
  }

  @Deprecated('Use context.responsiveWidth()')
  static double getResponsiveWidth(BuildContext context, double baseWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    return baseWidth * (screenWidth / 390.0);
  }

  @Deprecated('Use context.responsivePadding()')
  static double getResponsivePadding(BuildContext context, double basePadding) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 700) return basePadding * 0.6;
    if (screenHeight < 800) return basePadding * 0.8;
    return basePadding;
  }

  @Deprecated('Use context.responsiveSpacing()')
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 700) return baseSpacing * 0.5;
    if (screenHeight < 800) return baseSpacing * 0.75;
    return baseSpacing;
  }

  @Deprecated('Use context.responsiveFontSize()')
  static double getResponsiveFontSize(
      BuildContext context, double baseFontSize) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 700) return baseFontSize * 0.85;
    if (screenHeight < 800) return baseFontSize * 0.92;
    return baseFontSize;
  }

  @Deprecated('Use context.responsiveTextStyle()')
  static TextStyle getResponsiveTextStyle(
      BuildContext context, TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontSize:
          getResponsiveFontSize(context, baseStyle.fontSize ?? fontSizeBase),
    );
  }

  @Deprecated('Use AppDecorations.modernCardDecoration')
  static BoxDecoration get modernCardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: shadowMedium,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      );

  @Deprecated('Use AppDecorations.modernCardDecorationWithColor()')
  static BoxDecoration modernCardDecorationWithColor(Color color) =>
      BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
}

import 'package:flutter/material.dart';

class AppColors {
  // Modern Primary Colors (Swiggy/Groww inspired)
  static const Color primary = Color(0xFFFF6B35); // Vibrant Orange
  static const Color primaryLight = Color(0xFFFF8A65); // Light Orange
  static const Color primaryDark = Color(0xFFE64A19); // Dark Orange

  // Accent Colors
  static const Color secondary = Color(0xFF6C5CE7); // Modern Purple
  static const Color accent = Color(0xFF00D4AA); // Fresh Teal
  static const Color purple = Color(0xFF9B59B6); // Rich Purple

  // Status Colors (Modern & Subtle)
  static const Color success = Color(0xFF27AE60); // Fresh Green
  static const Color warning = Color(0xFFF39C12); // Modern Amber
  static const Color error = Color(0xFFE74C3C); // Clean Red
  static const Color info = Color(0xFF3498DB); // Bright Blue

  // Neutral Colors (Clean & Modern)
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1A1A1A); // Softer black
  static const Color grey50 = Color(0xFFFCFCFC); // Ultra light
  static const Color grey100 = Color(0xFFF8F9FA); // Light background
  static const Color grey200 = Color(0xFFE9ECEF); // Border color
  static const Color grey300 = Color(0xFFDEE2E6); // Divider
  static const Color grey400 = Color(0xFFCED4DA); // Placeholder
  static const Color grey500 = Color(0xFF6C757D); // Secondary text
  static const Color grey600 = Color(0xFF495057); // Body text
  static const Color grey700 = Color(0xFF343A40); // Headings
  static const Color grey800 = Color(0xFF212529); // Dark text
  static const Color grey900 = Color(0xFF1A1A1A); // Darkest

  // Background Colors (Clean & Fresh)
  static const Color background = white; // Pure white background
  static const Color surface = white; // Card surface
  static const Color surfaceVariant = grey50; // Alternate surface
  static const Color cardShadow = Color(0x08000000); // Subtle shadow

  // Text Colors (Modern Hierarchy)
  static const Color textPrimary = grey800; // Main content
  static const Color textSecondary = grey500; // Supporting text
  static const Color textTertiary = grey400; // Subtle text
  static const Color textOnPrimary = white;
  static const Color textOnDark = white;
  static const Color textPlaceholder = grey400;

  // Modern Opacity Variants
  static Color get primaryWithLowOpacity => primary.withValues(alpha: 0.08);
  static Color get primaryWithMediumOpacity => primary.withValues(alpha: 0.12);
  static Color get primaryWithHighOpacity => primary.withValues(alpha: 0.16);

  static Color get whiteWithLowOpacity => white.withValues(alpha: 0.1);
  static Color get greyWithLowOpacity => grey200.withValues(alpha: 0.5);
  static Color get shadowLight => black.withValues(alpha: 0.04);
  static Color get shadowMedium => black.withValues(alpha: 0.08);
  static Color get shadowDark => black.withValues(alpha: 0.12);

  // Modern Card Colors (Subtle & Fresh)
  static const List<Color> dashboardCardColors = [
    Color(0xFF6C5CE7), // Modern Purple for attendance
    Color(0xFF00D4AA), // Fresh Teal for history
    Color(0xFF3498DB), // Bright Blue for worksheet
    Color(0xFFFF6B35), // Vibrant Orange for material
  ];

  // Status Colors for Stats
  static const List<Color> statColors = [
    info, // Blue for time
    success, // Green for monthly stats
  ];

  // Modern Gradient Colors (Subtle)
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

  // Typography System (Smaller, Modern Font Sizes)
  static const double fontSizeXS = 11.0; // Extra small text
  static const double fontSizeSM = 12.0; // Small text (captions, labels)
  static const double fontSizeBase = 14.0; // Base text size (body text)
  static const double fontSizeLG = 16.0; // Large text (subheadings)
  static const double fontSizeXL = 18.0; // Extra large (section headers)
  static const double fontSize2XL = 20.0; // 2X large (page titles)
  static const double fontSize3XL = 24.0; // 3X large (main headings)
  static const double fontSize4XL = 28.0; // 4X large (display text)

  // Text Styles (Pre-defined for consistency)
  static TextStyle get captionStyle => TextStyle(
        fontSize: fontSizeSM,
        color: textSecondary,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodyStyle => TextStyle(
        fontSize: fontSizeBase,
        color: textPrimary,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodyMediumStyle => TextStyle(
        fontSize: fontSizeBase,
        color: textPrimary,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get subheadingStyle => TextStyle(
        fontSize: fontSizeLG,
        color: textPrimary,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get headingStyle => TextStyle(
        fontSize: fontSizeXL,
        color: textPrimary,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleStyle => TextStyle(
        fontSize: fontSize2XL,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get displayStyle => TextStyle(
        fontSize: fontSize3XL,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      );

  static TextStyle get displayLargeStyle => TextStyle(
        fontSize: fontSize4XL,
        color: textPrimary,
        fontWeight: FontWeight.w800,
      );

  // Responsive Utilities
  static double getResponsiveHeight(BuildContext context, double baseHeight) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Scale based on screen height relative to a standard phone (844px like iPhone 14)
    return baseHeight * (screenHeight / 844.0);
  }

  static double getResponsiveWidth(BuildContext context, double baseWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Scale based on screen width relative to a standard phone (390px like iPhone 14)
    return baseWidth * (screenWidth / 390.0);
  }

  static double getResponsivePadding(BuildContext context, double basePadding) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 700) {
      // Small screens like Galaxy S23 (667px) - reduce padding by 40%
      return basePadding * 0.6;
    } else if (screenHeight < 800) {
      // Medium screens - reduce padding by 20%
      return basePadding * 0.8;
    } else {
      // Large screens - keep original padding
      return basePadding;
    }
  }

  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 700) {
      // Small screens - reduce spacing by 50%
      return baseSpacing * 0.5;
    } else if (screenHeight < 800) {
      // Medium screens - reduce spacing by 25%
      return baseSpacing * 0.75;
    } else {
      // Large screens - keep original spacing
      return baseSpacing;
    }
  }

  static double getResponsiveFontSize(
      BuildContext context, double baseFontSize) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 700) {
      // Small screens - reduce font size by 15%
      return baseFontSize * 0.85;
    } else if (screenHeight < 800) {
      // Medium screens - reduce font size by 8%
      return baseFontSize * 0.92;
    } else {
      // Large screens - keep original font size
      return baseFontSize;
    }
  }

  static TextStyle getResponsiveTextStyle(
      BuildContext context, TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontSize:
          getResponsiveFontSize(context, baseStyle.fontSize ?? fontSizeBase),
    );
  }

  // Modern Card Decoration
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

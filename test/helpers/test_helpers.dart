import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kseb/utils/app_colors.dart';
import 'package:kseb/utils/app_typography.dart';
import 'package:kseb/utils/app_spacing.dart';
import 'package:kseb/utils/page_transitions.dart';

/// Disable GoogleFonts network fetching for test environments.
void setupTestEnvironment() {
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// Build the app's canonical ThemeData for use in widget tests.
///
/// Mirrors the production theme in lib/main.dart so that widget tests
/// render under the same conditions as the running application.
ThemeData createTestTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primaryWithLowOpacity,
      onPrimaryContainer: AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: AppColors.secondary.withValues(alpha: 0.08),
      onSecondaryContainer: AppColors.secondary,
      tertiary: AppColors.accent,
      onTertiary: AppColors.textOnPrimary,
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.grey200,
      outline: AppColors.grey300,
      outlineVariant: AppColors.grey200,
      shadow: AppColors.cardShadow,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: AppTypography.displayLargeStyle,
      displayMedium: AppTypography.displayStyle,
      titleLarge: AppTypography.titleStyle,
      titleMedium: AppTypography.headingStyle,
      titleSmall: AppTypography.subheadingStyle,
      bodyLarge: AppTypography.bodyMediumStyle,
      bodyMedium: AppTypography.bodyStyle,
      bodySmall: AppTypography.captionStyle,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0.5,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.shadowLight,
      centerTitle: true,
      titleTextStyle: AppTypography.headingStyle,
    ),
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide(color: AppColors.error),
      ),
      labelStyle: AppTypography.captionStyle,
      hintStyle: TextStyle(color: AppColors.textPlaceholder),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        ),
        textStyle: AppTypography.bodyMediumStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: AppTypography.bodyStyle,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: AppPageTransition(),
        TargetPlatform.iOS: AppPageTransition(),
        TargetPlatform.windows: AppPageTransition(),
        TargetPlatform.macOS: AppPageTransition(),
        TargetPlatform.linux: AppPageTransition(),
      },
    ),
  );
}

/// Wraps a widget in MaterialApp with the design-system theme for testing.
Widget createTestApp(Widget child) {
  return MaterialApp(
    theme: createTestTheme(),
    home: child,
  );
}

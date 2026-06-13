import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Spacing, border radius, and elevation token system for the AumLux design system.
///
/// Provides named spacing values, border radius constants, and shadow presets.
/// All screen and widget code should reference these tokens
/// instead of using magic numbers.
abstract final class AppSpacing {
  // ── Spacing Scale (dp) ────────────────────────────────────────────
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double page = 40.0;

  // ── Border Radius Scale (dp) ──────────────────────────────────────
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusDefault = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusPill = 100.0;

  // ── Shadow Presets ────────────────────────────────────────────────

  /// No shadow — flat elements.
  static const List<BoxShadow> shadowNone = [];

  /// Standard card shadow (homepage standard) — 2 layers.
  static List<BoxShadow> get shadowLight => [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: AppColors.shadowMedium,
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  /// Elevated cards, dialogs — 2 layers.
  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: AppColors.shadowMedium,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: AppColors.shadowDark,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Modals, overlays — 2 layers.
  static List<BoxShadow> get shadowHeavy => [
        BoxShadow(
          color: AppColors.shadowDark,
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.black.withValues(alpha: 0.16),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ];
}

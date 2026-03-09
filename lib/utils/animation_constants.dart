import 'package:flutter/material.dart';

/// Centralized animation timing and configuration constants.
///
/// Pattern: abstract final class with static const fields
/// (same as [AppColors], [AppSpacing]).
///
/// All animation widgets reference these constants exclusively —
/// no magic numbers anywhere else.
abstract final class AnimationConstants {
  // ── Splash Screen ───────────────────────────────────────────────
  /// Minimum time the splash animation must play before transitioning.
  static const Duration splashMinDuration = Duration(milliseconds: 1500);

  /// Maximum time to wait for auth before showing a loading indicator.
  static const Duration splashMaxDuration = Duration(milliseconds: 2500);

  /// Duration of the lightning-bolt icon scale-up animation.
  static const Duration splashIconScaleDuration = Duration(milliseconds: 800);

  /// Duration of the "KSEB" text slide-up animation.
  static const Duration splashTextSlideDuration = Duration(milliseconds: 500);

  /// Duration of the cross-fade from splash to the destination screen.
  static const Duration splashCrossFadeDuration = Duration(milliseconds: 400);

  // ── Page Transitions ────────────────────────────────────────────
  /// Duration of scale-from-origin + fade transition between screens.
  static const Duration pageTransitionDuration = Duration(milliseconds: 250);

  /// Curve used for page transition animations.
  static const Curve pageTransitionCurve = Curves.easeOut;

  // ── Press-Scale ─────────────────────────────────────────────────
  /// Scale factor applied on press (e.g. 0.96 = 4% shrink).
  static const double pressScaleFactor = 0.96;

  /// Duration of the press-scale animation.
  static const Duration pressScaleDuration = Duration(milliseconds: 120);

  /// Curve for the press-scale spring-back effect.
  static const Curve pressScaleCurve = Curves.easeOutBack;

  // ── Content Fade-In ─────────────────────────────────────────────
  /// Default duration for content fade-in after data loads.
  static const Duration contentFadeInDuration = Duration(milliseconds: 250);

  // ── Staggered List ──────────────────────────────────────────────
  /// Delay between consecutive list items during staggered entrance.
  static const Duration staggerDelayPerItem = Duration(milliseconds: 60);

  /// Maximum index used for stagger delay calculation (cap).
  static const int staggerMaxIndex = 8;

  /// Duration of each individual list item's entrance animation.
  static const Duration staggerItemDuration = Duration(milliseconds: 300);

  /// Vertical slide offset for list item entrance (fraction of height).
  static const double staggerSlideOffset = 0.08;

  /// Curve used for staggered list item entrance.
  static const Curve staggerCurve = Curves.easeOut;

  // ── Configurable Strings ────────────────────────────────────────
  /// Application name displayed on the splash screen.
  static const String appName = 'KSEB';
}

/// Returns [Duration.zero] when the platform reduce-motion setting is active,
/// otherwise returns the provided [normal] duration.
///
/// All animation widgets should use this to respect accessibility settings
/// (FR-015, research R3).
Duration respectMotion(BuildContext context, Duration normal) {
  return MediaQuery.of(context).disableAnimations ? Duration.zero : normal;
}

import 'package:flutter/material.dart';

import 'animation_constants.dart';

/// Custom page transition builder: scale-up from origin + fade.
///
/// When used with [AppRoute] and an origin [Rect], the new page
/// expands from where the user tapped (e.g. the dashboard card icon).
/// Fallback: a subtle scale+fade if no origin is provided.
///
/// When reduce-motion is enabled, returns the child directly (instant).
class AppPageTransition extends PageTransitionsBuilder {
  const AppPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Respect reduce-motion accessibility setting
    if (MediaQuery.of(context).disableAnimations) {
      return child;
    }

    final curve = CurvedAnimation(
      parent: animation,
      curve: AnimationConstants.pageTransitionCurve,
    );

    // If the route carries an origin rect, animate from that point
    if (route is AppRoute<T>) {
      final sourceRect = route.sourceRect;
      if (sourceRect != null) {
        final screen = MediaQuery.of(context).size;
        // Alignment from the origin center
        final originAlign = Alignment(
          (sourceRect.center.dx / screen.width) * 2 - 1,
          (sourceRect.center.dy / screen.height) * 2 - 1,
        );

        return ScaleTransition(
          alignment: originAlign,
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
            child: child,
          ),
        );
      }
    }

    // Fallback: subtle center scale + fade
    return ScaleTransition(
      alignment: Alignment.center,
      scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
        child: child,
      ),
    );
  }
}

/// Thin [MaterialPageRoute] subclass with custom transition duration.
///
/// Accepts an optional [sourceRect] — the bounding box of the widget
/// that was tapped. [AppPageTransition] uses it to scale from that origin.
///
/// Preserves iOS swipe-back gesture by extending [MaterialPageRoute].
class AppRoute<T> extends MaterialPageRoute<T> {
  /// The screen-space bounding box of the element that triggered navigation.
  final Rect? sourceRect;

  AppRoute({required super.builder, super.settings, this.sourceRect});

  @override
  Duration get transitionDuration => AnimationConstants.pageTransitionDuration;

  @override
  Duration get reverseTransitionDuration =>
      AnimationConstants.pageTransitionDuration;
}

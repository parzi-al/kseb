# Widget API Contracts: Animation System

**Feature**: 003-splash-smooth-ui | **Date**: 2026-03-09

## 1. AnimationConstants

```dart
/// Centralized animation timing and configuration constants.
/// Pattern: abstract final class with static const fields (same as AppColors, AppSpacing).
abstract final class AnimationConstants {
  // Splash screen
  static const Duration splashMinDuration;     // 1500ms
  static const Duration splashMaxDuration;     // 2500ms
  static const Duration splashIconScaleDuration; // 800ms
  static const Duration splashTextSlideDuration; // 500ms
  static const Duration splashCrossFadeDuration; // 400ms

  // Page transitions
  static const Duration pageTransitionDuration; // 300ms
  static const Curve pageTransitionCurve;       // Curves.easeOutCubic

  // Press-scale
  static const double pressScaleFactor;        // 0.96
  static const Duration pressScaleDuration;    // 120ms
  static const Curve pressScaleCurve;          // Curves.easeOutBack

  // Content fade-in
  static const Duration contentFadeInDuration; // 250ms

  // Staggered list
  static const Duration staggerDelayPerItem;   // 60ms
  static const int staggerMaxIndex;            // 8
  static const Duration staggerItemDuration;   // 300ms
  static const double staggerSlideOffset;      // 0.08
  static const Curve staggerCurve;             // Curves.easeOut

  // Configurable strings
  static const String appName;                 // 'KSEB'
}
```

## 2. SplashScreen

```dart
/// Branded splash screen displayed on app launch.
/// Shows: lightning bolt icon scaling up → "KSEB" text sliding up → cross-fade to destination.
/// Coordinates with Firebase auth initialization.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
}
// No public API beyond construction. Manages its own state internally.
// Transitions to LoginScreen or WorkerHomeScreen via Navigator.pushReplacement.
```

## 3. AppPageTransition

```dart
/// Custom page transition builder: slide-from-right + fade.
/// Configured globally in ThemeData.pageTransitionsTheme.
class AppPageTransition extends PageTransitionsBuilder {
  const AppPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  );
  // Returns: SlideTransition wrapping FadeTransition wrapping child
  // Slide: Offset(1.0, 0.0) → Offset.zero with easeOutCubic
  // Fade: 0.0 → 1.0 with easeOutCubic
  // Respects reduce-motion: if disableAnimations, returns child directly
}
```

## 4. AppRoute

```dart
/// Thin MaterialPageRoute subclass with custom transition duration.
/// Use instead of MaterialPageRoute for all Navigator.push calls.
class AppRoute<T> extends MaterialPageRoute<T> {
  AppRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration; // AnimationConstants.pageTransitionDuration
}
```

## 5. PressableScale

```dart
/// Wrapper widget that adds a press-scale animation to its child.
/// On press: scales to scaleFactor. On release: springs back to 1.0.
/// Respects reduce-motion accessibility setting.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor; // default: AnimationConstants.pressScaleFactor
  final bool enabled;       // default: true

  const PressableScale({
    required this.child,
    this.onTap,
    this.scaleFactor = AnimationConstants.pressScaleFactor,
    this.enabled = true,
    super.key,
  });
}
```

## 6. StaggeredListItem

```dart
/// Wrapper that animates a list item with staggered fade + slide-up entrance.
/// Delay is computed from index. Plays once per lifecycle.
/// Respects reduce-motion accessibility setting.
class StaggeredListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggeredListItem({
    required this.index,
    required this.child,
    super.key,
  });
}
```

## 7. FadeInWidget

```dart
/// Wrapper that fades in its child on first build.
/// Used for content-loading transition (FR-013).
/// Respects reduce-motion accessibility setting.
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration? duration; // default: AnimationConstants.contentFadeInDuration

  const FadeInWidget({
    required this.child,
    this.duration,
    super.key,
  });
}
```

## Integration Points

### main.dart changes

```dart
// Before:
home: SafeArea(child: StreamBuilder<User?>(...))

// After:
home: const SplashScreen(),
// StreamBuilder moves inside SplashScreen's transition logic

// Theme addition:
ThemeData(
  ...existing...,
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      TargetPlatform.android: const AppPageTransition(),
      TargetPlatform.iOS: const AppPageTransition(),
      TargetPlatform.windows: const AppPageTransition(),
      TargetPlatform.macOS: const AppPageTransition(),
      TargetPlatform.linux: const AppPageTransition(),
    },
  ),
)
```

### Navigator.push migration

```dart
// Before (9 call sites):
Navigator.of(context).push(MaterialPageRoute(builder: (context) => Screen()));

// After:
Navigator.of(context).push(AppRoute(builder: (context) => Screen()));
```

### Dashboard card migration

```dart
// Before:
_buildDashboardCard(context, icon: ..., onTap: () { ... })

// After:
// _buildDashboardCard internally wraps content with PressableScale
```

### List view migration (4 primary lists)

```dart
// Before:
ListView.builder(itemBuilder: (ctx, i) => ItemWidget(...))

// After:
ListView.builder(itemBuilder: (ctx, i) => StaggeredListItem(index: i, child: ItemWidget(...)))
```

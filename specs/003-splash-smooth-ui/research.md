# Research: Splash Screen & Smooth UI Transitions

**Feature**: 003-splash-smooth-ui | **Date**: 2026-03-09

## R1: Splash Screen Animation Approach

**Decision**: Custom `SplashScreen` StatefulWidget with its own `AnimationController`, placed as the initial `home:` of `MaterialApp`. Firebase init runs concurrently via a `Future` while the animation plays. When both minimum animation duration AND Firebase readiness complete, trigger cross-fade navigation.

**Rationale**: The current code awaits `Firebase.initializeApp()` before `runApp()`, showing nothing during init. Moving init into a `Future` running in parallel with the splash masks the wait. `AnimationController` with `TweenSequence` / chained `Interval` curves handles the sequenced sub-animations (icon scale-up → text slide-up) with precise timing. The spec requires a cross-fade distinct from regular page transitions — manage via `AnimatedSwitcher` or state flag, avoiding Navigator for this specific transition.

**Alternatives considered**:
- `flutter_native_splash` — Only static images during engine boot; cannot do multi-step programmatic animation.
- `Rive` / `Lottie` — Adds external deps and asset files; spec says "no external assets."
- Keep `await` before `runApp()` — Wastes 200–800ms showing nothing.

## R2: Global Page Transitions

**Decision**: Use `PageTransitionsTheme` inside `ThemeData` with a custom `PageTransitionsBuilder`. This retrofits all existing `MaterialPageRoute` calls without touching call sites. A thin `MaterialPageRoute` subclass overrides `transitionDuration` to ~300ms.

**Rationale**: 10+ `MaterialPageRoute` usages exist. `PageTransitionsTheme` is the only approach that applies globally (FR-010). The custom builder's `buildTransitions()` combines `SlideTransition` (offset 1.0→0.0) + `FadeTransition` (0.0→1.0) with `Curves.easeOutCubic`. Back navigation gets reverse automatically. Critically, `MaterialPageRoute` preserves iOS swipe-back gesture — `PageRouteBuilder` does not.

**Alternatives considered**:
- `onGenerateRoute` with named routes — Requires refactoring all navigation sites. `PageRouteBuilder` loses swipe-back.
- `Navigator 2.0` / `GoRouter` — Massive architectural change; not justified for cosmetic feature.
- Per-route `PageRouteBuilder` — Violates FR-010 global requirement. Unmaintainable.

## R3: Reduce-Motion Accessibility

**Decision**: Use `MediaQuery.of(context).disableAnimations` (Flutter 3.10+). When true, all animation durations become `Duration.zero` (instant transitions).

**Rationale**: Directly reflects OS-level "Remove animations" / "Reduce Motion" toggle. No platform channel needed. The spec says "skip or minimize" — `Duration.zero` is strongest compliance. Apply via a utility function: `Duration respectMotion(BuildContext context, Duration normal)`.

**Alternatives considered**:
- `MediaQuery.boldText` — Unrelated (text weight, not motion).
- `timeDilation` global — Debug tool, not production accessibility.
- Reduce to 50ms instead of zero — Still shows animation flash; defeats purpose.

## R4: Press-Scale Animation on Cards

**Decision**: Reusable `PressableScale` wrapper using `GestureDetector` (press/release) + `AnimationController` driving `Transform.scale`. Wraps existing card/InkWell widgets.

**Rationale**: `GestureDetector.onTapDown/Up/Cancel` gives precise press lifecycle control. `Transform.scale` is paint-only (no layout recalculation). Spring-back via `Curves.easeOutBack` gives slight overshoot for bouncy feel. Composes outside existing `InkWell` ripple — no conflict.

**Alternatives considered**:
- `AnimatedScale` — No spring curve support, requires rebuild to trigger.
- `InkWell.onHighlightChanged` — Doesn't provide raw down/up events, couples scale to ripple.
- `AnimatedContainer` — Recalculates layout on every frame (slower).

## R5: Staggered List Entrance Animation

**Decision**: Per-item wrapper widget with its own `AnimationController`, stagger delay = `index * 60ms`. Uses `ListView.builder` (not `AnimatedList`). Items animate once on first build; off-screen items animate when scrolled into view.

**Rationale**: `AnimatedList` is for dynamic insert/remove, not initial-load stagger. `ListView.builder`'s lazy construction means off-screen items never create controllers. Cap max delay at index 8 to prevent absurd waits on long lists. Combined `FadeTransition` + `SlideTransition` (Offset(0, 0.1) → zero) for entrance.

**Alternatives considered**:
- `AnimatedList` — Designed for mutations, not entrance. Would require fake sequential inserts.
- Single controller with `Interval` per item — Requires knowing total count upfront; breaks with lazy loading.
- `flutter_staggered_animations` package — Adds dependency for ~40 lines of achievable code.

## Summary

| Topic | Decision | Key Flutter APIs |
|-------|----------|-----------------|
| Splash screen | Custom StatefulWidget + AnimationController | `AnimationController`, `TweenSequence`, `Future.wait` |
| Global transitions | `PageTransitionsTheme` in ThemeData | `PageTransitionsBuilder`, `MaterialPageRoute` subclass |
| Reduce motion | `MediaQuery.disableAnimations` → Duration.zero | `MediaQuery.of(context).disableAnimations` |
| Press-scale | Reusable PressableScale wrapper | `GestureDetector`, `AnimationController`, `Transform.scale` |
| Staggered lists | Per-item controller in ListView.builder | `AnimationController`, `FadeTransition`, `SlideTransition` |

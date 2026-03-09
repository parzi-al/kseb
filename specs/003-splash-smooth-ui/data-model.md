# Data Model: Splash Screen & Smooth UI Transitions

**Feature**: 003-splash-smooth-ui | **Date**: 2026-03-09

> This feature introduces no Firestore/data changes. The "data model" here describes the widget entities, animation state machines, and constant definitions that form the animation system.

## Entities

### 1. AnimationConstants (abstract final class)

Centralized timing, curve, and scale constants consumed by all animation widgets. No magic numbers anywhere else.

| Field | Type | Value | FR |
|-------|------|-------|----|
| `splashMinDuration` | Duration | 1500ms | FR-003 |
| `splashMaxDuration` | Duration | 2500ms | FR-003 |
| `splashIconScaleDuration` | Duration | 800ms | FR-002 |
| `splashTextSlideDuration` | Duration | 500ms | FR-002 |
| `splashCrossFadeDuration` | Duration | 400ms | FR-006 |
| `pageTransitionDuration` | Duration | 300ms | FR-008 |
| `pressScaleFactor` | double | 0.96 | FR-012 |
| `pressScaleDuration` | Duration | 120ms | FR-012 |
| `contentFadeInDuration` | Duration | 250ms | FR-013 |
| `staggerDelayPerItem` | Duration | 60ms | FR-014 |
| `staggerMaxIndex` | int | 8 | FR-014 |
| `staggerItemDuration` | Duration | 300ms | FR-014 |
| `staggerSlideOffset` | double | 0.08 | FR-014 |
| `pageTransitionCurve` | Curve | Curves.easeOutCubic | FR-008 |
| `pressScaleCurve` | Curve | Curves.easeOutBack | FR-012 |
| `staggerCurve` | Curve | Curves.easeOut | FR-014 |
| `appName` | String | 'KSEB' | FR-002 (config) |

### 2. SplashScreen (StatefulWidget)

Full-screen branded animation displayed on launch.

**State machine**:

```
[idle] → initState → [animating]
  ├── icon scale-up (0→800ms)
  ├── text slide-up (800→1300ms)
  └── hold until min duration (1300→1500ms)
[animating] → min duration elapsed + auth ready → [transitioning]
  └── cross-fade out (400ms)
[transitioning] → complete → [disposed]

Exception path:
[animating] → max duration elapsed + auth NOT ready → [waiting]
  └── show pulsing loading indicator
[waiting] → auth ready → [transitioning]
```

**Props**: None (reads auth state internally via StreamBuilder or Future).

### 3. AppPageTransition (PageTransitionsBuilder)

Custom builder producing combined slide-from-right + fade transition.

| Parameter | Value |
|-----------|-------|
| Slide begin | Offset(1.0, 0.0) → Offset.zero |
| Fade begin | 0.0 → 1.0 |
| Duration | 300ms (via route subclass) |
| Curve | Curves.easeOutCubic |
| Reverse | Automatic (slide right-to-left, fade 1.0→0.0) |
| Swipe-back | Supported (extends MaterialPageRoute) |

### 4. AppRoute (MaterialPageRoute subclass)

Thin subclass that only overrides `transitionDuration` to 300ms. This is needed because `PageTransitionsTheme` controls the visual transition but not the duration.

### 5. PressableScale (StatefulWidget)

Wrapper adding press-scale animation to any child.

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `child` | Widget | required | Content to wrap |
| `onTap` | VoidCallback? | null | Tap handler (forwarded) |
| `scaleFactor` | double | 0.96 | Target scale on press |
| `enabled` | bool | true | Disable animation |

**State machine**:
```
[idle, scale=1.0] → onTapDown → [pressed, scale=0.96]
[pressed] → onTapUp → [releasing, scale→1.0 with spring]
[pressed] → onTapCancel → [releasing, scale→1.0]
[releasing] → animation complete → [idle]
```

### 6. StaggeredListItem (StatefulWidget)

Wrapper that animates a single list item with fade + slide-up entrance.

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `index` | int | required | Position in list (determines delay) |
| `child` | Widget | required | Content to wrap |

**Behavior**:
- Delay = `min(index, staggerMaxIndex) * staggerDelayPerItem`
- Animation: opacity 0→1 + translateY offset→0
- Plays once per widget lifecycle (not on rebuild)
- Respects `MediaQuery.disableAnimations`

### 7. FadeInWidget (StatefulWidget)

Simple wrapper that fades in its child when first built. Used for content-loading fade-in (FR-013).

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `child` | Widget | required | Content to fade in |
| `duration` | Duration? | contentFadeInDuration | Override default |

## Relationships

```
main.dart
  └── MaterialApp
       ├── theme: createAppTheme()
       │    └── pageTransitionsTheme: AppPageTransition (for all platforms)
       └── home: SplashScreen
            ├── [animating] → shows lightning bolt + "KSEB" text
            ├── [transitioning] → cross-fade to:
            │    ├── LoginScreen (if unauthenticated)
            │    └── WorkerHomeScreen (if authenticated)
            │         └── _buildDashboardCard → PressableScale wrapper
            │              └── InkWell (existing ripple)
            └── [waiting] → pulsing indicator overlay

worker_home_screen / staff_management_screen / etc.
  └── ListView.builder
       └── StaggeredListItem(index: i, child: ...)
            └── FadeTransition + SlideTransition → actual item widget

All Navigator.push calls → AppRoute(builder: ...) instead of MaterialPageRoute
```

## Accessibility Model

| Condition | Behavior |
|-----------|----------|
| `disableAnimations == false` | Full animations with specified durations and curves |
| `disableAnimations == true` | All durations → Duration.zero; splash shows static frame for min wait; transitions instant; no scale/stagger |

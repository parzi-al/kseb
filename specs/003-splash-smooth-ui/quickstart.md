# Quickstart: Splash Screen & Smooth UI Transitions

**Feature**: 003-splash-smooth-ui | **Date**: 2026-03-09

## Overview

This feature adds three animation layers to the KSEB app:
1. **Splash screen** — branded opening animation on every launch
2. **Page transitions** — smooth slide+fade between all screens
3. **Micro-interactions** — press-scale, content fade-in, staggered list entrance

All animations use existing design tokens exclusively and respect the device's reduce-motion accessibility setting.

## Quick Reference

### Animation Constants

All timing values live in `lib/utils/animation_constants.dart`:

```dart
import 'package:kseb/utils/animation_constants.dart';

// Splash
AnimationConstants.splashMinDuration    // 1500ms
AnimationConstants.splashMaxDuration    // 2500ms

// Page transitions
AnimationConstants.pageTransitionDuration // 300ms

// Press-scale
AnimationConstants.pressScaleFactor    // 0.96

// Stagger
AnimationConstants.staggerDelayPerItem // 60ms
AnimationConstants.staggerMaxIndex     // 8
```

### Using AppRoute (page transitions)

Replace `MaterialPageRoute` with `AppRoute` in all navigation calls:

```dart
// Before:
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => const AttendanceScreen()),
);

// After:
import 'package:kseb/utils/page_transitions.dart';

Navigator.of(context).push(
  AppRoute(builder: (context) => const AttendanceScreen()),
);
```

The global `PageTransitionsTheme` handles the visual transition automatically. `AppRoute` just sets the correct duration.

### Adding press-scale to a card

Wrap any widget with `PressableScale`:

```dart
import 'package:kseb/components/common/pressable_scale.dart';

PressableScale(
  onTap: () => navigateSomewhere(),
  child: MyCardWidget(),
)
```

The scale animation (0.96× on press, spring back on release) is built-in. It composes with existing `InkWell` ripple effects.

### Staggered list entrance

Wrap each list item with `StaggeredListItem`:

```dart
import 'package:kseb/components/common/staggered_list_item.dart';

ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => StaggeredListItem(
    index: index,
    child: MyListItem(item: items[index]),
  ),
)
```

Items fade+slide in with a staggered delay based on their index. Only use on primary screen-level lists, not nested sub-lists or dropdowns.

### Content fade-in on data load

Wrap loaded content with `FadeInWidget`:

```dart
import 'package:kseb/components/common/fade_in_widget.dart';

_isLoading
  ? const AppLoading()
  : FadeInWidget(child: _buildContent())
```

### Accessibility

All animation widgets automatically check `MediaQuery.of(context).disableAnimations`. When the user has reduce-motion enabled:
- Splash shows static frame (no animation) for the minimum duration
- Page transitions are instant
- Press-scale is disabled
- Stagger and fade-in are instant

No manual intervention needed — the widgets handle it internally.

## File Map

| File | Purpose |
|------|---------|
| `lib/utils/animation_constants.dart` | All timing/curve/scale constants |
| `lib/utils/page_transitions.dart` | `AppPageTransition` builder + `AppRoute` subclass |
| `lib/screens/splash_screen.dart` | Branded splash screen widget |
| `lib/components/common/pressable_scale.dart` | Press-scale wrapper |
| `lib/components/common/staggered_list_item.dart` | Staggered entrance wrapper |
| `lib/components/common/fade_in_widget.dart` | Content fade-in wrapper |

## Design Token Compliance

All animations use:
- `AppColors.primary` for splash branding
- `AppColors.background` for splash background
- `AppTypography.displayLargeStyle` for "KSEB" text
- `AppSpacing.*` for any padding/margin in animation widgets
- `AnimationConstants.*` for all timing values

Zero new hardcoded values. If you need a new timing constant, add it to `AnimationConstants`.

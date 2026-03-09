# Skeleton Loading — Change Summary

## What Changed

Every screen that previously showed a **spinning `CircularProgressIndicator`** (via `AppLoading`) while loading data now shows a **shimmer skeleton** — grey placeholder shapes that match the screen's real layout and pulse with a subtle highlight sweep.

## Why

- Spinners give no indication of what content is coming, making the app **feel slower** than it is.
- Skeleton screens tell the user "content shaped like this is loading", which reduces **perceived wait time** by up to 35% (Google/Meta UX research).
- The attendance screen was the last holdout — now every data-heavy screen uses skeletons.

## Files Changed

| File | Change |
|------|--------|
| [lib/components/common/skeleton_loader.dart](lib/components/common/skeleton_loader.dart) | **NEW** — Custom `Shimmer` animation, `SkeletonBox`, `SkeletonCircle`, and 6 screen-specific skeleton layouts |
| [lib/screens/worker_home_screen.dart](lib/screens/worker_home_screen.dart) | `isLoading ? HomeScreenSkeleton()` replaces inline `'Loading...'` / `'--'` text |
| [lib/screens/staff_management_screen.dart](lib/screens/staff_management_screen.dart) | Both `StreamBuilder` loading states → `ListScreenSkeleton()` |
| [lib/screens/bonus_history_screen.dart](lib/screens/bonus_history_screen.dart) | Stream waiting state → `BonusHistorySkeleton()` |
| [lib/screens/bonus_management_screen.dart](lib/screens/bonus_management_screen.dart) | Full-page `_isLoading` → `FormScreenSkeleton()` |
| [lib/screens/worksheet_screen.dart](lib/screens/worksheet_screen.dart) | Full-page `_isLoading` → `FormScreenSkeleton()` |
| [lib/screens/add_material_screen.dart](lib/screens/add_material_screen.dart) | Full-page `_isLoading` → `FormScreenSkeleton()` |
| [lib/screens/withdraw_material_screen.dart](lib/screens/withdraw_material_screen.dart) | Full-page `_isLoading` → `FormScreenSkeleton()`; inline material dropdown spinner → shimmer box |
| [lib/screens/attendance_screen.dart](lib/screens/attendance_screen.dart) | Full-page `_isLoading` → `AttendanceScreenSkeleton()` |
| [lib/screens/attendance_history_screen.dart](lib/screens/attendance_history_screen.dart) | Full-page `_isLoading` → `ListScreenSkeleton()` |
| [test/components/skeleton_loader_test.dart](test/components/skeleton_loader_test.dart) | **NEW** — 12 tests covering Shimmer, SkeletonBox, SkeletonCircle, and all screen skeletons |

## Skeleton Variants

| Skeleton | Used By | Shape |
|----------|---------|-------|
| `HomeScreenSkeleton` | Worker home | Profile header + 2 stat cards + 2×2 action grid |
| `ListScreenSkeleton` | Staff management, attendance history | Repeating card rows with avatar circle + text lines |
| `FormScreenSkeleton` | Worksheet, bonus management, add/withdraw material | Header card + dropdown fields + text inputs + submit button |
| `BonusHistorySkeleton` | Bonus history | Repeating cards with points/amount + reason lines |
| `AttendanceScreenSkeleton` | Attendance | Avatar + name + role badge + stats row + calendar block + progress bar + button |

## Implementation Details

- **No external packages** — custom `Shimmer` widget using `AnimationController` + `ShaderMask` with a sweeping `LinearGradient` (1200ms repeat).
- **Accessibility**: shimmer animation is automatically disabled when `MediaQuery.disableAnimations` is `true` — static grey boxes shown instead.
- **Design system**: all skeleton shapes use `AppColors.grey100`/`grey200` and `AppSpacing` radius tokens.

## Test Results

- **251 tests passing** (239 existing + 12 new skeleton tests)
- **0 analyzer issues**

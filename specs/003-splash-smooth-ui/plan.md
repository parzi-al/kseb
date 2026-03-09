# Implementation Plan: Splash Screen & Smooth UI Transitions

**Branch**: `003-splash-smooth-ui` | **Date**: 2026-03-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-splash-smooth-ui/spec.md`

## Summary

Add a branded splash screen with lightning-bolt icon scale + text slide animation, replace all `MaterialPageRoute` calls with a global slide-from-right + fade transition, and add micro-interaction polish (press-scale on dashboard cards, content fade-in, staggered list entrance). All animations respect accessibility reduce-motion settings and use existing design tokens exclusively.

## Technical Context

**Language/Version**: Dart 3.6.0+ / Flutter 3.27.1 stable
**Primary Dependencies**: Firebase Core/Auth/Firestore (existing), google_fonts (existing). No new packages.
**Storage**: N/A (no data model changes)
**Testing**: `flutter test` (194+ existing tests)
**Target Platform**: Android (primary, SM S911B test device), iOS, Web
**Project Type**: Mobile app (Flutter)
**Performance Goals**: 60fps for all animations on mid-range devices
**Constraints**: No third-party animation packages. All styling via existing design tokens. Accessibility reduce-motion support required.
**Scale/Scope**: 11 screens, 9 `MaterialPageRoute` call sites, 4 primary list views, 6 dashboard cards

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Spec First | ✅ PASS | spec.md complete with 4 clarifications |
| II. Single Source of Truth | ✅ PASS | Spec drives all design decisions |
| III. Small Iterative Specs | ✅ PASS | 3 independent user stories (P1→P2→P3) |
| IV. Clear Data Contracts | ✅ PASS | No data model changes; animation contracts defined in this plan |
| V. Testability | ✅ PASS | Each widget testable independently; acceptance criteria map to tests |
| VI. Edge Case Awareness | ✅ PASS | 5 edge cases documented in spec |
| VII. Minimal Complexity | ✅ PASS | Built-in Flutter animation primitives only; no state management library |
| VIII. Documented Architecture | ✅ PASS | This plan + data-model.md + quickstart.md |
| IX. Reproducibility | ✅ PASS | No new external dependencies; deterministic builds |
| X. Clear Deliverable Structure | ✅ PASS | Standard speckit structure |
| XI. Test-Gated Development | ✅ PASS | Tests defined per phase; must pass before merge |

**Gate result: PASS — no violations.**

## Project Structure

### Documentation (this feature)

```text
specs/003-splash-smooth-ui/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (widget/animation model)
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (animation constants, widget APIs)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── main.dart                           # Modified: splash as home, global page transition theme
├── screens/
│   └── splash_screen.dart              # NEW: branded splash screen widget
├── components/
│   └── common/
│       ├── app_card.dart               # Modified: add press-scale animation
│       ├── animated_list_item.dart     # NEW: staggered entrance wrapper
│       └── fade_in_widget.dart         # NEW: content fade-in wrapper
└── utils/
    ├── page_transitions.dart           # NEW: custom PageRouteBuilder + global theme config
    ├── animation_constants.dart        # NEW: duration, curve, scale constants
    └── design_tokens.dart              # Unchanged (barrel export)

test/
├── screens/
│   └── splash_screen_test.dart         # NEW
├── components/
│   └── common/
│       ├── animated_list_item_test.dart # NEW
│       └── fade_in_widget_test.dart     # NEW
└── utils/
    └── page_transitions_test.dart       # NEW
```

**Structure Decision**: All new files follow the existing module layout (screens/, components/common/, utils/). No new directories or architectural patterns introduced. Animation constants centralized in one file to avoid magic numbers per FR-016.

## Complexity Tracking

No violations to justify — all gates pass.

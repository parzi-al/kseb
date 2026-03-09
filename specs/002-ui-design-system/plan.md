# Implementation Plan: Uniform UI Design System

**Branch**: `002-ui-design-system` | **Date**: 2026-03-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-ui-design-system/spec.md`

## Summary

Extract the existing homepage visual patterns (colors, typography, spacing, shadows, border radii) into a formal design token system split across 4 focused modules, build a reusable widget library (buttons, cards, inputs, loading/error/empty states, page scaffold, AppBar), update the root theme to eliminate the teal/orange conflict, and incrementally migrate all 11 screens + 8 components to use the shared system — converging on the homepage standard.

## Technical Context

**Language/Version**: Dart 3.6.0+ / Flutter 3.27.1 stable  
**Primary Dependencies**: google_fonts 6.2.1, table_calendar 3.1.2, percent_indicator 4.2.3, firebase_core/auth/firestore/storage  
**Storage**: Firebase Firestore (no schema changes needed — this feature is UI-only)  
**Testing**: flutter_test + fake_cloud_firestore 4.0.1; 5 existing test files (attendance module + utils)  
**Target Platform**: Android (primary), iOS, Web  
**Project Type**: Mobile app (Flutter)  
**Performance Goals**: 60fps rendering on all screens after migration; no jank from widget rebuilds  
**Constraints**: No behavioral changes — pure visual/structural refactor; must not break existing functionality; AppToast system unchanged  
**Scale/Scope**: 14 screen files (6,881 lines), 8 component files (2,215 lines), 3 utility files (440 lines) — total ~9,536 lines to audit and migrate

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Notes |
|---|-----------|--------|-------|
| I | Spec First | ✅ PASS | Spec completed and clarified before planning |
| II | Single Source of Truth | ✅ PASS | Design tokens will become the single source for all styling values |
| III | Small Iterative Specs | ✅ PASS | FR-019 mandates incremental screen-by-screen migration |
| IV | Clear Data Contracts | ✅ PASS | No data model changes; UI-only refactor. Widget API contracts defined in Phase 1 |
| V | Testability | ✅ PASS | Each widget and each screen migration is independently testable via flutter_test |
| VI | Edge Case Awareness | ✅ PASS | Spec covers: third-party widget theming, one-off exceptions, dark mode extensibility, long loading states |
| VII | Minimal Complexity | ✅ PASS | 4-file token split is the minimum for single-responsibility; no new abstractions beyond what the spec requires |
| VIII | Documented Architecture | ✅ PASS | This plan + data-model + contracts/ + quickstart.md fulfill documentation requirements |
| IX | Reproducibility | ✅ PASS | Token values are deterministic constants; no environment-dependent styling |
| X | Clear Deliverable Structure | ✅ PASS | Feature follows specs/002-ui-design-system/ structure per constitution |
| XI | Test-Gated Development | ✅ PASS | Widget tests required before screen migration; all tests must pass per-step |

**Gate result: PASS — no violations. Proceeding to Phase 0.**

## Project Structure

### Documentation (this feature)

```text
specs/002-ui-design-system/
├── plan.md              # This file
├── research.md          # Phase 0: technology research
├── data-model.md        # Phase 1: design token catalog
├── quickstart.md        # Phase 1: developer usage guide
├── contracts/           # Phase 1: widget API contracts
│   ├── widget-library.md
│   └── theme-contract.md
├── checklists/
│   └── requirements.md  # Quality checklist
└── tasks.md             # Phase 2 output (NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── utils/
│   ├── app_colors.dart           # REFACTOR → colors only (existing file, narrowed scope)
│   ├── app_typography.dart       # NEW — typography scale + responsive text helpers
│   ├── app_spacing.dart          # NEW — spacing, radius, elevation constants
│   ├── app_decorations.dart      # NEW — card decorations, responsive helpers, gradients
│   ├── app_constants.dart        # UNCHANGED — attendance business constants
│   └── app_toast.dart            # UNCHANGED — toast/snackbar system
├── components/
│   ├── common/
│   │   ├── modern_dropdown.dart  # EXISTING — update to use design tokens
│   │   ├── app_card.dart         # NEW — shared card widget
│   │   ├── app_button.dart       # NEW — shared button variants
│   │   ├── app_text_field.dart   # NEW — shared input field
│   │   ├── app_loading.dart      # NEW — shared loading indicator
│   │   ├── app_empty_state.dart  # NEW — shared empty state
│   │   ├── app_error_state.dart  # NEW — shared persistent error state
│   │   ├── app_scaffold.dart     # NEW — shared page scaffold
│   │   └── app_bar_builder.dart  # NEW — shared AppBar builder
│   ├── staff/                    # EXISTING — migrate to design tokens
│   └── team/                     # EXISTING — migrate to design tokens
├── screens/                      # ALL EXISTING — migrate incrementally
│   ├── worker_home_screen.dart
│   ├── attendance_screen.dart
│   ├── login_screen.dart
│   ├── staff_management_screen.dart
│   ├── worksheet_screen.dart
│   ├── material_management_screen.dart
│   ├── add_material_screen.dart
│   ├── withdraw_material_screen.dart
│   ├── bonus_management_screen.dart
│   ├── bonus_history_screen.dart
│   ├── attendance_history_screen.dart
│   └── components/               # EXISTING extracted components — migrate
└── main.dart                     # UPDATE theme configuration

test/
├── utils/
│   ├── app_constants_test.dart   # EXISTING
│   ├── app_colors_test.dart      # NEW — token value verification
│   ├── app_typography_test.dart  # NEW — typography scale verification
│   └── app_spacing_test.dart     # NEW — spacing/radius/elevation verification
├── components/
│   └── common/
│       ├── app_card_test.dart    # NEW — widget render tests
│       ├── app_button_test.dart  # NEW — widget render tests
│       └── ...                   # NEW — one test per shared widget
├── screens/                      # EXISTING + NEW per-screen migration tests
└── services/                     # EXISTING — unchanged
```

**Structure Decision**: Flutter mobile app structure. New files added under existing `lib/utils/` (split from `app_colors.dart`) and `lib/components/common/` (new shared widgets). Tests mirror the source structure under `test/`. No new top-level directories.

## Complexity Tracking

No constitution violations detected — this section is intentionally empty.

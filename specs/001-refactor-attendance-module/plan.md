# Implementation Plan: Refactor Attendance Module

**Branch**: `001-refactor-attendance-module` | **Date**: 2026-03-08 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-refactor-attendance-module/spec.md`

## Summary

Refactor the existing attendance module (model, service, two screens) to comply with the KSEB App Constitution. The primary changes are: (1) remove all direct Firestore references from screen files and route through `AttendanceService`, (2) fix `AttendanceHistoryScreen` to use the flat `attendance` collection instead of the deprecated `workers/{id}/attendance` subcollection, (3) extract reusable widgets to reduce `attendance_screen.dart` from ~1,223 to <600 lines, (4) add configurable attendance-hours time-window validation, (5) guard debug test button behind `kDebugMode`, (6) add unit tests for model and service with ≥80% coverage.

## Technical Context

**Language/Version**: Dart 3.6+ / Flutter (latest stable)
**Primary Dependencies**: `cloud_firestore ^6.0.1`, `firebase_auth ^6.0.2`, `local_auth ^2.3.0`, `table_calendar ^3.1.2`, `percent_indicator ^4.2.3`, `intl ^0.20.0`
**Storage**: Cloud Firestore — flat `attendance` collection
**Testing**: `flutter_test` (dev dependency already present); no existing attendance tests; only `test/widget_test.dart` exists (scaffold)
**Target Platform**: Android (primary), iOS, Web
**Project Type**: Mobile app (Flutter)
**Performance Goals**: N/A — refactor does not change runtime behavior
**Constraints**: No new Firestore indexes; no visual/UX changes; `present`-only status this iteration
**Scale/Scope**: 4 files touched (`attendance_model.dart`, `attendance_service.dart`, `attendance_screen.dart`, `attendance_history_screen.dart`), 1 new file (`app_constants.dart`), ~5 new test files, ~3 extracted widget files

## Constitution Check (Pre-Research)

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| # | Principle | Status | Evidence |
|---|-----------|--------|----------|
| I | Spec First | ✅ PASS | spec.md exists with 3 user stories, 13 FRs, 6 SCs |
| II | Single Source of Truth | ✅ PASS | Spec is canonical; plan derives from spec |
| III | Small Iterative Specs | ✅ PASS | Single module refactor, one iteration |
| IV | Clear Data Contracts | ✅ PASS | AttendanceModel defined; Firestore schema documented in DATABASE_STRUCTURE.md |
| V | Testability | ✅ PASS | FR-008 mandates unit tests; SC-003/SC-004/SC-005 define coverage targets |
| VI | Edge Case Awareness | ✅ PASS | 6 edge cases explicitly defined |
| VII | Minimal Complexity | ✅ PASS | Refactor simplifies (removes direct Firestore from screens); no new abstractions |
| VIII | Documented Architecture | ⚠️ DEFERRED | Architecture doc will be produced as part of deliverables |
| IX | Reproducibility | ✅ PASS | Flutter build is deterministic; tests are repeatable |
| X | Clear Deliverable Structure | ✅ PASS | spec.md, plan.md, research.md, data-model.md, contracts/ all planned |
| XI | Test-Gated Development | ✅ PASS | FR-008 + SC-003 mandate tests before merge |

**Gate result**: PASS — no blocking violations. Principle VIII deferred to Phase 1 output (quickstart.md documents the architecture).

## Project Structure

### Documentation (this feature)

```text
specs/001-refactor-attendance-module/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── attendance-service-contract.md
├── checklists/
│   └── requirements.md  # Quality checklist
└── tasks.md             # Phase 2 output (NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── models/
│   └── attendance_model.dart          # Refactored model (status as param)
├── services/
│   └── attendance_service.dart        # Sole Firestore access point
├── screens/
│   ├── attendance_screen.dart         # Refactored (<600 lines)
│   ├── attendance_history_screen.dart # Fixed to flat collection
│   └── components/                    # NEW: extracted widgets
│       ├── attendance_calendar.dart
│       ├── attendance_stats_card.dart
│       └── attendance_history_list.dart
└── utils/
    ├── app_colors.dart                # Existing
    ├── app_toast.dart                 # Existing
    └── app_constants.dart             # NEW: attendance hours config

test/
├── widget_test.dart                   # Existing scaffold
├── models/
│   └── attendance_model_test.dart     # NEW
├── services/
│   └── attendance_service_test.dart   # NEW
└── screens/
    └── attendance_screen_test.dart    # NEW
```

**Structure Decision**: Mobile app — single Flutter project. New `lib/screens/components/` directory for extracted attendance widgets. New `lib/utils/app_constants.dart` for configurable values. Test directory mirrors `lib/` structure.

## Complexity Tracking

No constitution violations requiring justification. The widget extraction (3 new files) reduces net complexity by splitting a 1,223-line file.

## Constitution Check (Post-Design)

*Re-evaluated after Phase 1 design artifacts produced.*

| # | Principle | Status | Evidence |
|---|-----------|--------|----------|
| I | Spec First | ✅ PASS | spec.md complete with 4 clarifications |
| II | Single Source of Truth | ✅ PASS | data-model.md + contract define canonical shapes |
| III | Small Iterative Specs | ✅ PASS | Single module, 3 user stories, one iteration |
| IV | Clear Data Contracts | ✅ PASS | data-model.md (entity/fields/validations) + contracts/attendance-service-contract.md (all method signatures, errors, behaviour) |
| V | Testability | ✅ PASS | DI via constructor; fake_cloud_firestore for unit tests; test file structure defined |
| VI | Edge Case Awareness | ✅ PASS | 6 edge cases + acceptance scenarios cover all failure modes |
| VII | Minimal Complexity | ✅ PASS | No new packages beyond fake_cloud_firestore (dev only); widget extraction reduces complexity |
| VIII | Documented Architecture | ✅ PASS | quickstart.md: architecture overview, component diagram, data flow, dependency boundaries |
| IX | Reproducibility | ✅ PASS | flutter test deterministic; fake_cloud_firestore in-memory |
| X | Clear Deliverable Structure | ✅ PASS | spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md all generated |
| XI | Test-Gated Development | ✅ PASS | FR-008 + SC-003 mandate tests before merge |

**Post-design gate result**: PASS — all principles satisfied. Ready for Phase 2 (tasks).

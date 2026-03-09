# Implementation Plan: Fix Auth Navigation & Login UI

**Branch**: `004-fix-auth-navigation-ui` | **Date**: 2026-03-09 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-fix-auth-navigation-ui/spec.md`

## Summary

Fix broken login/logout navigation (no auth state listener after splash), add industry-level auth features (idle timeout, brute-force protection, Firestore audit log, single-session enforcement), improve login UI (center bolt icon with modern animation, password strength indicator). The core architectural fix is introducing a reactive `StreamBuilder` on `FirebaseAuth.authStateChanges()` in `main.dart` to drive navigation, replacing the current one-shot splash-only approach.

## Technical Context

**Language/Version**: Dart 3.6+ / Flutter (latest stable)  
**Primary Dependencies**: firebase_auth ^6.0.2, cloud_firestore ^6.0.1, firebase_core ^4.1.0  
**Storage**: Cloud Firestore (existing collections: users, attendance, teams, etc. — new: auth_events, device_sessions, app_settings)  
**Testing**: flutter_test, fake_cloud_firestore ^4.0.1  
**Target Platform**: Android (primary), iOS, Web  
**Project Type**: Mobile app (Flutter)  
**Performance Goals**: Auth state navigation <2s, login icon animation <1s, 60fps animations  
**Constraints**: Offline-tolerant (login requires network; session check should degrade gracefully), reduce-motion accessible  
**Scale/Scope**: ~12 screens, ~5 services, <50 active users initially, single Firebase project

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Spec First | ✅ PASS | spec.md created with 22 FRs, 9 SCs, edge cases, clarifications |
| II. Single Source of Truth | ✅ PASS | All behavior derived from spec.md; plan references spec |
| III. Small Iterative Specs | ✅ PASS | 3 user stories are independently testable; P1 (nav fix) can ship alone |
| IV. Clear Data Contracts | ✅ PASS | Will be defined in data-model.md and contracts/ (Phase 1) |
| V. Testability | ✅ PASS | Acceptance scenarios + edge cases defined; test plan in quickstart.md |
| VI. Edge Case Awareness | ✅ PASS | 10 explicit edge cases in spec; null data, network failures, concurrency addressed |
| VII. Minimal Complexity | ⚠️ WATCH | 5 new Firestore collections/concepts — justified by industry-level auth requirements (user request). See Complexity Tracking. |
| VIII. Documented Architecture | ✅ PASS | This plan + data-model + contracts fulfill architecture docs |
| IX. Reproducibility | ✅ PASS | No new build tooling; existing flutter test + firebase deploy pipeline |
| X. Clear Deliverable Structure | ✅ PASS | spec.md, plan.md, research.md, data-model.md, contracts/, quickstart.md |
| XI. Test-Gated Development | ✅ PASS | Unit tests required per quickstart.md; all FRs mapped to test scenarios |

**Gate Result**: ✅ PASS (1 WATCH item — tracked in Complexity Tracking)

## Project Structure

### Documentation (this feature)

```text
specs/004-fix-auth-navigation-ui/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── firestore-schema.md
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
lib/
├── main.dart                        # MODIFY: Add StreamBuilder auth wrapper
├── models/
│   ├── user_model.dart              # EXISTING (no changes)
│   ├── auth_event_model.dart        # NEW: Audit log event model
│   └── device_session_model.dart    # NEW: Device session model
├── services/
│   ├── auth_service.dart            # NEW: Centralized auth service (login, logout, session mgmt)
│   ├── auth_audit_service.dart      # NEW: Firestore audit log writer
│   ├── session_service.dart         # NEW: Single-session enforcement
│   ├── idle_timeout_service.dart    # NEW: Idle timeout manager
│   └── user_service.dart            # EXISTING (no changes)
├── screens/
│   ├── login_screen.dart            # MODIFY: Center icon, animation, strength indicator, rate limiting
│   ├── splash_screen.dart           # EXISTING (no changes — continues cold-start auth check)
│   └── worker_home_screen.dart      # MODIFY: Logout uses auth_service, session check on resume
├── components/
│   └── common/
│       └── password_strength_indicator.dart  # NEW: Visual strength meter widget
├── utils/
│   ├── animation_constants.dart     # MODIFY: Add login icon animation constants
│   └── app_toast.dart               # EXISTING (reuse for error messages)
firestore.rules                      # MODIFY: Add rules for auth_events, device_sessions, app_settings

test/
├── services/
│   ├── auth_service_test.dart       # NEW
│   ├── auth_audit_service_test.dart # NEW
│   ├── session_service_test.dart    # NEW
│   └── idle_timeout_service_test.dart # NEW
├── screens/
│   └── login_screen_test.dart       # NEW or MODIFY
├── components/
│   └── password_strength_indicator_test.dart # NEW
└── models/
    ├── auth_event_model_test.dart   # NEW
    └── device_session_model_test.dart # NEW
```

**Structure Decision**: Follows existing Flutter mobile app structure (`lib/models`, `lib/services`, `lib/screens`, `lib/components`, `lib/utils`). New files are added within existing directories. No new top-level directories needed. This matches the existing pattern used by user_service.dart, attendance_service.dart, etc.

## Complexity Tracking

> Principle VII (Minimal Complexity) — WATCH

| Concern | Why Needed | Simpler Alternative Rejected Because |
|---------|------------|-------------------------------------|
| 3 new Firestore collections (auth_events, device_sessions, app_settings) | Industry-level auth requires audit trail (FR-018), single-session enforcement (FR-020), configurable idle timeout (FR-012) | Relying on Firebase Console-only logs provides no in-app admin visibility; no collection = no session enforcement; hardcoded timeout can't be admin-configured |
| 4 new service classes | Each handles a distinct concern: auth orchestration, audit logging, session management, idle timeout | Combining into one mega-service violates single responsibility and makes testing harder |
| Client-side rate limiting state | Brute-force protection (FR-015) requires tracking failed attempt count and cooldown timers | Firebase-only throttling gives cryptic error messages; no client UX for cooldown |

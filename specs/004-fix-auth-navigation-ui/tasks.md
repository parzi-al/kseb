# Tasks: Fix Auth Navigation & Login UI

**Input**: Design documents from `/specs/004-fix-auth-navigation-ui/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/firestore-schema.md, quickstart.md

**Tests**: Included — Constitution Principle XI requires test-gated development; quickstart.md maps all 22 FRs to test files.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Setup/Foundational phases have no story label
- File paths are relative to repository root

---

## Phase 1: Setup

**Purpose**: New model and utility files, animation constants update, no behavioral changes yet

- [X] T001 [P] Create AuthEventModel and AuthEventType enum in lib/models/auth_event_model.dart
- [X] T002 [P] Add activeSessionToken and lastLoginAt fields to UserModel in lib/models/user_model.dart
- [X] T003 [P] Add login icon animation constants to lib/utils/animation_constants.dart
- [X] T004 [P] Create LoginRateLimiter utility class in lib/services/login_rate_limiter.dart

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core services and Firestore rules that ALL user stories depend on. Must complete before any story work.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 [P] Create AuthAuditService in lib/services/auth_audit_service.dart
- [ ] T006 [P] Create SessionService in lib/services/session_service.dart
- [ ] T007 [P] Create IdleTimeoutService in lib/services/idle_timeout_service.dart
- [ ] T008 Create AuthService (orchestrator) in lib/services/auth_service.dart
- [ ] T009 Update Firestore security rules for auth_events, app_settings collections in firestore.rules
- [ ] T010 [P] Create unit tests for AuthEventModel in test/models/auth_event_model_test.dart
- [ ] T011 [P] Create unit tests for LoginRateLimiter in test/services/login_rate_limiter_test.dart
- [ ] T012 [P] Create unit tests for AuthAuditService in test/services/auth_audit_service_test.dart
- [ ] T013 [P] Create unit tests for SessionService in test/services/session_service_test.dart
- [ ] T014 [P] Create unit tests for IdleTimeoutService in test/services/idle_timeout_service_test.dart
- [ ] T015 Create unit tests for AuthService in test/services/auth_service_test.dart

**Checkpoint**: All foundational services built and tested. User story implementation can begin.

---

## Phase 3: User Story 1 — Successful Login Navigates to Home (Priority: P1) 🎯 MVP

**Goal**: After successful Firebase sign-in, the user is automatically navigated to the Worker Home Screen. Back button cannot return to login. Includes password validation, strength indicator, and brute-force protection.

**Independent Test**: Enter valid credentials → tap Sign In → verify Worker Home Screen appears within 2 seconds. Press back → verify app does NOT return to login.

### Implementation for User Story 1

- [ ] T016 [US1] Create AuthGate widget with StreamBuilder on authStateChanges() in lib/screens/auth_gate.dart
- [ ] T017 [US1] Update main.dart to use AuthGate as MaterialApp home instead of SplashScreen in lib/main.dart
- [ ] T018 [US1] Refactor SplashScreen to pure animation widget (remove auth logic) in lib/screens/splash_screen.dart
- [ ] T019 [P] [US1] Create PasswordStrengthIndicator widget in lib/components/common/password_strength_indicator.dart
- [ ] T020 [US1] Update LoginScreen: integrate AuthService.signIn, add password strength indicator, add rate limiting UI, add password min-length validation in lib/screens/login_screen.dart
- [ ] T021 [US1] Wire login to create session token and write audit event via AuthService in lib/screens/login_screen.dart
- [ ] T022 [P] [US1] Create unit tests for PasswordStrengthIndicator in test/components/password_strength_indicator_test.dart
- [ ] T023 [US1] Create widget tests for LoginScreen (sign-in flow, validation, rate limiting UI) in test/screens/login_screen_test.dart

**Checkpoint**: Login flow works end-to-end. User signs in → AuthGate detects auth state → Worker Home Screen shown. Back button cannot return to login. Password strength and rate limiting visible.

---

## Phase 4: User Story 2 — Successful Logout Navigates to Login (Priority: P1)

**Goal**: After confirming logout, the user is navigated to the Login Screen. Session is cleared. Back button cannot return to home. Includes idle timeout and single-session enforcement.

**Independent Test**: Log in → tap logout → confirm → verify Login Screen appears within 2 seconds. Press back → verify app does NOT return to home.

### Implementation for User Story 2

- [ ] T024 [US2] Update WorkerHomeScreen logout dialog to use AuthService.signOut (clears session, writes audit event) in lib/screens/worker_home_screen.dart
- [ ] T025 [US2] Add WidgetsBindingObserver to WorkerHomeScreen for session validation on app resume (force-logout detection) in lib/screens/worker_home_screen.dart
- [ ] T026 [US2] Integrate IdleTimeoutService with Listener widget in AuthGate for inactivity auto-logout in lib/screens/auth_gate.dart
- [ ] T027 [US2] Read idle timeout config from Firestore app_settings/auth document in lib/services/idle_timeout_service.dart
- [ ] T028 [US2] Create widget/integration tests for logout flow and session invalidation in test/screens/worker_home_screen_test.dart

**Checkpoint**: Full auth lifecycle works. Login → Home → Logout → Login. Idle timeout triggers auto-logout. Second device login invalidates first device session.

---

## Phase 5: User Story 3 — Centered Login Icon with Modern Animation (Priority: P2)

**Goal**: The bolt icon on the login screen is horizontally centered and plays a polished scale-in + glow entrance animation on load. Respects reduce-motion accessibility.

**Independent Test**: Open login screen → verify icon is centered → verify animation plays within 1 second → enable reduce-motion → verify icon appears without animation.

### Implementation for User Story 3

- [ ] T029 [US3] Center the bolt icon container by wrapping in Center widget within the Column in lib/screens/login_screen.dart
- [ ] T030 [US3] Add AnimationController with scale-in + glow BoxShadow entrance animation to LoginScreen in lib/screens/login_screen.dart
- [ ] T031 [US3] Add reduce-motion check (MediaQuery.disableAnimations) to skip animation when enabled in lib/screens/login_screen.dart
- [ ] T032 [US3] Create widget tests for icon centering, animation behavior, and reduce-motion in test/screens/login_screen_test.dart

**Checkpoint**: Login screen bolt icon is centered, animated on load, respects accessibility. All visual acceptance criteria met.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, cleanup, and cross-story integration testing

- [ ] T033 Verify all existing tests still pass (zero regressions) by running full test suite
- [ ] T034 Run quickstart.md verification steps 1-9 end-to-end on device/emulator
- [ ] T035 [P] Deploy updated firestore.rules to Firebase via firebase deploy --only firestore:rules
- [ ] T036 [P] Create app_settings/auth document in Firestore with idleTimeoutMinutes: 15 default
- [ ] T037 Code cleanup: remove stale comments referencing non-existent StreamBuilder in login_screen.dart and worker_home_screen.dart

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 models/utilities — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 completion — can start after foundational is done
- **US2 (Phase 4)**: Depends on Phase 2 completion + T016-T017 from Phase 3 (AuthGate must exist for logout navigation to work)
- **US3 (Phase 5)**: Depends on Phase 2 completion — can run in parallel with US2 (different concerns in login_screen.dart, but T029-T031 modify the same file as T020; sequence after T020)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Depends only on Foundational (Phase 2). Delivers the AuthGate which US2 also needs.
- **User Story 2 (P1)**: Depends on Foundational + AuthGate from US1 (T016-T017). Independently testable once AuthGate exists.
- **User Story 3 (P2)**: Depends on Foundational. Modifies login_screen.dart — should execute after US1's T020 to avoid merge conflicts.

### Within Each User Story

- Models before services
- Services before screen integration
- Screen integration before tests
- Tests validate the completed story

### Parallel Opportunities

**Phase 1** (all [P] — different files):
- T001, T002, T003, T004 can all run simultaneously

**Phase 2** (services [P] — different files):
- T005, T006, T007 can run simultaneously
- T010, T011, T012, T013, T014 can run simultaneously
- T008 depends on T005, T006, T007 (orchestrates them)
- T015 depends on T008

**Phase 3**:
- T019 (PasswordStrengthIndicator) + T022 (its test) can run parallel to T016-T018 (AuthGate work)

**Phase 5**:
- T029, T030, T031 are sequential (same file, cumulative changes)

---

## Parallel Example: Phase 2 Foundational

```bash
# Batch 1 — All independent services (different files):
T005: AuthAuditService in lib/services/auth_audit_service.dart
T006: SessionService in lib/services/session_service.dart
T007: IdleTimeoutService in lib/services/idle_timeout_service.dart

# Batch 2 — Orchestrator (depends on Batch 1):
T008: AuthService in lib/services/auth_service.dart

# Batch 3 — All tests (different files, parallel):
T010: auth_event_model_test.dart
T011: login_rate_limiter_test.dart
T012: auth_audit_service_test.dart
T013: session_service_test.dart
T014: idle_timeout_service_test.dart

# Batch 4 — Orchestrator test (depends on Batch 2):
T015: auth_service_test.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T015)
3. Complete Phase 3: User Story 1 (T016-T023)
4. **STOP and VALIDATE**: Login works → Home Screen shown → back button blocked
5. Deploy if ready — login is functional!

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add User Story 1 → Login works → Deploy/Demo (MVP!)
3. Add User Story 2 → Logout + idle timeout + session enforcement works → Deploy/Demo
4. Add User Story 3 → Login icon polished → Deploy/Demo
5. Polish → Full validation → Final deploy

### Single Developer Strategy

Execute phases sequentially: Phase 1 → 2 → 3 → 4 → 5 → 6.
Within each phase, use [P] markers to batch parallelizable work.

---

## Task Summary

| Phase | Tasks | Parallelizable | Description |
|-------|-------|---------------|-------------|
| Phase 1: Setup | T001-T004 (4) | 4 | Models, constants, utility |
| Phase 2: Foundational | T005-T015 (11) | 8 | Services, Firestore rules, tests |
| Phase 3: US1 Login | T016-T023 (8) | 2 | AuthGate, login screen, password strength |
| Phase 4: US2 Logout | T024-T028 (5) | 0 | Logout flow, idle timeout, session check |
| Phase 5: US3 Icon | T029-T032 (4) | 0 | Center icon, animation, reduce-motion |
| Phase 6: Polish | T033-T037 (5) | 2 | Validation, deploy, cleanup |
| **Total** | **37 tasks** | **16** | |

### Tasks Per User Story

| Story | Task Count | Phase |
|-------|-----------|-------|
| US1 (Login Navigation) | 8 | Phase 3 |
| US2 (Logout Navigation) | 5 | Phase 4 |
| US3 (Login Icon/Animation) | 4 | Phase 5 |
| Shared (Setup + Foundational) | 15 | Phase 1-2 |
| Polish | 5 | Phase 6 |

### MVP Scope

**Minimum viable**: Phase 1 + Phase 2 + Phase 3 (User Story 1) = **23 tasks**  
Delivers: Working login → home navigation, password strength indicator, rate limiting, audit logging, session management infrastructure.

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks
- [US1/US2/US3] labels map tasks to spec.md user stories for traceability
- Constitution Principle XI: All tests must pass before feature is considered complete
- Commit after each task or logical group
- Stop at any checkpoint to validate the story independently
- The AuthGate (T016-T017) is the architectural linchpin — it fixes both login AND logout navigation

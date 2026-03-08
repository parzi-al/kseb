# Tasks: Refactor Attendance Module

**Input**: Design documents from `/specs/001-refactor-attendance-module/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/attendance-service-contract.md ✅, quickstart.md ✅

**Tests**: Included — FR-008 mandates unit tests; SC-003/SC-004/SC-005 define coverage targets.

**Organization**: Tasks are grouped by user story (3 stories from spec.md) to enable independent implementation and testing.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths included in all descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add test dependency and create directory structure for new files

- [x] T001 Add `fake_cloud_firestore` to dev_dependencies in pubspec.yaml and run `flutter pub get`
- [x] T002 [P] Create test directory structure: test/models/, test/services/, test/screens/ and create lib/screens/components/ directory

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 [P] Create lib/utils/app_constants.dart with `abstract final class AttendanceConstants` containing `static const int attendanceStartHour = 6`, `static const int attendanceEndHour = 22`, `static const int workingDaysInYear = 240`, and a `static Set<DateTime> getPublicHolidays(int year)` method that returns normalised midnight dates (replacing hard-coded holiday data)
- [x] T004 [P] Refactor AttendanceModel in lib/models/attendance_model.dart — add `status` parameter (default `'present'`), validate status ∈ {`present`, `absent`, `leave`}, ensure `fromFirestore` factory and `toMap` method handle all fields per data-model.md (id, userId, worksheetId, date, verifiedBy, status, timestamp), normalise date to midnight
- [x] T005 [P] Refactor AttendanceService constructor in lib/services/attendance_service.dart — add optional `FirebaseFirestore? firestore` parameter defaulting to `FirebaseFirestore.instance`, store as `final FirebaseFirestore _firestore` instance field, replace all `FirebaseFirestore.instance` usages with `_firestore`
- [x] T006 [P] Guard debug "Test Mode — Mark Without Biometric" button behind `kDebugMode` in lib/screens/attendance_screen.dart — wrap with `if (kDebugMode)` so it only appears in debug builds (FR-012)

**Checkpoint**: Foundation ready — model accepts status, service is testable via DI, constants are centralised, debug button is guarded. User story implementation can now begin.

---

## Phase 3: User Story 1 — Staff Marks Daily Attendance (Priority: P1) 🎯 MVP

**Goal**: A staff member opens the Attendance screen, authenticates via biometrics, and their attendance is recorded for the current day with updated statistics.

**Independent Test**: Staff user opens attendance screen, taps "Mark Attendance" with biometric auth; record is created, stats update. Duplicate attempts are rejected. Outside-hours attempts are rejected.

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T007 [P] [US1] Write unit tests for AttendanceModel in test/models/attendance_model_test.dart — test fromFirestore deserialization (all fields including nullable worksheetId/verifiedBy), toMap serialization, status validation (valid values accepted, invalid throws ArgumentError), date normalisation to midnight, default status is 'present'
- [x] T008 [P] [US1] Write unit tests for US1 service methods in test/services/attendance_service_test.dart — test markAttendance (success, duplicate throws AttendanceAlreadyMarkedException, date normalisation, server timestamp), isAttendanceMarkedToday (true when exists, false when not), getUserAttendanceStats (returns correct total/thisMonth/thisYear/isMarkedToday), double-tap produces exactly one record (SC-004). Use `FakeFirebaseFirestore` for all tests.

### Implementation for User Story 1

- [x] T009 [US1] Implement markAttendance, isAttendanceMarkedToday, and getUserAttendanceStats methods in lib/services/attendance_service.dart per contracts/attendance-service-contract.md — markAttendance: normalise date to midnight, query for existing record, throw AttendanceAlreadyMarkedException if duplicate, insert with server timestamp; isAttendanceMarkedToday: query today's record; getUserAttendanceStats: compute total/thisMonth/thisYear/isMarkedToday in single query
- [x] T010 [P] [US1] Extract AttendanceStatsCard widget to lib/screens/components/attendance_stats_card.dart — StatelessWidget receiving stats data (thisMonth, thisYear, total, isMarkedToday) via constructor, callbacks for actions; include const constructor
- [x] T011 [P] [US1] Extract AttendanceCalendar widget to lib/screens/components/attendance_calendar.dart — StatelessWidget wrapping table_calendar with attendance date markers and public holiday highlights; receive List<DateTime> attendanceDates and Set<DateTime> holidays via constructor
- [x] T012 [US1] Refactor lib/screens/attendance_screen.dart — remove ALL direct `FirebaseFirestore` references (FR-001/FR-004), delegate all data operations to AttendanceService, add time-window validation using AttendanceConstants.attendanceStartHour/endHour (FR-010), add `_isLoading` guard to prevent double-tap duplicate submissions (FR-005), use extracted AttendanceStatsCard and AttendanceCalendar widgets, surface user-friendly error messages for network/permission/duplicate/missing-user errors (FR-007), target <600 lines (SC-006)

**Checkpoint**: User Story 1 is fully functional — staff can mark attendance, stats update, duplicates rejected, time-window enforced, debug button hidden in release. Run `flutter test test/models/ test/services/` to verify.

---

## Phase 4: User Story 2 — Staff Views Personal Attendance History (Priority: P2)

**Goal**: A staff member navigates to attendance history and sees a calendar with highlighted attendance dates plus a list view, with accurate monthly/yearly counts.

**Independent Test**: After several attendance records exist, open history view; calendar highlights correct dates, "This Month" counter matches, navigating to a previous month updates correctly, empty state shows message.

### Tests for User Story 2 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T013 [P] [US2] Write unit tests for US2 service methods (append to test/services/attendance_service_test.dart) — test getAttendanceHistory (returns List<AttendanceModel> sorted by date descending), getMonthlyAttendanceCount (correct count for given month), getTotalAttendanceCount (total present records), getAttendanceStream (emits updates). Use `FakeFirebaseFirestore`.

### Implementation for User Story 2

- [x] T014 [US2] Implement getAttendanceHistory, getMonthlyAttendanceCount, getTotalAttendanceCount, and getAttendanceStream methods in lib/services/attendance_service.dart per contracts/attendance-service-contract.md — getAttendanceHistory: query flat `attendance` collection for userId, return as List<AttendanceModel> sorted by date descending; getMonthlyAttendanceCount: count records in date range; getTotalAttendanceCount: count all present records; getAttendanceStream: return real-time stream with optional date range filter
- [x] T015 [P] [US2] Extract AttendanceHistoryList widget to lib/screens/components/attendance_history_list.dart — StatelessWidget receiving List<AttendanceModel> via constructor, renders scrollable list with date and status info, shows empty-state message when list is empty
- [x] T016 [US2] Refactor lib/screens/attendance_history_screen.dart — remove ALL direct Firestore queries and deprecated `workers/{id}/attendance` subcollection references (FR-002), use AttendanceService.getAttendanceHistory() for data (reads from flat `attendance` collection), use extracted AttendanceHistoryList widget, display monthly/yearly counts via service methods, handle empty state

**Checkpoint**: User Stories 1 AND 2 both work independently — staff can mark attendance and view full history with correct calendar highlights and counts. Run `flutter test` to verify.

---

## Phase 5: User Story 3 — Supervisor Verifies Team Attendance (Priority: P3)

**Goal**: A supervisor views team attendance for a given date and can verify individual records. Verified records display who verified them. Supervisors can only set `verifiedBy` — they cannot change `status`.

**Independent Test**: Supervisor opens team attendance for today, sees which members marked attendance, taps "Verify" on an unverified record; `verifiedBy` updates to supervisor's UID, `status` remains unchanged. Non-supervisors cannot verify.

### Tests for User Story 3 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T017 [P] [US3] Write unit tests for US3 service methods (append to test/services/attendance_service_test.dart) — test getTeamAttendance (returns correct records for given userIds and date, handles batch query for >10 users per Firestore whereIn limit), verifyAttendance (updates ONLY verifiedBy field, status remains unchanged per FR-011). Use `FakeFirebaseFirestore`.

### Implementation for User Story 3

- [x] T018 [US3] Implement getTeamAttendance and verifyAttendance methods in lib/services/attendance_service.dart per contracts/attendance-service-contract.md — getTeamAttendance: normalise date, batch query with whereIn (max 10 per batch), return List<AttendanceModel>; verifyAttendance: update ONLY `verifiedBy` field on document (FR-011), do NOT modify `status`
- [x] T019 [US3] Update supervisor verification UI in attendance screens — ensure team attendance view calls AttendanceService.getTeamAttendance() instead of direct Firestore queries, wire "Verify" button to AttendanceService.verifyAttendance(), display `verifiedBy` info on verified records, show permission error for non-supervisor users (FR-007)

**Checkpoint**: All 3 user stories are independently functional — marking, history, and verification all work through AttendanceService. Run `flutter test` to verify all pass.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Edge case coverage, remaining contract methods, final validation

- [x] T020 [P] Implement deleteAttendance method in lib/services/attendance_service.dart per contract — delete document by attendanceId (manager+ role enforced by Firestore rules)
- [x] T021 [P] Write edge case and screen behavior tests in test/screens/attendance_screen_test.dart covering all 6 edge cases from spec.md (SC-005): (1) no biometric hardware fallback, (2) missing Firestore user document shows "Not Logged In", (3) date timezone normalisation to UTC midnight, (4) network error shows message without allowing duplicate, (5) double-tap loading guard prevents duplicate writes, (6) outside time-window rejection with configured hours message
- [x] T022 Code cleanup and success criteria verification — confirm SC-001 (zero direct Firestore refs in screen files), SC-002 (no deprecated subcollection queries), SC-006 (attendance_screen.dart <600 lines), remove any dead code or unused imports across all modified files
- [x] T023 Run quickstart.md validation — execute `flutter test --coverage`, confirm ≥80% line coverage for AttendanceModel and AttendanceService (SC-003), verify SC-004 (double-tap test passes), verify all 23 tasks' output compiles and tests pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) — **BLOCKS all user stories**
- **User Story 1 (Phase 3)**: Depends on Foundational (Phase 2) — no dependencies on other stories
- **User Story 2 (Phase 4)**: Depends on Foundational (Phase 2) — can proceed in parallel with US1 if staffed, but sequentially recommended (US1 creates shared service patterns)
- **User Story 3 (Phase 5)**: Depends on Foundational (Phase 2) — can proceed in parallel with US1/US2 if staffed
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Starts after Phase 2. Independent — delivers MVP value alone.
- **User Story 2 (P2)**: Starts after Phase 2. Independent — reads from same `attendance` collection but does not depend on US1 implementation (only shared foundational model/service).
- **User Story 3 (P3)**: Starts after Phase 2. Independent — verification operates on existing records but does not require US1/US2 UI to function.

### Within Each User Story

1. Tests MUST be written FIRST and FAIL before implementation
2. Service methods before screen refactoring
3. Widget extraction (parallel) before screen integration
4. Screen refactoring last (consumes service + extracted widgets)

---

## Parallel Execution Examples

### Phase 2: Foundational (all 4 tasks in parallel)

```
Parallel batch:
  T003: Create lib/utils/app_constants.dart
  T004: Refactor AttendanceModel in lib/models/attendance_model.dart
  T005: Refactor AttendanceService constructor in lib/services/attendance_service.dart
  T006: Guard debug button in lib/screens/attendance_screen.dart
```

### Phase 3: User Story 1

```
Parallel batch 1 (tests):
  T007: Model tests in test/models/attendance_model_test.dart
  T008: Service tests in test/services/attendance_service_test.dart

Sequential:
  T009: Implement service methods in lib/services/attendance_service.dart

Parallel batch 2 (widget extraction):
  T010: Extract AttendanceStatsCard to lib/screens/components/attendance_stats_card.dart
  T011: Extract AttendanceCalendar to lib/screens/components/attendance_calendar.dart

Sequential:
  T012: Refactor lib/screens/attendance_screen.dart (consumes T009, T010, T011)
```

### Phase 4: User Story 2

```
Parallel batch 1:
  T013: Service tests (append to test/services/attendance_service_test.dart)
  T015: Extract AttendanceHistoryList to lib/screens/components/attendance_history_list.dart

Sequential:
  T014: Implement service methods in lib/services/attendance_service.dart
  T016: Refactor lib/screens/attendance_history_screen.dart (consumes T014, T015)
```

### Phase 5: User Story 3

```
Sequential (tests first):
  T017: Service tests (append to test/services/attendance_service_test.dart)
  T018: Implement service methods in lib/services/attendance_service.dart
  T019: Update supervisor verification UI
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003–T006)
3. Complete Phase 3: User Story 1 (T007–T012)
4. **STOP and VALIDATE**: Run `flutter test` — model and service tests pass, attendance marking works end-to-end
5. Deploy/demo if ready — staff can mark daily attendance with full validation

### Incremental Delivery

1. **Setup + Foundational** → Foundation ready (T001–T006)
2. **Add User Story 1** → Test independently → Deploy/Demo (**MVP!**) (T007–T012)
3. **Add User Story 2** → Test independently → Deploy/Demo (T013–T016)
4. **Add User Story 3** → Test independently → Deploy/Demo (T017–T019)
5. **Polish** → Full validation → Final release (T020–T023)
6. Each story adds value without breaking previous stories

### Single Developer Strategy (Recommended)

Execute phases sequentially in priority order: Setup → Foundational → US1 → US2 → US3 → Polish. Commit after each task or logical group. Validate at each checkpoint.

---

## Notes

- [P] tasks = different files, no dependencies on incomplete tasks in same phase
- [US1/US2/US3] labels map tasks to user stories for traceability
- All service methods follow contracts/attendance-service-contract.md signatures exactly
- All data shapes follow data-model.md entity definitions exactly
- Research decisions (research.md) are embedded in task descriptions: constructor DI, fake_cloud_firestore, abstract final class, widget extraction
- No new Firestore indexes required
- No visual/UX changes — refactor only

# Feature Specification: Refactor Attendance Module

**Feature Branch**: `001-refactor-attendance-module`
**Created**: 2026-03-08
**Status**: Draft
**Input**: User description: "Refactor existing attendance module to comply with the KSEB App Constitution and Spec-Driven Development workflow."

## Clarifications

### Session 2026-03-08

- Q: Can a supervisor change the attendance status (present/absent/leave), or only verify (set verifiedBy)? → A: Verify only — supervisors set `verifiedBy` but cannot change `status`.
- Q: Should `_isWithinAttendanceHours` enforce a real time window or be removed? → A: Enforce a time window; store the allowed hours in a central config/constants file editable without touching business logic.
- Q: Should the "Test Mode — Mark Without Biometric" button be kept, guarded, or removed? → A: Guard behind debug mode — only visible when `kDebugMode` is true.
- Q: Should the refactored module support recording `absent`/`leave` status, or only `present`? → A: `present` only for now; absence is implied by no record. Code MUST be structured so that `absent` and `leave` can be added later without refactoring the model or service interface.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Staff Marks Daily Attendance (Priority: P1)

A staff member opens the Attendance screen, authenticates via biometrics, and their attendance is recorded for the current day. The screen shows updated statistics (days present this month, this year, total).

**Why this priority**: This is the core action of the module. Every other feature (history, verification, stats) depends on attendance records existing.

**Independent Test**: Can be fully tested by a staff user opening the attendance screen and tapping "Mark Attendance" with biometric auth; delivers the primary value of recording daily presence.

**Acceptance Scenarios**:

1. **Given** a logged-in staff member who has not marked attendance today, **When** they tap "Mark Attendance" and pass biometric auth, **Then** an attendance record is created with status "present", date normalised to midnight, and current server timestamp.
2. **Given** a staff member who has already marked attendance today, **When** they attempt to mark again, **Then** the system rejects the request with a clear "already marked" message and no duplicate record is created.
3. **Given** a staff member who fails biometric auth, **When** the auth callback returns false, **Then** no attendance record is created and the user sees an authentication-failure message.

---

### User Story 2 — Staff Views Personal Attendance History (Priority: P2)

A staff member navigates to the attendance history view and sees a calendar and/or list of all dates they were present. Totals for the current month and year are displayed.

**Why this priority**: Viewing history is the most frequent read operation after marking attendance and provides transparency to staff.

**Independent Test**: Can be tested by viewing the calendar after several attendance records exist; the calendar highlights correct dates and counts match.

**Acceptance Scenarios**:

1. **Given** a staff member with 15 attendance records this month, **When** they open the history view, **Then** the calendar highlights exactly those 15 dates and the "This Month" counter reads 15.
2. **Given** a staff member with no records, **When** they open the history view, **Then** an empty-state message is displayed.
3. **Given** a staff member viewing history, **When** they navigate to a previous month, **Then** only that month's records are displayed and counts update accordingly.

---

### User Story 3 — Supervisor Verifies Team Attendance (Priority: P3)

A supervisor views team attendance for a given date and can verify (approve) individual records. Verified records show who verified them.

**Why this priority**: Verification enforces accountability and is a supervisor-only workflow that builds on top of staff-facing stories.

**Independent Test**: Can be tested by a supervisor viewing a team attendance list for today and tapping "Verify" on an unverified record; the `verifiedBy` field is updated.

**Acceptance Scenarios**:

1. **Given** a supervisor with 5 team members where 3 marked attendance today, **When** the supervisor opens team attendance for today, **Then** 3 records show as "present" and 2 show as "absent/not marked".
2. **Given** an unverified attendance record, **When** the supervisor taps "Verify", **Then** the record's `verifiedBy` field is set to the supervisor's user ID and the `status` field remains unchanged.
3. **Given** a user without supervisor (or higher) role, **When** they attempt to verify a record, **Then** the action is denied by Firestore rules and a permission error is shown.

---

### Edge Cases

- What happens when the device has no biometric hardware? The system should fall back to PIN/password authentication or show a clear error explaining biometric hardware is required.
- What happens when the user's Firestore document does not exist (deleted account)? The system should show "Not Logged In" and prevent attendance marking.
- What happens when the attendance record's `date` field is stored in a different timezone? All dates must be normalised to UTC midnight before comparison to prevent duplicate or missed detection.
- What happens when the Firestore query for "already marked today" fails due to network error? The system should show a network-error message and not silently allow a duplicate.
- What happens when two taps fire concurrently (double-tap)? The `markAttendance` method must be guarded with a loading/lock flag to prevent duplicate writes.
- What happens when a staff member tries to mark attendance outside the configured time window? The system must show a message like "Attendance can only be marked between [start] and [end]" using the values from the config file.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The attendance service MUST be the sole point of Firestore interaction for all attendance operations; no screen may query Firestore directly for attendance data.
- **FR-002**: The `AttendanceHistoryScreen` MUST read from the flat `attendance` collection (not the deprecated `workers/{id}/attendance` subcollection).
- **FR-003**: The `AttendanceModel` MUST be used by all screens and services as the single data contract for attendance records.
- **FR-004**: The `AttendanceScreen` MUST delegate all data-fetching and mutation logic to `AttendanceService`; direct `FirebaseFirestore` references MUST be removed from the screen.
- **FR-005**: The `markAttendance` flow MUST include a UI-level loading guard to prevent concurrent duplicate submissions (double-tap protection).
- **FR-006**: All attendance date comparisons MUST normalise dates to midnight (year, month, day) before comparison to avoid timezone drift or time-of-day mismatches.
- **FR-007**: Error handling MUST surface user-friendly messages for: network failures, permission denials, duplicate attendance, and missing user data.
- **FR-008**: Unit tests MUST be written for `AttendanceModel` (serialisation/deserialisation), `AttendanceService` (business logic with mocked Firestore), and key screen behaviors.
- **FR-009**: Public holidays displayed in the calendar MUST be configurable (not hard-coded to a specific year) — ideally derived from configuration or data, not inline constants.
- **FR-010**: Attendance marking MUST be restricted to a configurable time window. The allowed start and end hours MUST be defined in a central configuration file (e.g., `lib/utils/app_constants.dart` or equivalent) so they can be edited without modifying business logic. The attendance flow MUST reject attempts outside this window with a clear user-facing message.
- **FR-011**: Supervisor verification MUST only set the `verifiedBy` field; supervisors MUST NOT be permitted to change the `status` field of an attendance record through the verify action.
- **FR-012**: The "Test Mode — Mark Without Biometric" button MUST be guarded behind `kDebugMode` so it is only visible in development/debug builds and never ships in release builds.
- **FR-013**: The app MUST only write `present` as the attendance status in this iteration. However, the `AttendanceModel` and `AttendanceService` MUST accept status as a parameter (defaulting to `present`) so that `absent` and `leave` can be added in a future iteration without changing the model or service interface.

### Key Entities

- **AttendanceRecord**: Represents a single day's attendance for one user. Key attributes: userId, date (normalised midnight), status (present/absent/leave — only `present` used in this iteration; `absent` and `leave` reserved for future use), verifiedBy (nullable), worksheetId (nullable), timestamp (server time of creation).
- **User (existing)**: The staff/supervisor/manager who marks or verifies attendance. Linked by userId.
- **Team (existing)**: Used by supervisors to scope which users' attendance they can view/verify.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero direct Firestore references remain in attendance screen files; all data access routes through `AttendanceService`.
- **SC-002**: `AttendanceHistoryScreen` reads from the flat `attendance` collection; queries against the deprecated `workers/{id}/attendance` path are removed.
- **SC-003**: Unit tests exist for `AttendanceModel.fromFirestore`, `AttendanceModel.toMap`, and all public `AttendanceService` methods, with ≥ 80% line coverage of those classes.
- **SC-004**: Double-tap on "Mark Attendance" produces exactly one attendance record (verified by test).
- **SC-005**: All five edge cases listed above are covered by explicit test scenarios.
- **SC-006**: The attendance screen file is refactored to under 600 lines (from current ~1,223) by extracting reusable widgets and delegating logic to the service.

### Assumptions

- The flat `attendance` Firestore collection and its security rules are the canonical data source; the deprecated `workers/{id}/attendance` subcollection will not be used.
- Biometric authentication is handled by the `local_auth` package and its behavior is out of scope for this refactor (no change to auth flow needed).
- Public holiday data is currently hard-coded; making it fully dynamic (e.g., fetched from Firestore) is out of scope but the code should be structured so that the data source can be swapped later.
- No new Firestore indexes are required — existing indexes on `userId` and `userId + date` are sufficient.
- The refactor does not change the visual design or UX of the attendance screens; it only restructures the code.

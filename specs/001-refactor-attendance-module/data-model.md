# Data Model: Refactor Attendance Module

**Feature**: 001-refactor-attendance-module
**Date**: 2026-03-08

## Entities

### AttendanceModel

Represents a single day's attendance record for one user.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | `String` | Yes | Auto-generated | Firestore document ID |
| `userId` | `String` | Yes | — | UID of the staff member |
| `worksheetId` | `String?` | No | `null` | Optional link to a worksheet |
| `date` | `DateTime` | Yes | — | Normalised to midnight (year, month, day) |
| `verifiedBy` | `String?` | No | `null` | UID of supervisor who verified |
| `status` | `String` | Yes | `'present'` | One of: `present`, `absent`, `leave`. Only `present` written in this iteration; `absent` and `leave` reserved for future use |
| `timestamp` | `DateTime` | Yes | Server timestamp | Actual time the record was created |

**Firestore collection**: `attendance` (flat, top-level)

**Firestore document structure**:
```json
{
  "userId": "abc123",
  "worksheetId": null,
  "date": "Timestamp(2026-03-08T00:00:00Z)",
  "verifiedBy": null,
  "status": "present",
  "timestamp": "Timestamp(2026-03-08T08:15:32Z)"
}
```

**Indexes** (existing — no new indexes required):
- `userId` (single field)
- Composite: `userId` + `date`
- `worksheetId` (single field)
- `verifiedBy` (single field)

### Validation Rules

| Rule | Enforcement Point | Description |
|------|-------------------|-------------|
| One record per user per day | `AttendanceService.markAttendance()` | Query `userId + date` before insert; reject if exists |
| Date normalised to midnight | `AttendanceService.markAttendance()` | `DateTime(now.year, now.month, now.day)` |
| Status must be valid | `AttendanceModel` constructor | Assert status ∈ {`present`, `absent`, `leave`} |
| Verify-only updates | `AttendanceService.updateAttendanceStatus()` | Only `verifiedBy` field updated; `status` unchanged |
| Time-window enforcement | `AttendanceScreen` (UI) + `AttendanceService` (optional) | Reject marking outside configured hours |

### State Transitions

```
[No Record] → markAttendance() → [present, verifiedBy=null]
[present, verifiedBy=null] → verifyAttendance() → [present, verifiedBy=supervisorId]
```

Future iterations may add:
```
[No Record] → markAbsent() → [absent, verifiedBy=null]
[No Record] → markLeave() → [leave, verifiedBy=null]
```

### Relationships

```
User (1) ──── (0..*) AttendanceModel   [userId → User.id]
Team (1) ──── (1..*) User              [User.teamId → Team.id]
AttendanceModel (0..1) ── (0..1) Worksheet  [worksheetId → Worksheet.id]
AttendanceModel (0..1) ── (0..1) User       [verifiedBy → User.id (supervisor)]
```

## Configuration Entity

### AttendanceConstants

Stored in `lib/utils/app_constants.dart` as compile-time constants.

| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `attendanceStartHour` | `int` | `6` | Earliest hour attendance can be marked (inclusive) |
| `attendanceEndHour` | `int` | `22` | Latest hour attendance can be marked (exclusive) |
| `workingDaysInYear` | `int` | `240` | Total working days for yearly progress calculation |

### PublicHoliday (future-ready structure)

Currently hard-coded as a `Set<DateTime>` in the screen. After refactor, extracted to a utility method in `app_constants.dart` that accepts a `year` parameter and returns `Set<DateTime>` — making the data source swappable later.

| Field | Type | Description |
|-------|------|-------------|
| `date` | `DateTime` | Normalised to midnight |
| `name` | `String` | Holiday name (for display; optional in this iteration) |

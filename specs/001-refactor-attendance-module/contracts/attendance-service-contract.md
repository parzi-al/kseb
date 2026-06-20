# Service Contract: AttendanceService

**Feature**: 001-refactor-attendance-module
**Date**: 2026-03-08

## Overview

`AttendanceService` is the sole Firestore access point for all attendance operations. No screen may query Firestore directly for attendance data (FR-001).

## Constructor

```
AttendanceService({FirebaseFirestore? firestore})
```

- `firestore`: Optional. Defaults to `FirebaseFirestore.instance` in production. Accepts `FakeFirebaseFirestore()` in tests.

## Public Methods

### markAttendance

```
Future<bool> markAttendance({
  required String userId,
  String? worksheetId,
  String? verifiedBy,
  String status = 'present',
})
```

**Behaviour**:
1. Normalise current date to midnight.
2. Build deterministic document ID `{encodedUserId}_{yyyyMMdd}` for the user/day.
3. Run a Firestore transaction and read that document.
4. If record exists → throw `AttendanceAlreadyMarkedException`.
5. If no record → insert new document with `userId`, `worksheetId`, `date` (midnight), `verifiedBy`, `status`, `timestamp` (server timestamp).
6. Return `true` on success.

**Consistency note**: deterministic IDs plus transactional reads prevent duplicate daily attendance records from rapid double taps, retries, or multiple devices submitting at the same time.

**Error conditions**:
- `AttendanceAlreadyMarkedException` — attendance already marked for today
- `FirebaseException` — network failure or permission denied
- `ArgumentError` — invalid status value (not in `{present, absent, leave}`)

---

### getMonthlyAttendanceCount

```
Future<int> getMonthlyAttendanceCount({
  required String userId,
  required int year,
  required int month,
})
```

**Behaviour**: Run a Firestore aggregate count where `userId == userId`, `date >= monthStart`, `date < nextMonthStart`, `status == 'present'`. Return count without downloading matching documents.

---

### getTotalAttendanceCount

```
Future<int> getTotalAttendanceCount(String userId)
```

**Behaviour**: Run a Firestore aggregate count where `userId == userId`, `status == 'present'`. Return count without downloading matching documents.

---

### getAttendanceStream

```
Stream<QuerySnapshot> getAttendanceStream({
  required String userId,
  DateTime? startDate,
  DateTime? endDate,
})
```

**Behaviour**: Return a real-time stream of attendance records for `userId`, optionally filtered by date range. Ordered by `date` descending.

---

### getTeamAttendance

```
Future<List<AttendanceModel>> getTeamAttendance({
  required List<String> userIds,
  required DateTime date,
})
```

**Behaviour**:
1. Normalise `date` to midnight.
2. Batch query (max 10 per Firestore `whereIn` limit).
3. Return list of `AttendanceModel` instances.

**Change from current**: Returns `List<AttendanceModel>` instead of `List<Map<String, dynamic>>` (FR-003).

---

### verifyAttendance

```
Future<void> verifyAttendance({
  required String attendanceId,
  required String verifiedBy,
})
```

**Behaviour**: Update ONLY the `verifiedBy` field of the document. The `status` field MUST NOT be changed (FR-011).

**Change from current**: Renamed from `updateAttendanceStatus` to `verifyAttendance`. Removed `status` parameter. Old method signature deprecated.

---

### deleteAttendance

```
Future<void> deleteAttendance(String attendanceId)
```

**Behaviour**: Delete the document. Only callable by manager+ roles (enforced by Firestore rules, not app code).

---

### isAttendanceMarkedToday

```
Future<bool> isAttendanceMarkedToday(String userId)
```

**Behaviour**: Normalise today to midnight. Query `attendance` where `userId == userId` AND `date == today`. Return `docs.isNotEmpty`.

---

### getUserAttendanceStats

```
Future<Map<String, dynamic>> getUserAttendanceStats(String userId)
```

**Behaviour**: Fetch all records for `userId` in a single query. Compute and return:
- `total` (int): Total present days
- `thisMonth` (int): Present days in current month
- `thisYear` (int): Present days in current year
- `isMarkedToday` (bool): Whether attendance exists for today

---

### getAttendanceHistory

```
Future<List<AttendanceModel>> getAttendanceHistory(String userId)
```

**Behaviour**: Return all attendance records for `userId` as `AttendanceModel` instances, sorted by date descending. This is the method `AttendanceHistoryScreen` MUST use instead of direct Firestore queries (FR-002).

**New method**: Does not exist in current service; must be added.

## Error Types

| Error | When | User-facing message |
|-------|------|---------------------|
| `AttendanceAlreadyMarkedException` | Duplicate attendance attempt | "Attendance already marked for today." |
| `FirebaseException` (permission-denied) | Role violation | "You don't have permission to perform this action." |
| `FirebaseException` (unavailable) | Network failure | "Network error. Please check your connection and try again." |
| `ArgumentError` | Invalid status value | Internal error — should not reach user |

## Firestore Security Rules

```
match /attendance/{attendanceId} {
  allow read: if request.auth != null && (
    resource.data.userId == request.auth.uid ||
    isRole('supervisor') || isRole('manager') || isRole('coo') || isRole('director')
  );
  allow create: if request.auth != null && isValidAttendanceCreate() && (
    (request.resource.data.userId == request.auth.uid && request.resource.data.date == today) ||
    isRole('supervisor') || isRole('manager') || isRole('coo') || isRole('director')
  );
  allow update: if request.auth != null && (
    isRole('supervisor') || isRole('manager') || isRole('coo') || isRole('director')
  );
  allow delete: if request.auth != null && (
    isRole('manager') || isRole('coo') || isRole('director')
  );
}
```

**Change**: Supervisors and above may create attendance records for team/member workflows. Self-service users remain limited to creating their own attendance for the current day.

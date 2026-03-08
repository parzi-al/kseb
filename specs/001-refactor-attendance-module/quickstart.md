# Quickstart: Refactor Attendance Module

**Feature**: 001-refactor-attendance-module
**Date**: 2026-03-08

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                      UI Layer                            │
│  ┌──────────────────┐  ┌───────────────────────────────┐ │
│  │ AttendanceScreen  │  │ AttendanceHistoryScreen       │ │
│  │ (<600 lines)      │  │ (uses flat collection)        │ │
│  └───────┬──────────┘  └──────────┬────────────────────┘ │
│          │  uses                   │  uses                │
│  ┌───────┴──────────────────────────┴───────────────────┐ │
│  │              Extracted Widgets                        │ │
│  │  ┌──────────────┐ ┌────────────┐ ┌────────────────┐  │ │
│  │  │ Calendar     │ │ StatsCard  │ │ HistoryList    │  │ │
│  │  └──────────────┘ └────────────┘ └────────────────┘  │ │
│  └──────────────────────────────────────────────────────┘ │
└──────────────────────┬───────────────────────────────────┘
                       │ calls (no direct Firestore)
┌──────────────────────┴───────────────────────────────────┐
│                   Service Layer                          │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ AttendanceService                                    │ │
│  │ - markAttendance()          - getAttendanceHistory() │ │
│  │ - getUserAttendanceStats()  - verifyAttendance()     │ │
│  │ - getTeamAttendance()       - isAttendanceMarkedToday│ │
│  └───────────────────────┬──────────────────────────────┘ │
└──────────────────────────┬───────────────────────────────┘
                           │ reads/writes
┌──────────────────────────┴───────────────────────────────┐
│                   Data Layer                             │
│  ┌────────────────┐  ┌─────────────────────────────────┐ │
│  │ AttendanceModel│  │ Firestore: attendance collection │ │
│  │ (single data   │  │ (flat, top-level)               │ │
│  │  contract)     │  │                                 │ │
│  └────────────────┘  └─────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│                   Config Layer                           │
│  app_constants.dart                                      │
│  - AttendanceConstants.startHour (6)                     │
│  - AttendanceConstants.endHour (22)                      │
│  - AttendanceConstants.workingDaysInYear (240)           │
│  - getPublicHolidays(year) → Set<DateTime>              │
└──────────────────────────────────────────────────────────┘
```

## Component Diagram

| Component | File | Responsibility |
|-----------|------|---------------|
| `AttendanceScreen` | `lib/screens/attendance_screen.dart` | Coordinator: state management, biometric auth, delegates all data ops to service |
| `AttendanceHistoryScreen` | `lib/screens/attendance_history_screen.dart` | History view; uses `AttendanceService.getAttendanceHistory()` |
| `AttendanceCalendar` | `lib/screens/components/attendance_calendar.dart` | Extracted widget: calendar view with attendance markers |
| `AttendanceStatsCard` | `lib/screens/components/attendance_stats_card.dart` | Extracted widget: stat cards (this month, this year, total, status) |
| `AttendanceHistoryList` | `lib/screens/components/attendance_history_list.dart` | Extracted widget: scrollable list of attendance records |
| `AttendanceService` | `lib/services/attendance_service.dart` | Sole Firestore access point for attendance CRUD |
| `AttendanceModel` | `lib/models/attendance_model.dart` | Single data contract; serialisation/deserialisation |
| `AppConstants` | `lib/utils/app_constants.dart` | Configurable attendance hours, working days, public holidays |

## Data Flow

### Mark Attendance
```
User taps "Mark Attendance"
  → AttendanceScreen checks time window (AppConstants)
  → AttendanceScreen triggers biometric auth (local_auth)
  → On success: AttendanceService.markAttendance(userId)
    → Service normalises date to midnight
    → Service queries Firestore: already marked today?
    → If no: Service inserts document
    → Returns true
  → AttendanceScreen refreshes stats via getUserAttendanceStats()
  → UI updates
```

### View History
```
User opens AttendanceHistoryScreen
  → Screen calls AttendanceService.getAttendanceHistory(userId)
  → Service queries flat `attendance` collection (NOT workers subcollection)
  → Returns List<AttendanceModel>
  → Screen maps to calendar highlights + list items
```

### Supervisor Verifies
```
Supervisor opens team attendance view
  → Screen calls AttendanceService.getTeamAttendance(userIds, date)
  → Returns List<AttendanceModel>
  → Supervisor taps "Verify" on a record
  → Screen calls AttendanceService.verifyAttendance(attendanceId, supervisorId)
  → Service updates ONLY verifiedBy field
  → UI updates
```

## Dependency Boundaries

| Depends On | Used By |
|------------|---------|
| `cloud_firestore` | `AttendanceService` ONLY |
| `firebase_auth` | `AttendanceScreen` (for current user UID) |
| `local_auth` | `AttendanceScreen` (biometric auth) |
| `table_calendar` | `AttendanceCalendar` widget |
| `percent_indicator` | `AttendanceScreen` (yearly progress) |
| `AttendanceService` | Both screens + tests |
| `AttendanceModel` | Service + screens + tests |
| `AppConstants` | Screens + service |

## How to Run Tests

```bash
# Add fake_cloud_firestore to dev_dependencies
flutter pub add --dev fake_cloud_firestore

# Run all tests
flutter test

# Run attendance tests only
flutter test test/models/attendance_model_test.dart
flutter test test/services/attendance_service_test.dart

# Run with coverage
flutter test --coverage
```

## Key Decisions

1. **No state management package** — callbacks + constructor params suffice
2. **`fake_cloud_firestore`** for unit tests — no emulator needed
3. **`abstract final class`** for constants — idiomatic Dart 3+
4. **Constructor DI** for `AttendanceService` — `FirebaseFirestore?` param defaults to `.instance`
5. **Widget extraction** to `lib/screens/components/` — reduces main screen to <600 lines

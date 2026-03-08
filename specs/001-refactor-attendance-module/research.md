# Research: Refactor Attendance Module

**Feature**: 001-refactor-attendance-module
**Date**: 2026-03-08

## 1. Widget Extraction Pattern

**Decision**: Extract logical UI sections into small, single-purpose `StatelessWidget` classes in a `lib/screens/components/` subdirectory. Pass data down as constructor parameters and behaviour up as callbacks (`VoidCallback`, `ValueChanged<T>`).

**Rationale**: This is the canonical Flutter approach ("Lifting state up"). The ~1,223-line `attendance_screen.dart` has distinct sections (header, stats cards, calendar, history list, action buttons) that map naturally to separate widget files. Constructor-param passing keeps the dependency graph explicit, makes each widget independently testable, and allows `const` constructors for rebuild optimisation. No state management package is needed.

**Alternatives considered**:
- **InheritedWidget/InheritedModel**: Adds boilerplate with minimal benefit for a 2–3 level deep tree. Not justified.
- **Provider/Riverpod/Bloc**: Project has no such dependency; introducing one for a single-screen refactor is disproportionate.
- **Private helper methods (`_buildHeader()`)**: Can't be `const`, can't have own lifecycle, can't be independently tested, and don't reduce file line count. Defeated by framework rebuild semantics.

## 2. Mocking Firestore in Unit Tests

**Decision**: Use the `fake_cloud_firestore` package. Inject `FirebaseFirestore` via constructor parameter into `AttendanceService` instead of using `FirebaseFirestore.instance` directly.

**Rationale**: `fake_cloud_firestore` provides an in-memory implementation of the Firestore API surface (collections, documents, queries, snapshots, streams). Tests run without network, Firebase emulator, or Docker. Fast, deterministic, CI-friendly. The only prerequisite is that `AttendanceService` accepts a `FirebaseFirestore` instance via its constructor (one-line refactor).

**Alternatives considered**:
- **Manual mocking (mockito/mocktail)**: Firestore's API surface is wide (`CollectionReference` → `DocumentReference` → `DocumentSnapshot` → nested `Query`). Manual stubbing is tedious, fragile, and must track SDK changes.
- **Firebase Emulator Suite**: Valuable for security-rule integration tests but too heavyweight for unit testing a service class. 10–100× slower, requires running emulator process.

## 3. Configurable Constants Pattern

**Decision**: Create `lib/utils/app_constants.dart` with an `abstract final class` containing `static const` fields, grouped by domain (e.g., `AttendanceConstants.startHour`, `AttendanceConstants.endHour`).

**Rationale**: `abstract final class` (Dart 3+) is un-instantiable and un-extendable — clear intent as a namespace. `static const` fields are compile-time constants. Consistent with existing project patterns (`app_colors.dart`, `app_toast.dart` in `lib/utils/`). No runtime overhead, no DI needed, trivially discoverable.

**Alternatives considered**:
- **Top-level const variables**: Pollutes auto-complete without namespacing when multiple domains exist.
- **Enums**: Semantically wrong — enums represent closed variant sets, not configuration values.
- **JSON/YAML config loaded at runtime**: Adds latency, error handling, and parsing dependency for values that are business rules, not per-environment settings.
- **`dart-define` compile-time env vars**: Awkward for a dozen business constants; over-engineering.

## 4. Dependency Injection for Testability

**Decision**: Refactor `AttendanceService` constructor to accept an optional `FirebaseFirestore` parameter, defaulting to `FirebaseFirestore.instance`. This enables injecting `FakeFirebaseFirestore()` in tests without changing production call sites.

**Rationale**: Minimal change (one constructor parameter with a default) that unlocks full testability. Existing code that calls `AttendanceService()` continues to work unchanged.

**Alternatives considered**:
- **Service locator (get_it)**: Over-engineering for a single service; adds a package dependency.
- **Mandatory constructor parameter**: Would break all existing call sites. Default parameter avoids this.

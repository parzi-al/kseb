# Data Model: Fix Auth Navigation & Login UI

**Feature**: 004-fix-auth-navigation-ui  
**Date**: 2026-03-09  
**Source**: spec.md Key Entities + research.md decisions

## Entities

### 1. Auth Audit Event

**Collection**: `auth_events`  
**Purpose**: Append-only log of security-relevant auth actions for admin audit visibility (FR-018, FR-019).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `userId` | `String` | No* | Firebase Auth UID. Null for failed logins where user is unknown. |
| `email` | `String` | Yes | Email used in the auth attempt. Always available. |
| `eventType` | `String` (enum) | Yes | One of: `login_success`, `login_failure`, `logout`, `idle_timeout`, `force_logout` |
| `timestamp` | `Timestamp` | Yes | Server timestamp of event occurrence. |
| `deviceInfo` | `String` | No | Device model / OS version string (best-effort). |
| `sessionToken` | `String` | No | Session token at time of event (for correlation). |
| `metadata` | `Map<String, dynamic>` | No | Optional extra data (e.g., failure reason, IP). |

**Auto-generated ID**: Firestore auto-ID (no custom document ID needed).

*`userId` is null for `login_failure` events where the email doesn't map to a known user.

**Validation rules**:
- `eventType` must be one of the 5 defined enum values.
- `timestamp` must be a server timestamp (not client-set).
- `email` must not be empty.

**State transitions**: None — events are immutable, append-only.

---

### 2. Device Session (stored on User document)

**Collection**: `users/{uid}` (additional fields on existing document)  
**Purpose**: Track the single active session for enforcing one-device-at-a-time login (FR-020, FR-022).

Per research R2, session data is stored as fields on the existing `users` document rather than a separate collection.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `activeSessionToken` | `String` | No | UUID generated on login. Null if no active session. |
| `lastLoginAt` | `Timestamp` | No | Timestamp of most recent login. |

**Existing fields** (unchanged): `name`, `email`, `phone`, `role`, `teamId`, `areaCode`, `photoUrl`, `insuranceId`, `bonusPoints`, `bonusAmount`, `dob`, `createdAt`.

**Validation rules**:
- `activeSessionToken` is a non-empty string when present.
- `lastLoginAt` is a Firestore Timestamp when present.
- Only the authenticated user or the system (on login) can write these fields.

**State transitions**:
- On login: `activeSessionToken` = new UUID, `lastLoginAt` = server timestamp.
- On logout: `activeSessionToken` = null (cleared).
- On force-logout (detected by another device): reading device sees mismatch → calls signOut locally.

---

### 3. Idle Timeout Configuration

**Collection**: `app_settings`  
**Document**: `auth`  
**Purpose**: Admin-configurable auth settings including idle timeout duration (FR-011, FR-012).

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `idleTimeoutMinutes` | `int` | Yes | `15` | Minutes of inactivity before auto-logout. |

**Validation rules**:
- `idleTimeoutMinutes` must be a positive integer ≥ 1.
- Only admin users (manager and above) can modify this document.

**State transitions**: None — this is a configuration value, not a stateful entity.

---

### 4. Auth Session (in-memory, not persisted)

**Purpose**: Represents the local auth state driven by `FirebaseAuth.authStateChanges()` stream (FR-009).

| Property | Type | Description |
|----------|------|-------------|
| `user` | `User?` | Firebase Auth User object. Null = unauthenticated. |
| `isAuthenticated` | `bool` | Derived: `user != null` |
| `localSessionToken` | `String?` | UUID generated on login, stored in-memory for session comparison. |

**Not stored in Firestore** — this is the Flutter app's in-memory representation of the current auth state.

---

### 5. Login Rate Limiter State (in-memory, not persisted)

**Purpose**: Tracks failed login attempts for progressive cooldown (FR-015, FR-016, FR-017).

| Property | Type | Description |
|----------|------|-------------|
| `failedAttempts` | `int` | Count of consecutive credential failures. Resets on success or app restart. |
| `cooldownSeconds` | `int` | Current remaining cooldown seconds. 0 = no cooldown active. |
| `isInCooldown` | `bool` | Derived: `cooldownSeconds > 0` |

**Not stored in Firestore** — intentionally in-memory only per FR-017.

**Cooldown thresholds**:
| Failed Attempts | Cooldown Duration |
|----------------|-------------------|
| 3 | 5 seconds |
| 5 | 15 seconds |
| 8 | 30 seconds |

---

## Entity Relationship Summary

```
FirebaseAuth (external)
    │
    ├── authStateChanges() stream → drives AuthGate navigation
    │
    └── User
         │
         ├── users/{uid} (Firestore)
         │    ├── [existing fields: name, email, role, ...]
         │    ├── activeSessionToken (NEW)
         │    └── lastLoginAt (NEW)
         │
         └── auth_events (Firestore, append-only)
              └── {auto-id}
                   ├── userId
                   ├── email
                   ├── eventType
                   ├── timestamp
                   └── deviceInfo, sessionToken, metadata

app_settings/auth (Firestore)
    └── idleTimeoutMinutes: int

[In-memory only]
    ├── Auth Session (localSessionToken)
    └── Login Rate Limiter (failedAttempts, cooldownSeconds)
```

## Changes to Existing Entities

### UserModel (lib/models/user_model.dart)

Two new optional fields added:

```dart
final String? activeSessionToken;  // NEW
final DateTime? lastLoginAt;       // NEW (maps to Firestore Timestamp)
```

These fields must be added to:
- Constructor (optional, nullable)
- `fromFirestore` factory
- `fromMap` factory
- `toMap` method
- `copyWith` method

No other existing fields are modified.

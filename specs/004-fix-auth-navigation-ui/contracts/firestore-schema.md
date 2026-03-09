# Firestore Schema Contract: Fix Auth Navigation & Login UI

**Feature**: 004-fix-auth-navigation-ui  
**Date**: 2026-03-09  
**Source**: data-model.md, spec.md FR-018 through FR-022

This document defines the Firestore collections and security rules added or modified by this feature.

---

## New Collection: `auth_events`

### Schema

```
auth_events/{auto-id}
├── userId: string | null          # Firebase UID (null for unknown-user failures)
├── email: string                  # Email used in attempt (required)
├── eventType: string              # Enum: login_success | login_failure | logout | idle_timeout | force_logout
├── timestamp: timestamp           # Server timestamp (required)
├── deviceInfo: string | null      # Device model / OS (best effort)
├── sessionToken: string | null    # Session token for correlation
└── metadata: map | null           # Optional: { reason: string, ... }
```

### Security Rules

```
match /auth_events/{eventId} {
  // Any authenticated user can create audit events (the app writes on their behalf)
  allow create: if request.auth != null
    && request.resource.data.eventType in ['login_success', 'login_failure', 'logout', 'idle_timeout', 'force_logout']
    && request.resource.data.timestamp == request.time;
  
  // Only managers and above can read audit events (admin visibility)
  allow read: if request.auth != null && isManagerOrAbove();
  
  // No updates or deletes — append-only (FR-019)
  allow update, delete: if false;
}
```

### Example Document

```json
{
  "userId": "abc123",
  "email": "worker@kseb.in",
  "eventType": "login_success",
  "timestamp": "2026-03-09T10:30:00Z",
  "deviceInfo": "Pixel 7 / Android 15",
  "sessionToken": "sess_1741512600_x7k9",
  "metadata": null
}
```

---

## New Document: `app_settings/auth`

### Schema

```
app_settings/auth
└── idleTimeoutMinutes: number     # Positive integer, minimum 1, default 15
```

### Security Rules

```
match /app_settings/{settingId} {
  // All authenticated users can read settings (needed for idle timeout config)
  allow read: if request.auth != null;
  
  // Only managers and above can modify settings
  allow create, update: if request.auth != null && isManagerOrAbove();
  
  // Only directors can delete settings
  allow delete: if request.auth != null && isDirector();
}
```

### Example Document

```json
{
  "idleTimeoutMinutes": 15
}
```

---

## Modified Document: `users/{uid}`

### New Fields (added to existing schema)

```
users/{uid}
├── [all existing fields unchanged]
├── activeSessionToken: string | null   # NEW — UUID generated on login
└── lastLoginAt: timestamp | null       # NEW — timestamp of most recent login
```

### Security Rules Update

The existing `users/{userId}` rules already allow authenticated users to update their own profile (excluding `role` and `email`). The new fields `activeSessionToken` and `lastLoginAt` are writable by the owning user, which is compatible with existing rules:

```
// Existing rule (no change needed):
allow update: if request.auth != null && 
  request.auth.uid == userId &&
  !request.resource.data.diff(resource.data).affectedKeys().hasAny(['role', 'email']);
```

Since `activeSessionToken` and `lastLoginAt` are not in the restricted set (`role`, `email`), the existing rule already permits the user to write them. **No rule change needed for `users` collection.**

---

## Dart Model Contracts

### AuthEventModel

```dart
/// Represents an entry in the auth_events Firestore collection.
class AuthEventModel {
  final String? userId;
  final String email;
  final AuthEventType eventType;
  final DateTime timestamp;
  final String? deviceInfo;
  final String? sessionToken;
  final Map<String, dynamic>? metadata;

  // Factory: fromFirestore(DocumentSnapshot)
  // Method: toMap() → Map<String, dynamic>
}

enum AuthEventType {
  loginSuccess,
  loginFailure,
  logout,
  idleTimeout,
  forceLogout;

  String get firestoreValue; // e.g., 'login_success'
  static AuthEventType fromString(String value);
}
```

### DeviceSessionModel (fields on UserModel)

```dart
/// Extension of UserModel — two new nullable fields:
/// - activeSessionToken: String?
/// - lastLoginAt: DateTime?
```

### LoginRateLimiter (in-memory utility)

```dart
/// Progressive rate limiter for failed login attempts.
class LoginRateLimiter {
  int get failedAttempts;
  bool get isInCooldown;
  int get remainingSeconds;
  Stream<int> get cooldownStream; // Emits remaining seconds each tick

  void recordFailure();
  void reset();
  void dispose();
}
```

### IdleTimeoutService (in-memory utility)

```dart
/// Manages inactivity timer for auto-logout.
class IdleTimeoutService {
  void start({required int timeoutMinutes, required VoidCallback onTimeout});
  void resetTimer();
  void stop();
  void dispose();
}
```

---

## Service Contracts

### AuthService

```dart
/// Central orchestrator for all auth operations.
class AuthService {
  Stream<User?> get authStateChanges;    // Proxy for FirebaseAuth.authStateChanges()
  User? get currentUser;                 // Current Firebase user
  String? get localSessionToken;         // In-memory session token
  
  Future<UserCredential> signIn(String email, String password);
  Future<void> signOut({String reason});  // reason: 'manual' | 'idle_timeout' | 'force_logout'
  Future<bool> validateSession();         // Check Firestore token vs local token
}
```

### AuthAuditService

```dart
/// Writes auth events to Firestore.
class AuthAuditService {
  Future<void> logEvent({
    required AuthEventType eventType,
    required String email,
    String? userId,
    String? sessionToken,
    Map<String, dynamic>? metadata,
  });
}
```

### SessionService

```dart
/// Manages single-session enforcement.
class SessionService {
  Future<String> createSession(String userId);    // Returns new session token
  Future<void> clearSession(String userId);       // Clears session on logout
  Future<bool> isSessionValid(String userId, String localToken); // Compare tokens
}
```

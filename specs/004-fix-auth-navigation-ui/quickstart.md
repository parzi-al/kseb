# Quickstart: Fix Auth Navigation & Login UI

**Feature**: 004-fix-auth-navigation-ui  
**Date**: 2026-03-09  
**Purpose**: Minimal steps to verify the feature works end-to-end after implementation.

## Prerequisites

- Flutter SDK installed (3.6+)
- Firebase project configured (`google-services.json` present)
- A test user account in Firebase Authentication (email/password)
- Device or emulator running

## Quick Verification Steps

### 1. Login Navigation (FR-001, SC-001)

```
1. Run the app: `flutter run`
2. App shows splash → transitions to Login Screen
3. Enter valid test credentials
4. Tap "SIGN IN"
5. ✅ VERIFY: Loading indicator appears on the button
6. ✅ VERIFY: After auth succeeds, Worker Home Screen appears within 2 seconds
7. ✅ VERIFY: Pressing system back button does NOT return to login screen
```

### 2. Logout Navigation (FR-002, SC-002)

```
1. From Worker Home Screen, tap the logout icon (top-right)
2. Confirm in the logout dialog
3. ✅ VERIFY: Login Screen appears within 2 seconds
4. ✅ VERIFY: Pressing system back button does NOT return to home screen
```

### 3. Login Icon Centered + Animation (FR-006, FR-007, SC-004, SC-005)

```
1. On the Login Screen, observe the round bolt icon at the top
2. ✅ VERIFY: Icon is horizontally centered on the screen
3. ✅ VERIFY: Icon plays a scale-in + glow entrance animation (~800ms)
4. ✅ VERIFY: Animation is smooth (no jank)
```

### 4. Password Strength Indicator (FR-013, FR-014)

```
1. On the Login Screen, start typing in the password field
2. ✅ VERIFY: A strength indicator appears below the password field
3. Type "abc" → ✅ VERIFY: Shows "Weak" (red)
4. Type "abcdef" → ✅ VERIFY: Shows "Weak" (red)
5. Type "Abcdef1" → ✅ VERIFY: Shows "Fair" (amber)
6. Type "Abcdef1!" → ✅ VERIFY: Shows "Strong" (green)
7. ✅ VERIFY: Strength updates in real-time as you type
```

### 5. Rate Limiting (FR-015, FR-016)

```
1. Enter valid email but wrong password
2. Tap "SIGN IN" — should fail with error
3. Repeat 2 more times (3 total failures)
4. ✅ VERIFY: After 3rd failure, a countdown timer (5s) appears
5. ✅ VERIFY: SIGN IN button is disabled during countdown
6. Wait for countdown to expire, fail 2 more times (5 total)
7. ✅ VERIFY: 15-second cooldown appears
```

### 6. Audit Log (FR-018)

```
1. After a successful login, open Firebase Console → Firestore
2. Navigate to auth_events collection
3. ✅ VERIFY: A document exists with eventType: "login_success", correct email, timestamp
4. After a successful logout, check again
5. ✅ VERIFY: A document exists with eventType: "logout"
```

### 7. Single Session (FR-020, FR-021, SC-009)

```
1. Log in on Device A (or emulator A)
2. Log in with same credentials on Device B (or emulator B)
3. On Device A, interact with the app (tap any screen, or background→foreground)
4. ✅ VERIFY: Device A shows a notification "You have been signed out because your account was logged in on another device"
5. ✅ VERIFY: Device A redirects to Login Screen
```

### 8. Idle Timeout (FR-011, FR-012)

```
1. For quick testing, temporarily set idleTimeoutMinutes to 1 in Firestore (app_settings/auth)
2. Log in and leave the app idle for >1 minute
3. ✅ VERIFY: After timeout expires, user is redirected to Login Screen with a message
4. ✅ VERIFY: An auth_event with eventType: "idle_timeout" is logged
5. Reset idleTimeoutMinutes back to 15
```

### 9. Reduce-Motion Accessibility (FR-008, SC-007)

```
1. Enable "Remove animations" in device accessibility settings
2. Open the app → navigate to Login Screen
3. ✅ VERIFY: Bolt icon appears centered but without animation
4. ✅ VERIFY: No visual glitches
```

## Unit Test Verification

```bash
flutter test test/services/auth_service_test.dart
flutter test test/services/auth_audit_service_test.dart
flutter test test/services/session_service_test.dart
flutter test test/services/idle_timeout_service_test.dart
flutter test test/components/password_strength_indicator_test.dart
flutter test test/models/auth_event_model_test.dart
flutter test test/models/device_session_model_test.dart
```

All tests must pass (0 failures) before the feature is considered complete (Constitution Principle XI).

## FR → Test Mapping

| FR | Quickstart Step | Unit Test File |
|----|----------------|----------------|
| FR-001 | Step 1 | auth_service_test.dart |
| FR-002 | Step 2 | auth_service_test.dart |
| FR-003 | Step 1.5 | login_screen_test.dart |
| FR-004 | Step 5.2 | auth_service_test.dart |
| FR-005 | Step 2 | auth_service_test.dart |
| FR-006 | Step 3 | login_screen_test.dart |
| FR-007 | Step 3 | login_screen_test.dart |
| FR-008 | Step 9 | login_screen_test.dart |
| FR-009 | Step 1+2 | auth_service_test.dart |
| FR-010 | Step 1.7 | — (manual verification) |
| FR-011 | Step 8 | idle_timeout_service_test.dart |
| FR-012 | Step 8 | idle_timeout_service_test.dart |
| FR-013 | Step 4 | password_strength_indicator_test.dart |
| FR-014 | Step 4 | password_strength_indicator_test.dart |
| FR-015 | Step 5 | auth_service_test.dart |
| FR-016 | Step 5 | auth_service_test.dart |
| FR-017 | Step 5 | auth_service_test.dart |
| FR-018 | Step 6 | auth_audit_service_test.dart |
| FR-019 | Step 6 | auth_audit_service_test.dart (rule test) |
| FR-020 | Step 7 | session_service_test.dart |
| FR-021 | Step 7 | session_service_test.dart |
| FR-022 | Step 7 | session_service_test.dart |

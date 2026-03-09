# kseb Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-03-08

## Active Technologies
- Dart 3.6.0+ / Flutter 3.27.1 stable + google_fonts 6.2.1, table_calendar 3.1.2, percent_indicator 4.2.3, firebase_core/auth/firestore/storage (002-ui-design-system)
- Firebase Firestore (no schema changes needed — this feature is UI-only) (002-ui-design-system)
- Dart 3.6.0+ / Flutter 3.27.1 stable + Firebase Core/Auth/Firestore (existing), google_fonts (existing). No new packages. (003-splash-smooth-ui)
- N/A (no data model changes) (003-splash-smooth-ui)
- Dart 3.6+ / Flutter (latest stable) + firebase_auth ^6.0.2, cloud_firestore ^6.0.1, firebase_core ^4.1.0 (004-fix-auth-navigation-ui)
- Cloud Firestore (existing collections: users, attendance, teams, etc. — new: auth_events, device_sessions, app_settings) (004-fix-auth-navigation-ui)

- Dart 3.6+ / Flutter (latest stable) + `cloud_firestore ^6.0.1`, `firebase_auth ^6.0.2`, `local_auth ^2.3.0`, `table_calendar ^3.1.2`, `percent_indicator ^4.2.3`, `intl ^0.20.0` (001-refactor-attendance-module)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Dart 3.6+ / Flutter (latest stable)

## Code Style

Dart 3.6+ / Flutter (latest stable): Follow standard conventions

## Recent Changes
- 004-fix-auth-navigation-ui: Added Dart 3.6+ / Flutter (latest stable) + firebase_auth ^6.0.2, cloud_firestore ^6.0.1, firebase_core ^4.1.0
- 003-splash-smooth-ui: Added Dart 3.6.0+ / Flutter 3.27.1 stable + Firebase Core/Auth/Firestore (existing), google_fonts (existing). No new packages.
- 002-ui-design-system: Added Dart 3.6.0+ / Flutter 3.27.1 stable + google_fonts 6.2.1, table_calendar 3.1.2, percent_indicator 4.2.3, firebase_core/auth/firestore/storage


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->

# KSEB App - Kerala State Electricity Board Management System

A comprehensive Flutter application for managing KSEB workforce, attendance, materials, and worksheets with role-based access control.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK (latest stable)
- Firebase project configured
- Android Studio / VS Code with Flutter extensions

### Installation
```bash
flutter pub get
flutter run
```

### First Time Setup
**Important:** Before using the app, you need to set up initial user data in Firebase.

See **[SETUP_GUIDE.md](SETUP_GUIDE.md)** for complete setup instructions.

**Quick Fix for "Staff Management not visible":**
1. Open Firebase Console → Firestore
2. Add your user to `users` collection (see SETUP_GUIDE.md)
3. Set `role: "supervisor"` or higher
4. Create a team and link it
5. Hot reload the app

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Quick reference for common tasks |
| [SETUP_GUIDE.md](SETUP_GUIDE.md) | Step-by-step setup instructions |
| [DATABASE_STRUCTURE.md](DATABASE_STRUCTURE.md) | Complete database schema |
| [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) | Data migration from old structure |
| [UPDATE_SUMMARY.md](UPDATE_SUMMARY.md) | Recent changes and updates |
| [firestore.rules.new](firestore.rules.new) | Security rules to deploy |

## � Design System

The app uses a centralized design-token architecture. All colors, typography, spacing, and decorations are defined once and consumed everywhere via a barrel export.

```dart
import 'package:kseb/utils/design_tokens.dart';
```

| Token file | Contents |
|------------|----------|
| `lib/utils/app_colors.dart` | Primary palette, semantic, status, grey scale, opacity variants |
| `lib/utils/app_typography.dart` | 8 TextStyle presets + font-size constants (Google Fonts Poppins) |
| `lib/utils/app_spacing.dart` | Spacing scale, border radii, elevation shadows |
| `lib/utils/app_decorations.dart` | Card decorations, responsive `BuildContext` extensions |

**Shared widgets** (`lib/components/common/`): `AppButton`, `AppCard`, `AppTextField`, `AppLoading`, `AppEmptyState`, `AppErrorState`, `AppPageWrapper`, `buildAppBar()`.

> **Quickstart guide →** [specs/002-ui-design-system/quickstart.md](specs/002-ui-design-system/quickstart.md) covers token imports, widget usage, responsive helpers, and migration patterns.

## �🏗️ Architecture

### Database Structure (Firestore)
```
├── users (role-based: staff, supervisor, manager, coo, director)
├── teams (hierarchical team structure)
├── attendance (flat attendance tracking)
├── worksheets (work tracking with materials/assets)
├── materials (inventory management)
├── assets (equipment tracking)
├── insurance (staff insurance)
└── bonuses (reward tracking)
```

### Code Structure
```
lib/
├── models/          # Data models
│   ├── user_model.dart
│   ├── team_model.dart
│   └── attendance_model.dart
├── services/        # Business logic
│   ├── user_service.dart
│   ├── team_service.dart
│   └── staff_service.dart
├── screens/         # UI screens
├── components/      # Reusable widgets
│   └── common/      # Design-system widgets (AppButton, AppCard, etc.)
└── utils/           # Utilities & design tokens
    ├── app_colors.dart
    ├── app_typography.dart
    ├── app_spacing.dart
    ├── app_decorations.dart
    └── design_tokens.dart  # Barrel export
```

## 🎯 Features

### Current Features
- ✅ **Role-Based Access Control** - 5 roles: Staff, Supervisor, Manager, COO, Director
- ✅ **Staff Management** - Add, edit, delete staff members (supervisor+)
- ✅ **Team Hierarchy** - Organize staff into teams
- ✅ **Attendance Tracking** - Daily attendance with check-in/out
- ✅ **Worksheet Management** - Create and track work assignments
- ✅ **Material Requests** - Request and track materials

### User Roles

| Role | Permissions |
|------|------------|
| **Staff** | View own data, mark attendance |
| **Supervisor** | Manage team staff, create worksheets, verify attendance |
| **Manager** | Manage all teams, approve worksheets, manage materials |
| **COO** | Organization-wide access, analytics |
| **Director** | Full access including cashbook |

## 🔐 Security

The app uses Firebase Authentication and Firestore Security Rules for role-based access control.

**Deploy Security Rules:**
```bash
firebase deploy --only firestore:rules
```

See [firestore.rules.new](firestore.rules.new) for complete rules.

## 📱 Screens

### Main Screens
- **Worker Home** - Dashboard with quick actions
- **Staff Management** - Manage team members (supervisor+)
- **Attendance** - Mark attendance with biometric/PIN
- **Attendance History** - View attendance records
- **Worksheet** - Create daily worksheets
- **Material Management** - Request materials

## 🛠️ Development

### Running Tests
```bash
flutter test
```

### Building for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
flutter format .
```

## 🔄 Migration

If you have existing data in the old structure (`worker_info`, `staff_details`):

1. **Backup your data** first!
2. Follow [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)
3. Run migration scripts in Firebase Console
4. Verify data integrity
5. Deploy new security rules

## 🐛 Troubleshooting

### Staff Management Not Visible
**Cause:** User doesn't have proper role or teamId  
**Fix:** See [SETUP_GUIDE.md](SETUP_GUIDE.md) - Add user to `users` collection

### Permission Denied
**Cause:** Firestore security rules not deployed  
**Fix:** Deploy `firestore.rules.new` to your Firebase project

### Cannot Add Staff
**Cause:** Duplicate phone/email or invalid teamId  
**Fix:** Ensure phone/email are unique, teamId exists in teams collection

See [QUICK_REFERENCE.md](QUICK_REFERENCE.md) for more troubleshooting tips.

## 📊 Database Models

### UserModel
```dart
UserModel(
  id: String,
  name: String,
  email: String,
  phone: String,
  role: UserRole,  // staff, supervisor, manager, coo, director
  teamId: String?,
  areaCode: String?,
  bonusPoints: int,
  bonusAmount: double,
  ...
)
```

### TeamModel
```dart
TeamModel(
  id: String,
  supervisorId: String,
  managerId: String?,
  areaCode: String,
  members: List<String>,
  assets: List<String>,
  ...
)
```

See [DATABASE_STRUCTURE.md](DATABASE_STRUCTURE.md) for complete schema.

## 🤝 Contributing

1. Follow the existing code structure
2. Use the provided services (UserService, TeamService, etc.)
3. Never query Firestore directly in UI code
4. Check user roles before showing UI elements
5. Write tests for new features

## 📝 License

This project is proprietary software for Kerala State Electricity Board.

## 📞 Support

For setup issues or questions:
1. Check [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
2. Review [SETUP_GUIDE.md](SETUP_GUIDE.md)
3. See [DATABASE_STRUCTURE.md](DATABASE_STRUCTURE.md)

## 🎉 Recent Updates

**Latest:** Database structure updated to role-based, hierarchical system

See [UPDATE_SUMMARY.md](UPDATE_SUMMARY.md) for complete changelog.

---

**Version:** 2.0.0  
**Last Updated:** October 31, 2025  
**Flutter Version:** 3.x  
**Firebase:** Cloud Firestore + Authentication + Storage


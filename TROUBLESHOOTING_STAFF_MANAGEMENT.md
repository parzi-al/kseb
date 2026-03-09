# Troubleshooting: Staff Management Visibility

## Overview
This document helps troubleshoot why the Staff Management option may not be visible for supervisors and above.

## Requirements for Staff Management Visibility

The Staff Management card is visible when **BOTH** conditions are met:
1. `isSupervisor == true` (user role is supervisor, manager, COO, or director)
2. `teamId != null` (user is assigned to a team)

## Code Location
**File**: `lib/screens/worker_home_screen.dart`
**Line**: 616
```dart
if (isSupervisor && teamId != null)
  _buildDashboardCard(
    context,
    icon: Icons.people_rounded,
    label: 'Staff Management',
    ...
  )
```

## How It Works

### 1. Data Fetching (_fetchWorkerData method, line 76)
```dart
// Fetch user from 'users' collection
final userModel = await _userService.getUserByEmail(user.email!);

if (userModel != null) {
  workerId = userModel.id;
  workerName = userModel.name;
  workerRole = userModel.role.displayName;  // Sets role display name
  teamId = userModel.teamId;                 // Sets team ID
  
  // Check if user is supervisor or higher
  isSupervisor = userModel.isSupervisor;     // Uses getter from UserModel
  ...
}
```

### 2. Role Check (UserModel.isSupervisor getter)
**File**: `lib/models/user_model.dart`
**Line**: 142-147
```dart
bool get isSupervisor {
  return role == UserRole.supervisor ||
      role == UserRole.manager ||
      role == UserRole.coo ||
      role == UserRole.director;
}
```

## Debugging Steps

### Step 1: Verify User Document in Firestore
Check your Firestore database:
1. Open Firebase Console → Firestore Database
2. Navigate to `users` collection
3. Find the document with your email
4. Verify the document has:
   - `role` field set to one of: `"supervisor"`, `"manager"`, `"coo"`, or `"director"`
   - `teamId` field is set (not null or empty)

**Example user document:**
```json
{
  "name": "John Supervisor",
  "email": "john@example.com",
  "phone": "+1234567890",
  "role": "supervisor",
  "teamId": "team_001",
  "areaCode": "AREA_01",
  "bonusPoints": 0,
  "bonusAmount": 0,
  "createdAt": "2024-01-15T10:00:00Z"
}
```

### Step 2: Add Debug Logging
Add this code in `_fetchWorkerData()` method after line 90:

```dart
if (userModel != null) {
  workerId = userModel.id;
  workerName = userModel.name;
  workerRole = userModel.role.displayName;
  teamId = userModel.teamId;
  isSupervisor = userModel.isSupervisor;
  
  // DEBUG LOGGING
  print('===== DEBUG: Staff Management Visibility =====');
  print('User Email: ${user.email}');
  print('User Role: ${userModel.role.name}');
  print('Role Display Name: $workerRole');
  print('Team ID: $teamId');
  print('isSupervisor: $isSupervisor');
  print('Should show Staff Management: ${isSupervisor && teamId != null}');
  print('=============================================');
  
  if (userModel.dob != null) {
    workerDob = userModel.dob;
    _checkBirthday();
  }
}
```

### Step 3: Check Console Output
1. Run the app in debug mode
2. Login with the supervisor account
3. Check the debug console for the output
4. Verify the values match your expectations

### Step 4: Common Issues & Solutions

#### Issue 1: Role field is incorrect in Firestore
**Symptom**: `isSupervisor` is false even though user should be supervisor

**Solution**: 
- Ensure the `role` field in Firestore is exactly: `"supervisor"`, `"manager"`, `"coo"`, or `"director"`
- Role values are case-insensitive in code but should be lowercase in Firestore
- No extra spaces or typos

#### Issue 2: teamId is null
**Symptom**: `isSupervisor` is true but card still not visible

**Solution**:
- Ensure the `teamId` field exists in the user document
- The teamId should reference an existing team document in the `teams` collection
- Create a team first if it doesn't exist (see SETUP_GUIDE.md)

#### Issue 3: User document doesn't exist
**Symptom**: Nothing is displayed, or default staff role is shown

**Solution**:
- Create the user document in Firestore `users` collection
- Use the exact email from Firebase Authentication
- See SETUP_GUIDE.md for user creation steps

#### Issue 4: StaffManagementScreen receives wrong teamId
**Symptom**: Staff Management opens but shows no staff or errors

**Note**: The card currently passes `teamId` as `supervisorId` parameter (line 624)
```dart
StaffManagementScreen(
  supervisorId: teamId!,
)
```

**Verification**: 
- The `teamId` should match the team's supervisor's ID in the team document
- If you're a supervisor, your `teamId` should match a team where you are the supervisor

## Quick Test Checklist

- [ ] User document exists in `users` collection
- [ ] Email matches Firebase Auth email exactly
- [ ] Role field is set to supervisor/manager/coo/director
- [ ] TeamId field is not null
- [ ] Team document exists in `teams` collection with matching ID
- [ ] App rebuilt after database changes
- [ ] User logged out and back in after changes

## Example Firebase Setup

### 1. Create Team Document
**Collection**: `teams`
**Document ID**: `team_001`
```json
{
  "name": "Field Team 1",
  "supervisorId": "user_supervisor_001",
  "managerId": "user_manager_001",
  "members": ["user_supervisor_001", "user_staff_001", "user_staff_002"],
  "assets": [],
  "createdAt": "2024-01-15T10:00:00Z"
}
```

### 2. Create Supervisor User Document
**Collection**: `users`
**Document ID**: `user_supervisor_001`
```json
{
  "name": "John Supervisor",
  "email": "supervisor@kseb.com",
  "phone": "+919876543210",
  "role": "supervisor",
  "teamId": "team_001",
  "areaCode": "AREA_01",
  "bonusPoints": 0,
  "bonusAmount": 0,
  "createdAt": "2024-01-15T10:00:00Z"
}
```

### 3. Create Staff User Documents
**Collection**: `users`
**Document ID**: `user_staff_001`
```json
{
  "name": "Staff Member 1",
  "email": "staff1@kseb.com",
  "phone": "+919876543211",
  "role": "staff",
  "teamId": "team_001",
  "areaCode": "AREA_01",
  "bonusPoints": 0,
  "bonusAmount": 0,
  "createdAt": "2024-01-15T10:00:00Z"
}
```

## Still Not Working?

If you've verified all the above and it's still not working:

1. Check for any error messages in the console
2. Verify Firebase connection is working (try other features)
3. Clear app data and reinstall
4. Check Firestore security rules allow reading from `users` collection
5. Verify the user has been granted read access to the `teams` collection

## Security Rules Check

Ensure your `firestore.rules` allows reading users and teams:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /teams/{teamId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Contact Support
If issues persist after following all steps, provide:
- Debug console output
- Screenshot of user document in Firestore
- Screenshot of team document in Firestore
- App version and platform (Android/iOS)

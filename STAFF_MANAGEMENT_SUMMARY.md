# Staff Management Implementation - Summary

## What Has Been Implemented

### 1. Role-Based Staff Visibility

**Manager, COO, Director:**
- Can see **ALL staff** in the entire organization
- Not limited to any specific team

**Supervisor:**
- Can only see staff in **their assigned team**
- Requires `teamId` to be set

### 2. Add Staff Dialog

**Location:** `lib/components/staff/add_staff_dialog.dart`

**Features:**
- ✅ Full name (required)
- ✅ Email (required, must be unique)
- ✅ Phone number (required, must be unique)
- ✅ Team selection dropdown (optional - can be "No Team")
- ✅ Area code (optional)
- ✅ Auto-loads available teams from Firestore
- ✅ Checks for duplicate emails and phone numbers
- ✅ Creates user document with role="staff"

**Note:** This creates a USER PROFILE only. You need to manually create the Firebase Authentication account via Firebase Console.

### 3. Updated Files

#### `lib/screens/staff_management_screen.dart`
- Now accepts `teamId` (optional) and `currentUserRole` (required)
- Shows all staff for manager+ roles
- Shows only team staff for supervisor role

#### `lib/screens/worker_home_screen.dart`
- Passes both `teamId` and `currentUserRole` to StaffManagementScreen
- Staff Management card still requires:
  - `isSupervisor == true` (supervisor or above)
  - `teamId != null` (assigned to a team)

#### `lib/services/staff_service.dart`
- Added `getAllStaffStream()` method for manager+ roles
- Existing `getStaffStream(teamId)` for supervisor role

## How It Works

###Step 1: Login
When you login, the app:
1. Fetches your user document from `users` collection
2. Sets `workerRole` (Manager, Supervisor, etc.)
3. Sets `isSupervisor` flag (true for supervisor+)
4. Sets `teamId` (your assigned team)

### Step 2: Staff Management Visibility
The Staff Management card appears when:
- You are supervisor or above (`isSupervisor == true`)
- AND you have a team assigned (`teamId != null`)

### Step 3: View Staff
When you click Staff Management:
- **Manager/COO/Director**: See all staff in the company
- **Supervisor**: See only staff in your team

### Step 4: Add New Staff
When you click "Add Staff":
1. Dialog shows with form fields
2. Team dropdown loads from Firebase `teams` collection
3. You can select a team or leave as "No Team"
4. Creates user document in `users` collection
5. **IMPORTANT:** Manually create Firebase Auth account after

## Firebase Database Setup

### Required Collections

#### 1. `teams` Collection
```json
{
  "name": "Field Team 1",
  "supervisorId": "user_id_here",
  "managerId": "user_id_here",
  "members": ["user_id_1", "user_id_2"],
  "assets": [],
  "createdAt": <timestamp>
}
```

#### 2. `users` Collection

**Manager Example:**
```json
{
  "name": "Rohit George",
  "email": "xrg@simplewebsite.in",
  "phone": "+919876543210",
  "role": "manager",
  "teamId": "team_001",     ← MUST BE SET
  "areaCode": "AREA_01",
  "bonusPoints": 0,
  "bonusAmount": 0.0,
  "createdAt": <timestamp>
}
```

**Supervisor Example:**
```json
{
  "name": "John Supervisor",
  "email": "supervisor@example.com",
  "phone": "+919876543211",
  "role": "supervisor",
  "teamId": "team_001",     ← MUST BE SET
  "areaCode": "AREA_01",
  "bonusPoints": 0,
  "bonusAmount": 0.0,
  "createdAt": <timestamp>
}
```

**Staff Example:**
```json
{
  "name": "Staff Member",
  "email": "staff@example.com",
  "phone": "+919876543212",
  "role": "staff",
  "teamId": "team_001",     ← Can be null
  "areaCode": "AREA_01",
  "bonusPoints": 0,
  "bonusAmount": 0.0,
  "createdAt": <timestamp>
}
```

## How to Add Your First Team

### Via Firebase Console:

1. Go to Firebase Console → Firestore Database
2. Create `teams` collection if it doesn't exist
3. Add a document with ID `team_001`:
   ```
   name: "Main Team"
   supervisorId: "bOZf6PSiyBOdjMEaSbriG6EDWhT2"  ← Your user ID
   managerId: "bOZf6PSiyBOdjMEaSbriG6EDWhT2"     ← Your user ID
   members: ["bOZf6PSiyBOdjMEaSbriG6EDWhT2"]     ← Array with your ID
   assets: []                                     ← Empty array
   createdAt: (current timestamp)
   ```

4. Update your user document:
   - Add field `teamId` = `"team_001"`

5. Logout and login again

## How to Add Staff Members

### Method 1: Via App (Recommended)

1. Login as manager/supervisor
2. Click "Staff Management"
3. Click "+ Add Staff" button
4. Fill in the form:
   - Name: Full name
   - Email: Must be unique
   - Phone: Must be unique
   - Team: Select from dropdown or "No Team"
   - Area Code: Optional
5. Click "Add Staff"
6. **IMPORTANT:** Go to Firebase Console → Authentication
7. Click "Add User"
8. Use the SAME email you just entered
9. Set a password
10. Staff can now login!

### Method 2: Via Firebase Console

1. Create user in Firebase Authentication first
2. Get the UID
3. Create document in `users` collection with that UID as document ID
4. Add all required fields (name, email, phone, role, etc.)

## Troubleshooting

### "Staff Management not visible"

**Check:**
1. Your role is supervisor/manager/coo/director
2. Your `teamId` is not null
3. You've logged out and back in after database changes

**Debug output should show:**
```
User Role (enum): manager
Team ID: team_001
isSupervisor: true
Should show Staff Management: true
```

### "No staff showing in the list"

**For Supervisors:**
- Make sure staff have the same `teamId` as you
- Staff must have `role: "staff"`

**For Managers:**
- Check that staff exist in `users` collection
- Staff must have `role: "staff"`

### "Can't add staff - email/phone already exists"

- Each email and phone must be unique across ALL users
- Check Firebase Console for duplicates
- Delete duplicate entries if needed

## Next Steps

1. **Remove debug logging:** Once everything works, remove the debug print statements from `worker_home_screen.dart`

2. **Set up Firebase Auth for staff:** After adding staff via the app, create their Firebase Auth accounts manually

3. **Consider Firebase Functions:** For production, use Firebase Cloud Functions to create Auth users automatically (requires backend code)

4. **Add role field to edit:** Currently you can't change a user's role after creation. Consider adding this feature.

5. **Team management screen:** Create a screen to manage teams (add/edit/delete)

## Important Notes

⚠️ **Security:** Make sure your Firestore rules allow:
- Authenticated users to read `users` and `teams` collections
- Only managers+ to write to `users` collection
- Proper role-based access control

⚠️ **Authentication:** The current implementation doesn't create Firebase Auth users automatically to avoid logging you out. You must create Auth accounts manually.

⚠️ **Team Assignment:** Staff can be added without a team (teamId = null). They won't show up in supervisor views, only in manager+ views.

## Files Modified

```
lib/
├── models/
│   └── user_model.dart (already existed)
├── services/
│   ├── staff_service.dart (updated - added getAllStaffStream)
│   └── user_service.dart (already existed)
├── screens/
│   ├── worker_home_screen.dart (updated - passes role to staff screen)
│   └── staff_management_screen.dart (updated - role-based filtering)
└── components/
    └── staff/
        └── add_staff_dialog.dart (completely rewritten)
```

## Summary

You now have a complete staff management system where:
- **Managers see all staff** and can add staff to any team
- **Supervisors see only their team** and can add staff to their team
- **Team dropdown** shows all available teams or "No Team" option
- **Email and phone validation** prevents duplicates
- **Clean UI** with all necessary fields

Just remember to **create Firebase Auth accounts** manually for each staff member after adding them via the app!

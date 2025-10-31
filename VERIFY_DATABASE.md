# Database Verification Guide

## Issue: Staff Management not visible for Manager/Supervisor

### Quick Checklist

Run through these steps to verify your database is set up correctly:

#### 1. Check Firebase Console

Go to: Firebase Console → Firestore Database → `users` collection

#### 2. Find Your User Documents

Look for documents with these emails:
- Manager account email
- Supervisor account email
- COO account email

#### 3. Verify Each User Document Structure

Each user document should look like this:

**Manager Example:**
```json
{
  "name": "Manager Name",
  "email": "manager@kseb.com",
  "phone": "+919876543210",
  "role": "manager",           ← MUST be exactly "manager" (lowercase)
  "teamId": "team_001",         ← MUST NOT be null or empty
  "areaCode": "AREA_01",
  "bonusPoints": 0,
  "bonusAmount": 0,
  "createdAt": <timestamp>
}
```

**Supervisor Example:**
```json
{
  "name": "Supervisor Name",
  "email": "supervisor@kseb.com",
  "phone": "+919876543211",
  "role": "supervisor",         ← MUST be exactly "supervisor" (lowercase)
  "teamId": "team_001",         ← MUST NOT be null or empty
  "areaCode": "AREA_01",
  "bonusPoints": 0,
  "bonusAmount": 0,
  "createdAt": <timestamp>
}
```

**COO Example:**
```json
{
  "name": "COO Name",
  "email": "coo@kseb.com",
  "phone": "+919876543212",
  "role": "coo",                ← MUST be exactly "coo" (lowercase)
  "teamId": "team_001",         ← MUST NOT be null or empty
  "areaCode": "AREA_01",
  "bonusPoints": 0,
  "bonusAmount": 0,
  "createdAt": <timestamp>
}
```

#### 4. Common Mistakes to Avoid

❌ **Wrong role values:**
- "Manager" (capitalized) - should be "manager"
- "MANAGER" (all caps) - should be "manager"
- "Supervisor" - should be "supervisor"
- "COO" (all caps is OK) but "coo" is preferred

❌ **Missing teamId:**
- `teamId: null` - won't work
- Missing teamId field - won't work
- Empty string `teamId: ""` - won't work

❌ **Wrong email:**
- Email in Firestore must EXACTLY match Firebase Auth email
- Check for spaces, case sensitivity

#### 5. Create Team Document

You also need a team document in the `teams` collection:

**Collection:** `teams`
**Document ID:** `team_001` (or whatever you used in teamId)

```json
{
  "name": "Field Team 1",
  "supervisorId": "user_supervisor_001",    ← User document ID of supervisor
  "managerId": "user_manager_001",          ← User document ID of manager
  "members": [
    "user_manager_001",
    "user_supervisor_001",
    "user_staff_001"
  ],
  "assets": [],
  "createdAt": <timestamp>
}
```

#### 6. How to Create These Documents

**Option A: Using Firebase Console**

1. Open Firebase Console
2. Go to Firestore Database
3. Click "Start collection" (if `users` doesn't exist)
4. Collection ID: `users`
5. Add document with auto-generated ID or custom ID
6. Add each field manually

**Option B: Using Firestore Rules temporarily (easier)**

Temporarily update your `firestore.rules` to allow writes:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;  // ⚠️ TEMPORARY - REMOVE AFTER SETUP
    }
  }
}
```

Then create a test script in your app to add users.

**DON'T FORGET** to revert to secure rules after!

#### 7. Test Debug Output

After running the app, you should see output like this in the console:

```
═══════════════════════════════════════════════════════
DEBUG: Staff Management Visibility Check
User Email: manager@kseb.com
User ID: abc123xyz
User Name: Manager Name
User Role (enum): manager
User Role (display): Manager
Team ID: team_001
isSupervisor: true
Should show Staff Management: true
═══════════════════════════════════════════════════════
```

**What to check:**
- ✅ `User Role (enum)` should be: `supervisor`, `manager`, `coo`, or `director`
- ✅ `Team ID` should NOT be `null`
- ✅ `isSupervisor` should be `true`
- ✅ `Should show Staff Management` should be `true`

If any of these are wrong, you need to fix your Firestore data.

#### 8. Quick Firebase Console URL

Direct link format:
```
https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore/data/~2Fusers
```

Replace `YOUR_PROJECT_ID` with your actual Firebase project ID.

## Still Having Issues?

### Issue: "User document doesn't exist"

**Solution:** Create the user document manually in Firebase Console or using a setup script.

### Issue: "teamId is null even though I set it"

**Possible causes:**
1. Field name is wrong (check spelling: `teamId` not `teamid` or `team_id`)
2. Value is actually null in Firestore (not showing in console properly)
3. Firestore rules are blocking reads

**Solution:** 
- Delete and recreate the field
- Check field type is "string"
- Verify Firestore rules allow reading

### Issue: "isSupervisor is false for manager role"

**Possible causes:**
1. Role field has wrong value (check exact spelling and case)
2. Role field doesn't exist
3. Code isn't running (app not rebuilt after changes)

**Solution:**
- Verify role field in Firestore is exactly: `"manager"`, `"supervisor"`, `"coo"`, or `"director"`
- Hot restart the app (not just hot reload)
- Logout and login again

### Issue: "Email mismatch"

**Check:**
1. Firebase Console → Authentication → Users → Find your user → Copy email
2. Firebase Console → Firestore → users collection → Find document → Check email field
3. These MUST match exactly (including case, spaces, etc.)

## Example: Complete Setup for Testing

Here's a minimal working setup:

### 1. Create Manager User
```
Collection: users
Document ID: (auto-generated, e.g., "abc123")

Fields:
name: "Test Manager"
email: "manager@test.com"  ← Must match Firebase Auth
phone: "+919999999999"
role: "manager"
teamId: "team_001"
areaCode: "TEST"
bonusPoints: 0
bonusAmount: 0
createdAt: (timestamp) January 1, 2024 12:00:00
```

### 2. Create Team
```
Collection: teams
Document ID: "team_001"

Fields:
name: "Test Team"
supervisorId: "abc123"  ← The manager's document ID
managerId: "abc123"
members: ["abc123"]
assets: []
createdAt: (timestamp) January 1, 2024 12:00:00
```

### 3. Create Firebase Auth User

If not already created:
1. Firebase Console → Authentication → Users
2. Click "Add user"
3. Email: `manager@test.com` (must match Firestore)
4. Password: (set a test password)

### 4. Test Login

1. Run the app
2. Login with `manager@test.com` and the password
3. Check debug console output
4. Staff Management card should appear

## Need More Help?

Share this information:
1. Debug console output (the boxed section)
2. Screenshot of your user document in Firestore
3. Screenshot of your team document in Firestore
4. Any error messages

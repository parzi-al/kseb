# Quick Setup Guide for New Database Structure

## Important: Initial Setup Required

The new database structure requires some initial setup before the Staff Management option will appear.

## Why Staff Management is Not Visible

The Staff Management option only appears when:
1. ✅ User is logged in with Firebase Authentication
2. ✅ User has a document in the `users` collection
3. ✅ User's role is `supervisor`, `manager`, `coo`, or `director`
4. ✅ User has a `teamId` assigned

**If any of these conditions are not met, the Staff Management card will be hidden.**

## Quick Fix: Add Test User Data

### Option 1: Firebase Console (Recommended)

1. **Open Firebase Console** → Firestore Database
2. **Create a `users` collection** (if it doesn't exist)
3. **Add a document** with your logged-in email:

```json
{
  "name": "Your Name",
  "email": "your-test-email@example.com",  // Must match Firebase Auth email
  "phone": "+919876543210",
  "role": "supervisor",  // Or "manager", "coo", "director"
  "teamId": "team001",   // Create this team (see below)
  "areaCode": "EKM-04",
  "bonusPoints": 0,
  "bonusAmount": 0,
  "createdAt": [current timestamp]
}
```

4. **Create a `teams` collection** and add:

```json
// Document ID: team001
{
  "supervisorId": "user123",  // Your user document ID
  "managerId": null,
  "areaCode": "EKM-04",
  "members": ["user123"],  // Array with your user ID
  "assets": [],
  "createdAt": [current timestamp]
}
```

5. **Hot Reload** the app - the Staff Management option should now appear!

### Option 2: Using Firestore Data Import

Create a JSON file `initial_data.json`:

```json
{
  "users": {
    "user123": {
      "name": "Test Supervisor",
      "email": "test@kseb.in",
      "phone": "+919876543210",
      "role": "supervisor",
      "teamId": "team001",
      "areaCode": "EKM-04",
      "bonusPoints": 0,
      "bonusAmount": 0,
      "createdAt": {"_seconds": 1698739200, "_nanoseconds": 0}
    }
  },
  "teams": {
    "team001": {
      "supervisorId": "user123",
      "managerId": null,
      "areaCode": "EKM-04",
      "members": ["user123"],
      "assets": [],
      "createdAt": {"_seconds": 1698739200, "_nanoseconds": 0}
    }
  }
}
```

Import this in Firebase Console → Firestore → Import/Export.

## Adding Staff Members (After Setup)

Once you have a supervisor user with a team:

1. **Open the app** and navigate to Worker Home
2. **Staff Management card** should now be visible
3. **Tap it** to open Staff Management
4. **Click "+ Add Staff"** button
5. **Fill in the form**:
   - Name: Staff member's full name
   - Phone: Unique phone number
   - Email: Unique email address
   - Role/Position: Optional (e.g., "Electrician")
6. **Click "Add Staff"**

The new staff member will:
- Be created in the `users` collection with `role: "staff"`
- Be automatically assigned to your team (`teamId`)
- Appear in your staff list immediately

## Migrating Existing Data

If you have existing data in the old structure:

1. See `MIGRATION_GUIDE.md` for detailed migration scripts
2. Run migration scripts in Firebase Cloud Functions or locally
3. Verify data integrity before deleting old collections

## Testing Checklist

### Staff Management Visibility
- [ ] Firebase Auth user is logged in
- [ ] User document exists in `users` collection
- [ ] User's email matches Firebase Auth email
- [ ] User's role is supervisor or higher
- [ ] User has a valid `teamId`
- [ ] Team document exists with that `teamId`

### Adding Staff
- [ ] Can open Add Staff dialog
- [ ] Phone number validation works
- [ ] Email validation works
- [ ] Duplicate phone numbers are rejected
- [ ] New staff appears in list immediately
- [ ] New staff has `role: "staff"` and correct `teamId`

### Editing Staff
- [ ] Can open Edit Staff dialog
- [ ] Updates are saved correctly
- [ ] Changes reflect immediately

### Deleting Staff
- [ ] Confirmation dialog appears
- [ ] Staff is removed from Firestore
- [ ] Staff disappears from list immediately

## Common Issues

### "Staff Management not visible"
**Solution:** Check all conditions listed above. Most likely your user doesn't have a `users` collection document or the role is set to `staff`.

### "Error adding staff member"
**Solution:** Check Firestore rules. Ensure you have proper permissions. See `firestore.rules.new` for recommended rules.

### "Network timeout"
**Solution:** Check internet connection and Firestore connection. Verify Firebase is properly initialized in the app.

## Development vs Production

### Development Setup
- Use Firebase emulator suite for local testing
- Test with mock data first
- Don't deploy security rules until thoroughly tested

### Production Deployment
1. Backup all existing data
2. Test migration scripts on staging environment
3. Deploy new security rules (`firestore.rules.new` → `firestore.rules`)
4. Run migration scripts
5. Verify all functionality works
6. Monitor for errors

## Next Steps

After basic setup:
1. ✅ Verify Staff Management works
2. ⏳ Migrate attendance system (see TODO list)
3. ⏳ Implement worksheet enhancements
4. ⏳ Add bonus tracking
5. ⏳ Implement insurance management

## Support

For detailed documentation:
- Database structure: `DATABASE_STRUCTURE.md`
- Migration guide: `MIGRATION_GUIDE.md`
- Security rules: `firestore.rules.new`

For code examples, check:
- `lib/models/` - Data models
- `lib/services/` - Business logic
- `lib/screens/worker_home_screen.dart` - Role-based UI

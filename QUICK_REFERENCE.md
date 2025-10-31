# Quick Reference: KSEB Database Structure

## 🎯 Quick Start (2 Minutes)

### Why is Staff Management Hidden?
You need:
1. A document in `users` collection with your email
2. `role` set to `supervisor` (or `manager`, `coo`, `director`)
3. A `teamId` assigned
4. A matching team document

### Fix Right Now (Firebase Console)
```javascript
// 1. Add to users collection:
{
  "email": "your-email@example.com",  // ← Your Firebase Auth email
  "name": "Your Name",
  "phone": "+919876543210",
  "role": "supervisor",               // ← Must be this or higher
  "teamId": "team001",               // ← Link to team
  "areaCode": "EKM-04",
  "bonusPoints": 0,
  "bonusAmount": 0,
  "createdAt": [NOW]
}

// 2. Add to teams collection (ID: team001):
{
  "supervisorId": "[your-user-doc-id]",
  "managerId": null,
  "areaCode": "EKM-04",
  "members": ["[your-user-doc-id]"],
  "assets": [],
  "createdAt": [NOW]
}
```

**Result:** Hot reload → Staff Management appears! ✅

---

## 📊 Collections at a Glance

| Collection | Purpose | Key Fields |
|------------|---------|------------|
| **users** | All people (staff, supervisors, managers, etc.) | `role`, `teamId`, `email` |
| **teams** | Team hierarchy | `supervisorId`, `members`, `assets` |
| **attendance** | Flat attendance tracking | `userId`, `date`, `timestamp` |
| **worksheets** | Work tracking | `teamId`, `status`, `location` |
| **materials** | Inventory | `name`, `stockAvailable` |
| **assets** | Equipment | `assignedTeam`, `status` |
| **insurance** | Staff insurance | `userId`, `policyNumber` |
| **bonuses** | Rewards | `userId`, `points`, `amount` |

---

## 👥 User Roles

```
Director ────────────────────── Full access + cashbook
   │
   ├── COO ──────────────────── Organization-wide access
   │     │
   │     └── Manager ──────────── All teams + staff management
   │           │
   │           └── Supervisor ──── Own team + staff
   │                 │
   │                 └── Staff ──── Own data only
```

---

## 🔑 Common Queries

### Get Team's Staff
```dart
firestore
  .collection('users')
  .where('teamId', isEqualTo: teamId)
  .where('role', isEqualTo: 'staff')
  .snapshots();
```

### Get User by Email
```dart
final userService = UserService();
final user = await userService.getUserByEmail(email);
```

### Check if User is Supervisor
```dart
if (user.isSupervisor) {
  // Show Staff Management
}
```

---

## 🛠️ Services Available

| Service | Use For |
|---------|---------|
| `UserService` | Get/update users, check roles |
| `TeamService` | Manage teams, add/remove members |
| `StaffService` | Add/edit/delete staff (simplified) |

---

## 🔐 Security Rules (Simplified)

```
Staff:      Read own data only
Supervisor: Read/write own team data
Manager:    Read/write all teams
COO:        Read/write everything except cashbook
Director:   Full access including cashbook
```

---

## 📝 Models Available

```dart
UserModel(id, name, email, role, teamId, ...)
TeamModel(id, supervisorId, members, assets, ...)
AttendanceModel(id, userId, date, timestamp, ...)
```

All have `.fromFirestore()` and `.toMap()` methods.

---

## 🚨 Troubleshooting

### "Staff Management not visible"
✅ Check: User document exists with correct email
✅ Check: `role` is `supervisor` or higher
✅ Check: `teamId` is set
✅ Check: Team document exists

### "Can't add staff"
✅ Check: Phone number is unique
✅ Check: Email is unique
✅ Check: Valid teamId

### "Permission denied"
✅ Check: Firestore rules deployed
✅ Check: User has correct role
✅ Check: Internet connection

---

## 📂 Files to Know

| File | What It Does |
|------|--------------|
| `DATABASE_STRUCTURE.md` | Full schema documentation |
| `MIGRATION_GUIDE.md` | How to migrate old data |
| `SETUP_GUIDE.md` | Detailed setup instructions |
| `firestore.rules.new` | Security rules to deploy |
| `UPDATE_SUMMARY.md` | What changed and why |

---

## 💡 Pro Tips

1. **Always use services**, never query Firestore directly in UI
2. **Check roles in code** using `user.isSupervisor` etc.
3. **Keep teamId in sync** between users and team members array
4. **Set timestamps** for createdAt and lastUpdated
5. **Validate uniqueness** for phone/email before creating users

---

## 🎯 Test Checklist

- [ ] User document created in Firebase
- [ ] Team document created
- [ ] Email matches Firebase Auth
- [ ] Role is supervisor or higher
- [ ] TeamId links to team document
- [ ] App hot reloaded
- [ ] Staff Management card visible
- [ ] Can add staff member
- [ ] Can edit staff member
- [ ] Can delete staff member

---

## 📞 Quick Commands (Dart)

```dart
// Get current user
final user = await UserService().getUserByEmail(email);

// Check if supervisor
if (user?.isSupervisor ?? false) { ... }

// Get team's staff
final staff = await UserService().getUsersByTeamId(teamId);

// Add staff
await StaffService().addStaff(
  name: name,
  phone: phone,
  email: email,
  teamId: teamId,
);
```

---

## 🔄 Migration Status

✅ Models created
✅ Services created
✅ Staff management updated
✅ Documentation complete
⏳ Attendance migration (future)
⏳ Data migration scripts (run when ready)

---

**Need more details?** Check the full documentation files!

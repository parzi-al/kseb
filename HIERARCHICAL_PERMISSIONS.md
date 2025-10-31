# Hierarchical Role-Based Permissions System

## Overview
The KSEB staff management system now implements a hierarchical permission model where each role can manage users at their level and below. This creates a clear chain of command and ensures proper access control.

## Role Hierarchy

```
Director (Level 0)
    ↓
  COO (Level 1)
    ↓
Manager (Level 2)
    ↓
Supervisor (Level 3)
    ↓
  Staff (Level 4)
```

**Lower level number = Higher authority**

## Permission Matrix

| Current User Role | Can View | Can Add | Can Edit | Can Delete | Can Assign Roles |
|------------------|----------|---------|----------|------------|------------------|
| **Director** | Everyone (including self) | Everyone | Everyone (including self) | Everyone (including other directors) | Director, COO, Manager, Supervisor, Staff |
| **COO** | COO and below | COO and below | COO and below | COO and below | COO, Manager, Supervisor, Staff |
| **Manager** | Manager and below | Manager and below | Manager and below | Manager and below | Manager, Supervisor, Staff |
| **Supervisor** | Supervisor and below | Supervisor and below | Supervisor and below | Supervisor and below | Supervisor, Staff |
| **Staff** | None | None | None | None | None |

## Key Principles

### 1. **Hierarchical Management**
- Each role can manage (view, edit, delete) anyone at their level or below
- **Example**: A Manager can manage other Managers, Supervisors, and Staff
- **Example**: A Supervisor can only manage other Supervisors and Staff
- **Example**: A Director can manage everyone, including other Directors

### 2. **Role Assignment**
- Users can only assign roles that are at their level or below
- **Example**: A COO can assign COO, Manager, Supervisor, or Staff roles
- **Example**: A Supervisor can only assign Supervisor or Staff roles
- **Cannot promote above yourself**: A Manager cannot create a COO

### 3. **Self-Management**
- **Directors** can edit their own profile (including changing their own role)
- Other roles can view but cannot edit their own role
- This prevents accidental self-demotion

### 4. **Visibility Rules**
- **Staff**: Cannot access staff management at all
- **Supervisor**: Sees only their team members (based on teamId)
- **Manager/COO/Director**: See all staff across the organization

## Implementation Details

### UserRole Enum Methods

```dart
// Check hierarchy level (0 = highest authority)
int get hierarchyLevel

// Check if this role can manage another role
bool canManage(UserRole otherRole)

// Get all roles this role can assign
List<UserRole> get manageableRoles

// Check if this role is supervisor or higher
bool get isSupervisor
```

### UserModel Methods

```dart
// Check if current user can edit another user
bool canEdit(UserRole otherUserRole)
```

### Usage Examples

#### Checking Edit Permission
```dart
final currentUserRole = UserRole.manager;
final staffRole = UserRole.staff;

if (currentUserRole.canManage(staffRole)) {
  // Manager can edit staff member
  showEditDialog();
}
```

#### Getting Manageable Roles
```dart
final supervisorRole = UserRole.supervisor;
final assignableRoles = supervisorRole.manageableRoles;
// Returns: [UserRole.supervisor, UserRole.staff]
```

#### Filtering Staff List
```dart
final manageableStaff = allStaff.where((doc) {
  final staffRole = UserRole.fromString(doc['role']);
  return currentUserRole.canManage(staffRole);
}).toList();
```

## UI Behavior

### Staff Cards
- **Edit/Delete buttons visible**: Only for staff members the current user can manage
- **Edit/Delete buttons hidden**: For staff members above current user's level
- **Example**: A Supervisor sees edit buttons for Staff but not for Managers

### Staff Form Dialog

#### Role Dropdown
- **Visible**: For Supervisors and above
- **Hidden**: For Staff (they shouldn't be in staff management anyway)
- **Options shown**: Only roles the current user can assign

#### Role Dropdown Examples

**Director viewing form:**
- Can select: Director, COO, Manager, Supervisor, Staff
- Badge shows: "Manageable Roles" in red

**Manager viewing form:**
- Can select: Manager, Supervisor, Staff
- Badge shows: "Manageable Roles" in orange

**Supervisor viewing form:**
- Can select: Supervisor, Staff
- Badge shows: "Manageable Roles" in green

### Info Box Message
The info box at the bottom of the form shows what roles the current user can manage:

- **Director**: "As Director, you can manage: Director, COO, Manager, Supervisor, Staff."
- **COO**: "As COO, you can manage: COO, Manager, Supervisor, Staff."
- **Manager**: "As Manager, you can manage: Manager, Supervisor, Staff."
- **Supervisor**: "As Supervisor, you can manage: Supervisor, Staff."

## Practical Examples

### Example 1: Supervisor Edits Staff
```
Logged in as: Supervisor
Target user: Staff Member

✅ Can view staff card
✅ Can see edit/delete buttons
✅ Can open edit dialog
✅ Can see role dropdown (with options: Supervisor, Staff)
✅ Can change staff to Supervisor
❌ Cannot change to Manager or higher
```

### Example 2: Manager Edits COO
```
Logged in as: Manager
Target user: COO

❌ Cannot see this user in the staff list
(Filtered out because Manager cannot manage COO)
```

### Example 3: Director Edits Another Director
```
Logged in as: Director
Target user: Another Director

✅ Can view director card
✅ Can see edit/delete buttons
✅ Can open edit dialog
✅ Can see role dropdown (all roles)
✅ Can change to any role including Director
✅ Can delete (if needed)
```

### Example 4: COO Creates New Staff
```
Logged in as: COO
Action: Add new staff

✅ Can click "Add Staff" button
✅ Can see staff form dialog
✅ Can see role dropdown
✅ Role options: COO, Manager, Supervisor, Staff
✅ Can create at any of these levels
❌ Cannot create a Director
```

## Database Filtering

### Query Filtering
The system filters at two levels:

1. **Database Query Level** (staff_management_screen.dart)
```dart
final manageableStaff = allStaff.where((doc) {
  final staffRole = UserRole.fromString(staffData['role']);
  return currentUserRole.canManage(staffRole);
}).toList();
```

2. **UI Level** (staff_card.dart)
```dart
final canEditStaff = currentUserRole.canManage(staffRole);

if (canEditStaff) {
  // Show edit/delete buttons
}
```

## Security Considerations

### Frontend Validation
✅ Role dropdowns only show assignable roles
✅ Edit buttons hidden for unmanageable users
✅ Staff list filtered to show only manageable users

### Backend Validation (Recommended)
⚠️ **Important**: This is frontend-only validation. For production:

1. Add Firestore Security Rules:
```javascript
match /users/{userId} {
  allow read: if request.auth != null;
  
  allow update: if request.auth != null && 
    canManageRole(
      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role,
      resource.data.role
    );
}

function canManageRole(managerRole, targetRole) {
  return getRoleLevel(managerRole) <= getRoleLevel(targetRole);
}
```

2. Add Cloud Functions for validation:
```javascript
exports.validateRoleChange = functions.firestore
  .document('users/{userId}')
  .onUpdate((change, context) => {
    // Validate that the user making the change
    // has permission to assign the new role
  });
```

## Testing Checklist

### As Director
- [ ] Can see all users (including other Directors)
- [ ] Can edit any user (including other Directors)
- [ ] Can delete any user
- [ ] Can assign any role (Director, COO, Manager, Supervisor, Staff)
- [ ] Can edit own profile and role

### As COO
- [ ] Can see COO and below (not Directors)
- [ ] Can edit COO, Managers, Supervisors, Staff
- [ ] Can assign roles: COO, Manager, Supervisor, Staff
- [ ] Cannot see Directors in list

### As Manager
- [ ] Can see Managers and below (not COO or Directors)
- [ ] Can edit Managers, Supervisors, Staff
- [ ] Can assign roles: Manager, Supervisor, Staff
- [ ] Cannot see COO or Directors in list

### As Supervisor
- [ ] Can see Supervisors and Staff only
- [ ] Can edit Supervisors and Staff
- [ ] Can assign roles: Supervisor, Staff
- [ ] Can only see team members (filtered by teamId)
- [ ] Cannot see Managers, COO, or Directors

### As Staff
- [ ] Cannot access Staff Management screen
- [ ] No visibility of other users

## Migration Notes

### Breaking Changes
None - this is an enhancement to existing functionality.

### New Features
- ✅ Hierarchical permission checking
- ✅ Filtered staff lists based on role
- ✅ Conditional edit/delete buttons
- ✅ Role-specific dropdown options
- ✅ Clear visual indicators of manageable roles

### Backwards Compatibility
- ✅ All existing code continues to work
- ✅ No database schema changes required
- ✅ No migration scripts needed

## Files Modified

1. **lib/models/user_model.dart**
   - Added `hierarchyLevel` getter
   - Added `canManage()` method
   - Added `manageableRoles` getter
   - Added `isSupervisor` getter to UserRole enum
   - Added `canEdit()` method to UserModel

2. **lib/screens/staff_management_screen.dart**
   - Added role-based filtering in `_buildBody()`
   - Added `canEdit` check in `itemBuilder`
   - Pass `canEdit` flag to StaffCard

3. **lib/components/staff/staff_card.dart**
   - Added `canEdit` parameter
   - Conditionally show/hide edit and delete buttons

4. **lib/components/staff/staff_form_dialog.dart**
   - Changed role dropdown from COO/Director only to Supervisor+
   - Filter role options using `manageableRoles`
   - Updated info box message to show manageable roles
   - Updated role dropdown badge to show "Manageable Roles"

## Future Enhancements

1. **Audit Trail**: Log all role changes with timestamp and who made the change
2. **Bulk Operations**: Allow bulk role assignment for efficiency
3. **Role Templates**: Pre-defined permission sets for common roles
4. **Temporary Promotions**: Time-limited role elevations
5. **Delegation**: Allow temporary delegation of permissions
6. **Role Requests**: Lower-level users can request role changes (approval workflow)
7. **Email Notifications**: Notify users when their role changes
8. **Analytics Dashboard**: Show role distribution and changes over time

## Support

For questions or issues with the hierarchical permissions system:
1. Check this documentation
2. Review the code comments in the modified files
3. Test with different role combinations
4. Ensure Firebase security rules match frontend logic

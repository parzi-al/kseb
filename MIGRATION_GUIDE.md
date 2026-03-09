# KSEB Database Migration Guide

## Overview
This document outlines the migration from the old database structure to the new hierarchical, role-based structure.

## Database Structure Changes

### Old Structure
```
- worker_info (collection)
- staff_details (collection)
- workers/{uid}/attendance (subcollection)
- worksheets (collection)
- materials (collection)
```

### New Structure
```
- users (collection) - All users with role-based access
- teams (collection) - Hierarchical team structure
- attendance (collection) - Flat attendance tracking
- worksheets (collection) - Enhanced with team/location data
- materials (collection) - Master inventory
- assets (collection) - Equipment tracking
- insurance (collection) - Staff insurance
- bonuses (collection) - Bonus tracking
```

## Migration Steps

### 1. Migrate worker_info → users

**Old Schema:**
```json
{
  "name": "string",
  "email": "string",
  "dob": "Timestamp"
}
```

**New Schema:**
```json
{
  "name": "string",
  "email": "string",
  "phone": "string",
  "role": "staff|supervisor|manager|coo|director",
  "teamId": "string",
  "areaCode": "string",
  "photoUrl": "string",
  "insuranceId": "string",
  "bonusPoints": 0,
  "bonusAmount": 0.0,
  "dob": "Timestamp",
  "createdAt": "Timestamp"
}
```

**Migration Script (Run in Firebase Console):**
```javascript
// Firestore console or Cloud Functions
const admin = require('firebase-admin');
const db = admin.firestore();

async function migrateWorkerInfo() {
  const workerInfoSnapshot = await db.collection('worker_info').get();
  
  for (const doc of workerInfoSnapshot.docs) {
    const data = doc.data();
    
    // Create user document
    await db.collection('users').doc(doc.id).set({
      name: data.name || '',
      email: data.email || '',
      phone: data.phone || '',
      role: 'supervisor', // Default role, adjust as needed
      teamId: null, // Assign team later
      areaCode: data.areaCode || null,
      photoUrl: data.photoUrl || null,
      insuranceId: null,
      bonusPoints: 0,
      bonusAmount: 0.0,
      dob: data.dob || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }
  
  console.log('Worker info migration complete');
}
```

### 2. Migrate staff_details → users

**Old Schema:**
```json
{
  "name": "string",
  "phone": "string",
  "email": "string",
  "role": "string",
  "supervisorId": "string",
  "joinDate": "Timestamp"
}
```

**Migration Script:**
```javascript
async function migrateStaffDetails() {
  const staffSnapshot = await db.collection('staff_details').get();
  
  for (const doc of staffSnapshot.docs) {
    const data = doc.data();
    
    // Create user document
    await db.collection('users').doc(doc.id).set({
      name: data.name || '',
      email: data.email || '',
      phone: data.phone || '',
      role: 'staff', // All staff_details are staff role
      teamId: data.supervisorId || null, // Will need team creation first
      areaCode: null,
      photoUrl: null,
      insuranceId: null,
      bonusPoints: 0,
      bonusAmount: 0.0,
      dob: null,
      createdAt: data.joinDate || admin.firestore.FieldValue.serverTimestamp()
    });
  }
  
  console.log('Staff details migration complete');
}
```

### 3. Create Teams

**Before migrating attendance, create teams to establish hierarchy:**

```javascript
async function createTeams() {
  const supervisorsSnapshot = await db.collection('users')
    .where('role', '==', 'supervisor')
    .get();
  
  for (const supervisorDoc of supervisorsSnapshot.docs) {
    const supervisor = supervisorDoc.data();
    
    // Get all staff members under this supervisor
    const staffSnapshot = await db.collection('users')
      .where('teamId', '==', supervisorDoc.id)
      .where('role', '==', 'staff')
      .get();
    
    const memberIds = staffSnapshot.docs.map(doc => doc.id);
    memberIds.push(supervisorDoc.id); // Add supervisor to members
    
    // Create team
    const teamRef = await db.collection('teams').add({
      supervisorId: supervisorDoc.id,
      managerId: null, // Assign later
      areaCode: supervisor.areaCode || 'UNKNOWN',
      members: memberIds,
      assets: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastUpdated: null
    });
    
    // Update all members with the teamId
    const batch = db.batch();
    for (const memberId of memberIds) {
      batch.update(db.collection('users').doc(memberId), {
        teamId: teamRef.id
      });
    }
    await batch.commit();
  }
  
  console.log('Teams created successfully');
}
```

### 4. Migrate Attendance

**Old Schema:**
```
workers/{uid}/attendance/{attendanceId}
{
  "timestamp": "Timestamp"
}
```

**New Schema:**
```
attendance/{attendanceId}
{
  "userId": "string",
  "worksheetId": "string",
  "date": "Timestamp",
  "verifiedBy": "string",
  "status": "present",
  "timestamp": "Timestamp"
}
```

**Migration Script:**
```javascript
async function migrateAttendance() {
  const workersSnapshot = await db.collection('workers').get();
  
  for (const workerDoc of workersSnapshot.docs) {
    const userId = workerDoc.id;
    const attendanceSnapshot = await db.collection('workers')
      .doc(userId)
      .collection('attendance')
      .get();
    
    for (const attendanceDoc of attendanceSnapshot.docs) {
      const data = attendanceDoc.data();
      const timestamp = data.timestamp.toDate();
      
      // Create new attendance document
      await db.collection('attendance').add({
        userId: userId,
        worksheetId: null, // Link to worksheet if available
        date: admin.firestore.Timestamp.fromDate(
          new Date(timestamp.getFullYear(), timestamp.getMonth(), timestamp.getDate())
        ),
        verifiedBy: null,
        status: 'present',
        timestamp: data.timestamp
      });
    }
  }
  
  console.log('Attendance migration complete');
}
```

## Code Changes Required

### 1. Update WorkerHomeScreen
- ✅ Change from `worker_info` to `users` collection
- ✅ Use `UserService` instead of direct Firestore queries
- ✅ Check role instead of hardcoded `isSupervisor = true`
- ✅ Pass `teamId` to StaffManagementScreen

### 2. Update StaffService
- ✅ Change from `staff_details` to `users` collection
- ✅ Filter by `teamId` instead of `supervisorId`
- ✅ Add role filter: `role == 'staff'`

### 3. Update StaffManagementScreen
- ✅ Accept `teamId` (currently named `supervisorId` for compatibility)
- ✅ Use updated `StaffService`

### 4. Update AttendanceScreen
- ⏳ Change from `workers/{uid}/attendance` to `attendance` collection
- ⏳ Add `userId` field to attendance records

### 5. Create New Services
- ✅ UserService - Manage users with role-based queries
- ✅ TeamService - Manage team hierarchy
- ⏳ AttendanceService - Manage flat attendance structure

## Testing Checklist

### Before Migration
1. ✅ Backup all Firestore data
2. ⏳ Test migration scripts on a development/staging database
3. ⏳ Verify all existing users can be mapped to new structure

### After Migration
1. ⏳ Verify user login still works
2. ⏳ Check staff management screen shows correct staff
3. ⏳ Verify attendance tracking works
4. ⏳ Test role-based permissions
5. ⏳ Verify team hierarchy is correct

## Rollback Plan

If migration fails:
1. Keep old collections intact during migration
2. Use feature flags to switch between old/new structure
3. Migration script should only ADD data, not DELETE
4. Test thoroughly before deleting old collections

## Timeline

1. **Phase 1: Models & Services** ✅
   - Create new models (UserModel, TeamModel, AttendanceModel)
   - Create services (UserService, TeamService)
   - Update existing services

2. **Phase 2: Code Updates** ✅ (Partially)
   - Update WorkerHomeScreen
   - Update StaffManagementScreen
   - Update Staff dialogs (Add/Edit/Delete)

3. **Phase 3: Attendance Migration** ⏳
   - Update AttendanceScreen
   - Update AttendanceHistoryScreen
   - Create AttendanceService

4. **Phase 4: Data Migration** ⏳
   - Run migration scripts
   - Verify data integrity
   - Update security rules

5. **Phase 5: Cleanup** ⏳
   - Remove old collections
   - Remove old code paths
   - Final testing

## Security Rules Update
See `firestore.rules.new` for the complete role-based security rules.

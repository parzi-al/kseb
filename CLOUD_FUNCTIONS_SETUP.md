# Firebase Cloud Functions Setup

## Complete User Deletion (Firestore + Auth)

### Problem
Client-side Firebase apps cannot delete other users' Firebase Auth accounts for security reasons. When you call `deleteStaff()` in the app, it only deletes the Firestore user document, not the Firebase Auth account.

### Solution
Use Firebase Cloud Functions with Admin SDK to delete both Firestore and Auth accounts.

## Setup Steps

### 1. Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Initialize Cloud Functions
```bash
cd c:\Users\heyrg\OneDrive\Desktop\kseb
firebase login
firebase init functions
```
Select:
- Choose your Firebase project
- Language: JavaScript or TypeScript
- ESLint: Yes (recommended)
- Install dependencies: Yes

### 3. Create Delete User Function

Edit `functions/index.js` (or `functions/src/index.ts` if TypeScript):

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Deletes a user account from both Firebase Auth and Firestore
 * Can only be called by authenticated users with COO or Director role
 */
exports.deleteUserAccount = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  // Get the caller's role from Firestore
  const callerDoc = await admin.firestore()
    .collection('users')
    .doc(context.auth.uid)
    .get();
  
  const callerRole = callerDoc.data()?.role;
  
  // Only COO and Director can delete users
  if (!['coo', 'director'].includes(callerRole)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Only COO and Director can delete users'
    );
  }

  const { uid } = data;

  if (!uid) {
    throw new functions.https.HttpsError('invalid-argument', 'UID is required');
  }

  try {
    // Get user being deleted to check hierarchy
    const targetDoc = await admin.firestore()
      .collection('users')
      .doc(uid)
      .get();
    
    if (!targetDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const targetRole = targetDoc.data()?.role;

    // Check if caller can manage target user (hierarchy check)
    const hierarchy = {
      director: 0,
      coo: 1,
      manager: 2,
      supervisor: 3,
      staff: 4
    };

    if (hierarchy[callerRole] > hierarchy[targetRole]) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Cannot delete user with higher authority'
      );
    }

    // Delete from Firestore first
    await admin.firestore().collection('users').doc(uid).delete();
    
    // Then delete from Firebase Auth
    await admin.auth().deleteUser(uid);

    return { 
      success: true, 
      message: 'User deleted successfully from both Auth and Firestore',
      deletedUid: uid
    };
  } catch (error) {
    console.error('Error deleting user:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

### 4. Deploy Cloud Function
```bash
firebase deploy --only functions
```

### 5. Update Flutter App

Add Firebase Functions package to `pubspec.yaml`:
```yaml
dependencies:
  cloud_functions: ^4.7.0
```

Update `lib/services/staff_service.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';

class StaffService {
  // ... existing code ...

  /// Deletes a staff member from both Firestore and Firebase Auth
  Future<void> deleteStaff(String staffId) async {
    try {
      // Call Cloud Function to delete from both Auth and Firestore
      final callable = FirebaseFunctions.instance.httpsCallable('deleteUserAccount');
      final result = await callable.call({'uid': staffId});
      
      if (result.data['success'] != true) {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      rethrow;
    }
  }
}
```

## Security Rules

The Cloud Function already includes:
- ✅ Authentication check (must be logged in)
- ✅ Authorization check (must be COO or Director)
- ✅ Hierarchy check (can't delete users with higher authority)
- ✅ User existence check

## Testing

1. Deploy the function
2. In your app, try deleting a staff member as COO
3. Check Firebase Console:
   - Authentication → User should be deleted
   - Firestore → User document should be deleted

## Cost

Firebase Cloud Functions pricing:
- Free tier: 2 million invocations/month
- After free tier: $0.40 per million invocations
- This delete operation is well within free tier for typical usage

## Troubleshooting

### Error: "User must be authenticated"
- Ensure the user calling the function is logged in
- Check that context.auth.uid is being passed correctly

### Error: "Only COO and Director can delete users"
- Verify the caller's role in Firestore
- Check that role field is correctly set

### Error: "Cannot delete user with higher authority"
- Verify role hierarchy in both Cloud Function and Flutter app
- Ensure they match exactly

### Function not found
- Run `firebase deploy --only functions` again
- Check Firebase Console → Functions to see if deployed
- Verify function name matches in Flutter code

## Current Implementation

Currently, the app only deletes from Firestore. The user's Firebase Auth account remains active but they cannot log in because their profile doesn't exist.

**To enable complete deletion:**
1. Follow steps 1-5 above
2. Test with a test user account
3. Once verified, it will delete from both Auth and Firestore

# KSEB Database Structure Documentation

## Overview
The KSEB app uses a hierarchical, role-based database structure in Firebase Firestore. This document describes the complete database schema, collections, and their relationships.

## Collections

### 1. users
Stores all users in the system with role-based access control.

**Document ID:** Auto-generated or UID from Firebase Auth

**Fields:**
```typescript
{
  name: string;              // Full name
  email: string;             // Email address (unique)
  phone: string;             // Phone number (unique)
  role: "staff" | "supervisor" | "manager" | "coo" | "director";
  teamId: string | null;     // Reference to teams collection
  areaCode: string | null;   // Area/section code (e.g., "EKM-04")
  photoUrl: string | null;   // Firebase Storage URL for profile photo
  insuranceId: string | null; // Reference to insurance collection
  bonusPoints: number;       // Accumulated bonus points (default: 0)
  bonusAmount: number;       // Total bonus amount (default: 0.0)
  dob: Timestamp | null;     // Date of birth
  createdAt: Timestamp;      // Account creation timestamp
}
```

**Indexes:**
- `email` (for login queries)
- `phone` (for searching/uniqueness)
- `teamId` (for team member queries)
- `role` (for role-based queries)
- Composite: `teamId + role` (for efficient team staff queries)

**Example:**
```json
{
  "name": "Rohit George",
  "email": "rohit@kseb.in",
  "phone": "+919876543210",
  "role": "supervisor",
  "teamId": "team001",
  "areaCode": "EKM-04",
  "photoUrl": "gs://kseb_app/users/user123_profile.jpg",
  "insuranceId": "ins001",
  "bonusPoints": 150,
  "bonusAmount": 5000,
  "dob": Timestamp(1990-05-15),
  "createdAt": Timestamp(2025-01-01)
}
```

---

### 2. teams
Hierarchical structure connecting supervisors, staff, managers, and teams.

**Document ID:** Auto-generated

**Fields:**
```typescript
{
  supervisorId: string;      // User ID of the team supervisor
  managerId: string | null;  // User ID of the manager overseeing this team
  areaCode: string;          // Area/section code
  members: string[];         // Array of user IDs in this team
  assets: string[];          // Array of asset IDs assigned to this team
  createdAt: Timestamp;      // Team creation timestamp
  lastUpdated: Timestamp | null; // Last modification timestamp
}
```

**Indexes:**
- `supervisorId` (to find teams by supervisor)
- `managerId` (to find teams by manager)
- `areaCode` (to find teams by area)

**Example:**
```json
{
  "supervisorId": "user123",
  "managerId": "user567",
  "areaCode": "EKM-04",
  "members": ["user123", "user456", "user789"],
  "assets": ["asset001", "asset002"],
  "createdAt": Timestamp(2025-01-01),
  "lastUpdated": Timestamp(2025-10-31)
}
```

---

### 3. attendance
Flat attendance tracking for all users.

**Document ID:** Auto-generated

**Fields:**
```typescript
{
  userId: string;            // User ID who attended
  worksheetId: string | null; // Optional link to worksheet
  date: Timestamp;           // Date of attendance (normalized to midnight)
  verifiedBy: string | null; // User ID of supervisor who verified
  status: "present" | "absent" | "leave"; // Attendance status
  timestamp: Timestamp;      // Actual check-in/check-out timestamp
}
```

**Indexes:**
- `userId` (to query user's attendance)
- Composite: `userId + date` (for daily attendance)
- `worksheetId` (to link attendance to work)
- `verifiedBy` (for supervisor verification tracking)

**Example:**
```json
{
  "userId": "user123",
  "worksheetId": "worksheet001",
  "date": Timestamp(2025-10-31T00:00:00),
  "verifiedBy": "supervisor123",
  "status": "present",
  "timestamp": Timestamp(2025-10-31T09:00:00)
}
```

**Note:** For check-in/check-out systems, create two records (one for in, one for out) or use an array of timestamps.

---

### 4. worksheets
Main work tracking documents with office details, materials, geotagging, etc.

**Document ID:** Auto-generated

**Fields:**
```typescript
{
  createdBy: string;         // User ID of creator (supervisor)
  approvedBy: string | null; // User ID of approver (manager)
  teamId: string;            // Team responsible for this work
  areaCode: string;          // Area code where work is performed
  officeName: string;        // KSEB office/section name
  workType: string;          // Type of work (e.g., "Maintenance", "Installation")
  maintenanceCategory: string | null; // Category (e.g., "Calamity Deposit")
  status: "pending" | "approved" | "in-progress" | "completed" | "rejected";
  location: {                // Geolocation of work site
    lat: number;
    lng: number;
    address: string;
  };
  permitBookUrl: string | null; // Firebase Storage URL for permit book PDF
  polvarText: string | null; // Polvar details text
  geotaggedPhotos: string[]; // Array of Firebase Storage URLs
  materialList: Array<{      // Materials used
    materialId: string;
    name: string;
    quantity: number;
    unit: string;
  }>;
  assetList: Array<{         // Assets used
    assetId: string;
    name: string;
    used: boolean;
  }>;
  submittedAt: Timestamp;    // When worksheet was submitted
  lastUpdated: Timestamp;    // Last modification time
}
```

**Indexes:**
- `createdBy` (to query worksheets by creator)
- `teamId` (to query team's worksheets)
- `status` (to filter by status)
- Composite: `teamId + status` (for team's pending/completed work)
- `areaCode` (for area-based queries)

**Example:**
```json
{
  "createdBy": "supervisor123",
  "approvedBy": "manager567",
  "teamId": "team001",
  "areaCode": "EKM-04",
  "officeName": "KSEB Kaloor Section",
  "workType": "Maintenance",
  "maintenanceCategory": "Calamity Deposit",
  "status": "approved",
  "location": {
    "lat": 10.01234,
    "lng": 76.32145,
    "address": "Kaloor Main Road, Ernakulam"
  },
  "permitBookUrl": "gs://kseb_app/permits/worksheet001_permit.pdf",
  "polvarText": "Polvar No. 23, replaced transformer on 31/10/2025",
  "geotaggedPhotos": [
    "gs://kseb_app/geotags/worksheet001_photo1.jpg",
    "gs://kseb_app/geotags/worksheet001_photo2.jpg"
  ],
  "materialList": [
    {
      "materialId": "mat001",
      "name": "Cable Roll",
      "quantity": 3,
      "unit": "coil"
    }
  ],
  "assetList": [
    {
      "assetId": "asset001",
      "name": "Transformer",
      "used": true
    }
  ],
  "submittedAt": Timestamp(2025-10-31T14:00:00),
  "lastUpdated": Timestamp(2025-10-31T15:30:00)
}
```

---

### 5. materials
Master inventory data for material tracking.

**Document ID:** Auto-generated

**Fields:**
```typescript
{
  name: string;              // Material name
  description: string | null; // Detailed description
  unit: string;              // Unit of measurement (e.g., "coil", "pcs", "meter")
  stockAvailable: number;    // Current stock available
  stockUsed: number;         // Total stock used/issued
  category: string | null;   // Material category
  lastUpdated: Timestamp;    // Last stock update time
}
```

**Indexes:**
- `name` (for searching materials)
- `category` (for filtering by category)

**Example:**
```json
{
  "name": "Cable Roll",
  "description": "XLPE 11kV cable, 100m per coil",
  "unit": "coil",
  "stockAvailable": 100,
  "stockUsed": 25,
  "category": "Cables",
  "lastUpdated": Timestamp(2025-10-31)
}
```

---

### 6. assets
Master table for equipment/assets (transformers, poles, meters, etc.).

**Document ID:** Auto-generated

**Fields:**
```typescript
{
  name: string;              // Asset name/type
  serialNumber: string | null; // Serial/ID number
  status: "active" | "under maintenance" | "scrapped" | "reserved";
  assignedTeam: string | null; // Team ID this asset is assigned to
  lastMaintenance: Timestamp | null; // Last maintenance date
  specifications: string | null; // Technical specifications
  purchaseDate: Timestamp | null; // Purchase/installation date
  photos: string[];          // Firebase Storage URLs for asset photos
}
```

**Indexes:**
- `assignedTeam` (to find team's assets)
- `status` (to filter active/inactive assets)
- `serialNumber` (for unique identification)

**Example:**
```json
{
  "name": "Transformer",
  "serialNumber": "T-1234-EKM",
  "status": "active",
  "assignedTeam": "team001",
  "lastMaintenance": Timestamp(2025-09-15),
  "specifications": "11kV/440V, 100kVA",
  "purchaseDate": Timestamp(2020-01-15),
  "photos": ["gs://kseb_app/assets/T-1234-EKM/photo1.jpg"]
}
```

---

### 7. insurance
Staff insurance details.

**Document ID:** Auto-generated

**Fields:**
```typescript
{
  userId: string;            // User ID this insurance belongs to
  company: string;           // Insurance company name
  policyNumber: string;      // Policy number
  validTill: string;         // Expiry date (YYYY-MM-DD format)
  policyDocumentUrl: string | null; // Firebase Storage URL for policy document
  coverageAmount: number | null; // Coverage amount
  createdAt: Timestamp;      // When insurance was added
}
```

**Indexes:**
- `userId` (to find user's insurance)
- `validTill` (to query expiring policies)

**Example:**
```json
{
  "userId": "user123",
  "company": "LIC",
  "policyNumber": "LIC45678",
  "validTill": "2026-12-31",
  "policyDocumentUrl": "gs://kseb_app/insurance/user123_policy.pdf",
  "coverageAmount": 500000,
  "createdAt": Timestamp(2025-01-01)
}
```

---

### 8. bonuses
Bonus and reward tracking.

**Document ID:** Auto-generated

**Fields:**
```typescript
{
  userId: string;            // User ID receiving the bonus
  points: number;            // Bonus points awarded
  amount: number;            // Bonus amount (currency)
  reason: string | null;     // Reason for bonus
  updatedBy: string;         // User ID who granted the bonus (supervisor/manager)
  updatedAt: Timestamp;      // When bonus was granted
}
```

**Indexes:**
- `userId` (to query user's bonuses)
- `updatedBy` (to track who grants bonuses)
- `updatedAt` (for time-based queries)

**Example:**
```json
{
  "userId": "user123",
  "points": 50,
  "amount": 1000,
  "reason": "Excellent performance on transformer installation",
  "updatedBy": "supervisor123",
  "updatedAt": Timestamp(2025-10-31)
}
```

---

### 9. cashbook (Optional - for future implementation)
Overall financial tracking (accessible to director/COO).

**Document ID:** Auto-generated

**Fields:**
```typescript
{
  date: Timestamp;           // Transaction date
  description: string;       // Transaction description
  amount: number;            // Amount
  type: "expense" | "income"; // Transaction type
  category: string | null;   // Category (e.g., "Material Purchase", "Service")
  enteredBy: string;         // User ID who entered this record
  approvedBy: string | null; // User ID who approved (if required)
  attachments: string[];     // Firebase Storage URLs for receipts/documents
  createdAt: Timestamp;      // When record was created
}
```

**Example:**
```json
{
  "date": Timestamp(2025-10-31),
  "description": "Material purchase - cables and insulators",
  "amount": 50000,
  "type": "expense",
  "category": "Material Purchase",
  "enteredBy": "manager123",
  "approvedBy": "director001",
  "attachments": ["gs://kseb_app/cashbook/receipt_20251031.pdf"],
  "createdAt": Timestamp(2025-10-31)
}
```

---

## Firebase Storage Structure

```
/storage
  /users/
      {userId}_profile.jpg
  /permits/
      {worksheetId}_permit.pdf
  /geotags/
      {worksheetId}_photo1.jpg
      {worksheetId}_photo2.jpg
  /insurance/
      {userId}_policy.pdf
  /assets/
      {assetId}/
          photo1.jpg
          photo2.jpg
  /cashbook/
      receipt_{date}.pdf
  /worksheets/
      {worksheetId}/
          additional_doc.pdf
```

---

## Role Hierarchy and Permissions

| Role       | Can Read                          | Can Create/Edit                    | Can Delete             |
|------------|-----------------------------------|-------------------------------------|------------------------|
| **Staff**  | Own data only                     | Own attendance                      | Nothing                |
| **Supervisor** | Team data, staff in team      | Team worksheets, staff, attendance  | Nothing                |
| **Manager** | All teams, all users             | Teams, users, worksheets, assets    | Users, worksheets      |
| **COO**    | Everything except cashbook       | Same as Manager + organization data | Same as Manager        |
| **Director** | Everything including cashbook  | Everything                          | Everything             |

---

## Common Query Patterns

### Get all staff in a team
```dart
final staffStream = firestore
  .collection('users')
  .where('teamId', isEqualTo: teamId)
  .where('role', isEqualTo: 'staff')
  .snapshots();
```

### Get user's attendance for a month
```dart
final monthStart = DateTime(year, month, 1);
final monthEnd = DateTime(year, month + 1, 1);

final attendance = await firestore
  .collection('attendance')
  .where('userId', isEqualTo: userId)
  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
  .where('date', isLessThan: Timestamp.fromDate(monthEnd))
  .get();
```

### Get pending worksheets for a team
```dart
final worksheets = firestore
  .collection('worksheets')
  .where('teamId', isEqualTo: teamId)
  .where('status', isEqualTo: 'pending')
  .snapshots();
```

---

## Migration from Old Structure

See `MIGRATION_GUIDE.md` for detailed migration instructions from the old database structure.

---

## Security

See `firestore.rules.new` for complete Firestore security rules implementing role-based access control.

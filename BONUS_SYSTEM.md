# Bonus System Documentation

## Overview
The bonus system tracks bonus points and amounts for employees with full transaction history.

## Database Structure

### 1. `users` Collection
Stores running totals for each user:
```
users/{userId}
├── bonusPoints: int (running total)
├── bonusAmount: double (running total)
└── ... (other user fields)
```

### 2. `bonuses` Collection
Stores individual transactions (history):
```
bonuses/{transactionId}
├── userId: string (employee who received bonus)
├── points: int (positive for add, negative for remove)
├── amount: double (positive for add, negative for remove)
├── updatedBy: string (userId of COO/Director who made change)
└── updatedAt: timestamp
```

## How It Works

### Adding Bonus
1. COO/Director enters bonus points and/or amount
2. System updates `users/{userId}` with new totals (addition)
3. System creates record in `bonuses` collection with positive values
4. Example: Adding 100 points creates `{points: 100, amount: 0}`

### Removing Bonus
1. COO/Director enters bonus points and/or amount to remove
2. System updates `users/{userId}` with new totals (subtraction, clamped to 0)
3. System creates record in `bonuses` collection with negative values
4. Example: Removing 50 points creates `{points: -50, amount: 0}`

## Features

### Bonus Management Screen (COO/Director Only)
- **Access**: Only visible to COO and Director roles
- **Features**:
  - Select team and employee
  - Choose action: Add or Remove
  - Enter bonus points (optional)
  - Enter bonus amount (optional)
  - At least one field (points or amount) must be filled
  - Tracks who made the change (`updatedBy` field)

### Bonus History Screen
- **COO/Director**: Can view any employee's bonus history via dropdown
- **Regular Users**: Automatically shows their own bonus history only
- **Features**:
  - Lists all transactions in reverse chronological order
  - Shows add/remove badge with color coding
  - Displays points and/or amount changes
  - Shows who made the change and when
  - Real-time updates via Firestore streams

### Home Screen Display
- **All Users**: Can see their own bonus points and amount on home screen
- **Data Source**: Reads from `users/{userId}` collection (running totals)
- **Icons**: Star icon for points, Rupee icon for amount

## Access Control

### Role-Based Permissions
- **Staff/Supervisor**: 
  - Can view own bonus totals on home screen
  - Can view own bonus history
  - Cannot access bonus management
  
- **COO/Director**:
  - Can view own bonus totals on home screen
  - Can add/remove bonuses for any employee
  - Can view any employee's bonus history
  - Full access to bonus management

## Technical Implementation

### Avoiding Composite Index
The bonus history query uses `.where('userId', isEqualTo: userId)` without `.orderBy()` to avoid requiring a Firestore composite index. Sorting is done in the app code instead:

```dart
// Fetch with simple filter
.where('userId', isEqualTo: _selectedUserId)

// Sort in app code
bonuses.sort((a, b) {
  final aTime = (aData['updatedAt'] as Timestamp?)?.toDate();
  final bTime = (bData['updatedAt'] as Timestamp?)?.toDate();
  return bTime.compareTo(aTime); // Newest first
});
```

### Data Consistency
- Both `users` totals and `bonuses` records are updated in the same operation
- If one fails, the whole transaction should be wrapped in error handling
- Running totals in `users` make home screen queries fast
- Transaction history in `bonuses` provides audit trail

## Future Enhancements
- Add batch operations for multiple employees
- Export bonus history to CSV/Excel
- Add date range filters for history
- Add bonus categories/reasons
- Add approval workflow for large bonuses
- Add notifications when bonuses are updated

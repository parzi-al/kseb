import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service for managing users in the new database structure
class UserService {
  static const String _usersCollection = 'users';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user by email
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return UserModel.fromFirestore(querySnapshot.docs.first);
    } catch (e) {
      print('Error getting user by email: $e');
      return null;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      
      if (!doc.exists) {
        return null;
      }

      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  /// Get users by team ID
  Stream<List<UserModel>> getUsersByTeamId(String teamId) {
    return _firestore
        .collection(_usersCollection)
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  /// Get users by role
  Stream<List<UserModel>> getUsersByRole(UserRole role) {
    return _firestore
        .collection(_usersCollection)
        .where('role', isEqualTo: role.name)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  /// Get all staff members in a team (role = staff)
  Stream<List<UserModel>> getStaffByTeamId(String teamId) {
    return _firestore
        .collection(_usersCollection)
        .where('teamId', isEqualTo: teamId)
        .where('role', isEqualTo: 'staff')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  /// Create a new user
  Future<String> createUser(UserModel user) async {
    try {
      final docRef = await _firestore.collection(_usersCollection).add(user.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  /// Update an existing user
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update(updates);
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  /// Update user's full data
  Future<void> updateUserModel(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .update(user.toMap());
    } catch (e) {
      print('Error updating user model: $e');
      rethrow;
    }
  }

  /// Delete a user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  /// Search users by phone number
  Future<List<UserModel>> searchUsersByPhone(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('phone', isEqualTo: phoneNumber)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error searching users by phone: $e');
      return [];
    }
  }

  /// Get users by area code
  Stream<List<UserModel>> getUsersByAreaCode(String areaCode) {
    return _firestore
        .collection(_usersCollection)
        .where('areaCode', isEqualTo: areaCode)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  /// Update user bonus
  Future<void> updateUserBonus({
    required String userId,
    required int points,
    required double amount,
  }) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'bonusPoints': FieldValue.increment(points),
        'bonusAmount': FieldValue.increment(amount),
      });
    } catch (e) {
      print('Error updating user bonus: $e');
      rethrow;
    }
  }
}

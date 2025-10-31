import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Service for managing staff members (users with role='staff')
/// Works with the new 'users' collection and team-based hierarchy
class StaffService {
  static const String _usersCollection = 'users';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get staff stream for a specific team
  Stream<QuerySnapshot> getStaffStream(String teamId) {
    return _firestore
        .collection(_usersCollection)
        .where('teamId', isEqualTo: teamId)
        .where('role', isEqualTo: 'staff')
        .snapshots();
  }

  /// Get all staff stream (for managers and above)
  Stream<QuerySnapshot> getAllStaffStream() {
    return _firestore
        .collection(_usersCollection)
        .where('role', isEqualTo: 'staff')
        .snapshots();
  }

  /// Get all staff for a supervisor (by teamId)
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

  /// Add a new staff member
  Future<String> addStaff({
    required String name,
    required String phone,
    required String email,
    required String teamId,
    String? areaCode,
    String? position,
  }) async {
    final userMap = {
      'name': name,
      'phone': phone,
      'email': email,
      'role': 'staff',
      'teamId': teamId,
      'areaCode': areaCode,
      'bonusPoints': 0,
      'bonusAmount': 0.0,
      'createdAt': Timestamp.now(),
    };

    final docRef = await _firestore.collection(_usersCollection).add(userMap);
    return docRef.id;
  }

  /// Update an existing staff member
  Future<void> updateStaff({
    required String staffId,
    required String name,
    required String email,
    required String phone,
    String? areaCode,
  }) async {
    await _firestore.collection(_usersCollection).doc(staffId).update({
      'name': name,
      'email': email,
      'phone': phone,
      if (areaCode != null) 'areaCode': areaCode,
    });
  }

  /// Delete a staff member
  Future<void> deleteStaff(String staffId) async {
    await _firestore.collection(_usersCollection).doc(staffId).delete();
  }

  /// Search for staff by phone number
  Future<List<UserModel>> searchStaffByPhone(String phoneNumber) async {
    final querySnapshot = await _firestore
        .collection(_usersCollection)
        .where('phone', isEqualTo: phoneNumber)
        .where('role', isEqualTo: 'staff')
        .get();

    return querySnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  /// Get staff member by ID
  Future<UserModel?> getStaffById(String staffId) async {
    final doc = await _firestore.collection(_usersCollection).doc(staffId).get();
    
    if (!doc.exists) {
      return null;
    }

    final user = UserModel.fromFirestore(doc);
    if (user.role == UserRole.staff) {
      return user;
    }
    
    return null;
  }

  /// Transfer staff to another team
  Future<void> transferStaffToTeam(String staffId, String newTeamId) async {
    await _firestore.collection(_usersCollection).doc(staffId).update({
      'teamId': newTeamId,
    });
  }
}

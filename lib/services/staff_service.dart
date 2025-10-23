import 'package:cloud_firestore/cloud_firestore.dart';

class StaffService {
  static const String _staffDetailsCollection = 'staff_details';
  static const String _supervisorStaffCollection = 'supervisor-staff';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get staff stream for a specific supervisor
  Stream<QuerySnapshot> getStaffStream(String supervisorId) {
    return _firestore
        .collection(_staffDetailsCollection)
        .where('supervisorId', isEqualTo: supervisorId)
        .snapshots();
  }

  // Add a new staff member
  Future<void> addStaff({
    required String name,
    required String phone,
    required String email,
    required String supervisorId,
    String? role,
  }) async {
    await _firestore.collection(_staffDetailsCollection).add({
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'supervisorId': supervisorId,
      'joinDate': Timestamp.now(),
    });
  }

  // Update an existing staff member
  Future<void> updateStaff({
    required String staffId,
    required String name,
    required String email,
    required String phone,
    String? role,
  }) async {
    await _firestore.collection(_staffDetailsCollection).doc(staffId).update({
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
    });
  }

  // Delete a staff member
  Future<void> deleteStaff(String staffId) async {
    await _firestore.collection(_staffDetailsCollection).doc(staffId).delete();
  }

  // Search for staff by phone number
  Future<QuerySnapshot> searchStaffByPhone(String phoneNumber) async {
    return await _firestore
        .collection(_staffDetailsCollection)
        .where('phone', isEqualTo: phoneNumber)
        .get();
  }

  // Link staff to supervisor (if needed for the supervisor-staff collection)
  Future<void> linkStaffToSupervisor({
    required String supervisorId,
    required String staffId,
    required String phoneNumber,
  }) async {
    await _firestore
        .collection(_supervisorStaffCollection)
        .doc(supervisorId)
        .collection('staff')
        .add({
      'staffId': staffId,
      'phoneNumber': phoneNumber,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'user_service.dart';

enum ApprovalAction {
  addMaterial,
  withdrawMaterial,
  worksheet;

  String get value {
    switch (this) {
      case ApprovalAction.addMaterial:
        return 'add_material';
      case ApprovalAction.withdrawMaterial:
        return 'withdraw_material';
      case ApprovalAction.worksheet:
        return 'worksheet';
    }
  }
}

class ApprovalService {
  ApprovalService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    UserService? userService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _userService = userService ?? UserService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserService _userService;

  Future<UserModel> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser?.email == null) {
      throw Exception('User not logged in.');
    }

    final user = await _userService.getUserByEmail(firebaseUser!.email!);
    if (user == null) {
      throw Exception('User profile not found.');
    }

    return user;
  }

  bool canApprove({
    required UserRole approverRole,
    required UserRole requesterRole,
  }) {
    return approverRole.canApproveRequestFrom(requesterRole);
  }

  Future<DocumentReference<Map<String, dynamic>>> submitRequest({
    required ApprovalAction action,
    required Map<String, dynamic> payload,
  }) async {
    final currentUser = await getCurrentUser();

    return _firestore.collection('material_requests').add({
      ...payload,
      'action': action.value,
      'requestedBy': currentUser.id,
      'requestedByEmail': currentUser.email,
      'requestedByName': currentUser.name,
      'requestedByRole': currentUser.role.name,
      'requestTimestamp': FieldValue.serverTimestamp(),
      'status': 'Pending',
      'approvalStatus': 'Awaiting Approval',
      'approvedBy': null,
      'approvedByRole': null,
      'approvedAt': null,
      'rejectionReason': null,
    });
  }

  Future<void> approveMaterialRequest(String requestId) async {
    final approver = await getCurrentUser();
    final requestRef = _firestore.collection('material_requests').doc(requestId);
    final requestSnapshot = await requestRef.get();

    if (!requestSnapshot.exists) {
      throw Exception('Request not found.');
    }

    final request = requestSnapshot.data()!;
    final requesterRole =
        UserRole.fromString(request['requestedByRole'] ?? 'staff');

    if (!canApprove(
      approverRole: approver.role,
      requesterRole: requesterRole,
    )) {
      throw Exception('Only a higher authority can approve this request.');
    }

    if (request['status'] != 'Pending') {
      throw Exception('This request is already ${request['status']}.');
    }

    final action = request['action'] as String?;
    if (action != ApprovalAction.addMaterial.value &&
        action != ApprovalAction.withdrawMaterial.value) {
      throw Exception('Unsupported or legacy request format.');
    }

    final batch = _firestore.batch();

    if (action == ApprovalAction.addMaterial.value) {
      final rawMaterialData = request['materialData'];
      if (rawMaterialData is! Map) {
        throw Exception('Add-material request is missing material details.');
      }

      final materialData = Map<String, dynamic>.from(rawMaterialData);
      final materialRef = _firestore.collection('materials').doc();

      batch.set(materialRef, {
        ...materialData,
        'approvedRequestId': requestId,
        'addedBy': request['requestedBy'],
        'addedByEmail': request['requestedByEmail'],
        'approvedBy': approver.id,
        'approvedByEmail': approver.email,
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'status': 'Available',
      });
    } else {
      final materialId = request['materialId'] as String?;
      if (materialId == null || materialId.isEmpty) {
        throw Exception('Withdraw request is missing material reference.');
      }

      final materialRef = _firestore.collection('materials').doc(materialId);
      final materialSnapshot = await materialRef.get();
      if (!materialSnapshot.exists) {
        throw Exception('Material not found.');
      }

      final material = materialSnapshot.data()!;
      final currentQuantity = (material['quantity'] ?? 0).toDouble();
      final requestedQuantity = (request['requestedQuantity'] ?? 0).toDouble();

      if (requestedQuantity <= 0) {
        throw Exception('Invalid requested quantity.');
      }
      if (currentQuantity < requestedQuantity) {
        throw Exception('Not enough stock available.');
      }

      batch.update(materialRef, {
        'quantity': currentQuantity - requestedQuantity,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    batch.update(requestRef, {
      'status': 'Approved',
      'approvalStatus': 'Approved',
      'approvedBy': approver.id,
      'approvedByEmail': approver.email,
      'approvedByRole': approver.role.name,
      'approvedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> rejectMaterialRequest(
    String requestId, {
    String? reason,
  }) async {
    final approver = await getCurrentUser();
    final requestRef = _firestore.collection('material_requests').doc(requestId);
    final requestSnapshot = await requestRef.get();

    if (!requestSnapshot.exists) {
      throw Exception('Request not found.');
    }

    final request = requestSnapshot.data()!;
    final requesterRole =
        UserRole.fromString(request['requestedByRole'] ?? 'staff');

    if (!canApprove(
      approverRole: approver.role,
      requesterRole: requesterRole,
    )) {
      throw Exception('Only a higher authority can reject this request.');
    }

    await requestRef.update({
      'status': 'Rejected',
      'approvalStatus': 'Rejected',
      'approvedBy': approver.id,
      'approvedByEmail': approver.email,
      'approvedByRole': approver.role.name,
      'approvedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });
  }
}

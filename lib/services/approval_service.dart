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

  String get _currentAuthUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('User not logged in.');
    }
    return uid;
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
    validateRequestPayload(action: action, payload: payload);

    final currentUser = await getCurrentUser();
    final currentAuthUid = _currentAuthUid;

    return _firestore.collection('material_requests').add({
      ...payload,
      'action': action.value,
      'requestCategory': action == ApprovalAction.worksheet
          ? ApprovalAction.worksheet.value
          : 'material',
      'requestedBy': currentAuthUid,
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

  static void validateRequestPayload({
    required ApprovalAction action,
    required Map<String, dynamic> payload,
  }) {
    switch (action) {
      case ApprovalAction.addMaterial:
        _validateAddMaterialPayload(payload);
        return;
      case ApprovalAction.withdrawMaterial:
        _validateWithdrawMaterialPayload(payload);
        return;
      case ApprovalAction.worksheet:
        throw Exception('Worksheet approval requests are not available yet.');
    }
  }

  static void _validateAddMaterialPayload(Map<String, dynamic> payload) {
    final materialData = payload['materialData'];
    if (materialData is! Map) {
      throw Exception('Material details are required.');
    }
    final normalizedMaterialData = Map<String, dynamic>.from(materialData);

    final requestedQuantity = _positiveNumber(
      payload['requestedQuantity'],
      'Requested quantity',
    );
    final materialQuantity = _positiveNumber(
      normalizedMaterialData['quantity'],
      'Material quantity',
    );

    if (requestedQuantity != materialQuantity) {
      throw Exception('Requested quantity must match material quantity.');
    }

    _requiredString(payload['materialName'], 'Material name');
    _requiredString(payload['materialCode'], 'Material code');
    _requiredString(payload['unit'], 'Unit');
    _requiredString(normalizedMaterialData['materialName'], 'Material name');
    _requiredString(normalizedMaterialData['materialCode'], 'Material code');
    _requiredString(normalizedMaterialData['category'], 'Category');
    _requiredString(normalizedMaterialData['unit'], 'Unit');
    _requiredString(normalizedMaterialData['supplier'], 'Supplier');
    _requiredString(normalizedMaterialData['location'], 'Storage location');

    final unitPrice = normalizedMaterialData['unitPrice'];
    if (unitPrice is! num || unitPrice < 0) {
      throw Exception('Unit price must be a valid positive number.');
    }

    final totalValue = normalizedMaterialData['totalValue'];
    final expectedTotalValue = materialQuantity * unitPrice;
    if (totalValue is! num ||
        (totalValue - expectedTotalValue).abs() > 0.0001) {
      throw Exception('Total value must match quantity and unit price.');
    }
  }

  static void _validateWithdrawMaterialPayload(Map<String, dynamic> payload) {
    _requiredString(payload['materialId'], 'Material reference');
    _requiredString(payload['materialName'], 'Material name');
    _requiredString(payload['unit'], 'Unit');
    _requiredString(payload['projectCode'], 'Project code');
    _requiredString(payload['purpose'], 'Purpose');
    _requiredString(payload['priority'], 'Priority');
    _positiveNumber(payload['requestedQuantity'], 'Requested quantity');

    if (payload['requiredDate'] == null) {
      throw Exception('Required date is required.');
    }
  }

  static String _requiredString(Object? value, String label) {
    if (value is! String || value.trim().isEmpty) {
      throw Exception('$label is required.');
    }
    return value.trim();
  }

  static double _positiveNumber(Object? value, String label) {
    if (value is! num || value <= 0) {
      throw Exception('$label must be greater than zero.');
    }
    return value.toDouble();
  }

  Future<void> approveMaterialRequest(String requestId) async {
    final approver = await getCurrentUser();
    final approverUid = _currentAuthUid;
    final requestRef =
        _firestore.collection('material_requests').doc(requestId);
    final failure =
        await _firestore.runTransaction<String?>((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        return 'Request not found.';
      }

      final request = requestSnapshot.data()!;
      final requesterRole =
          UserRole.fromString(request['requestedByRole'] ?? 'staff');

      if (!canApprove(
        approverRole: approver.role,
        requesterRole: requesterRole,
      )) {
        return 'Only a higher authority can approve this request.';
      }

      if (request['status'] != 'Pending') {
        return 'This request is already ${request['status']}.';
      }

      final action = request['action'] as String?;
      if (action != ApprovalAction.addMaterial.value &&
          action != ApprovalAction.withdrawMaterial.value) {
        return 'Unsupported or legacy request format.';
      }

      if (action == ApprovalAction.addMaterial.value) {
        final rawMaterialData = request['materialData'];
        if (rawMaterialData is! Map) {
          return 'Add-material request is missing material details.';
        }

        final materialData = Map<String, dynamic>.from(rawMaterialData);
        final materialRef = _firestore.collection('materials').doc();

        transaction.set(materialRef, {
          ...materialData,
          'approvedRequestId': requestId,
          'addedBy': request['requestedBy'],
          'addedByEmail': request['requestedByEmail'],
          'approvedBy': approverUid,
          'approvedByEmail': approver.email,
          'timestamp': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'status': 'Available',
        });
      } else {
        final materialId = request['materialId'] as String?;
        if (materialId == null || materialId.isEmpty) {
          return 'Withdraw request is missing material reference.';
        }

        final materialRef = _firestore.collection('materials').doc(materialId);
        final materialSnapshot = await transaction.get(materialRef);
        if (!materialSnapshot.exists) {
          return 'Material not found.';
        }

        final material = materialSnapshot.data()!;
        final currentQuantity = (material['quantity'] ?? 0).toDouble();
        final requestedQuantity =
            (request['requestedQuantity'] ?? 0).toDouble();

        if (requestedQuantity <= 0) {
          return 'Invalid requested quantity.';
        }
        if (currentQuantity < requestedQuantity) {
          return 'Not enough stock available.';
        }

        transaction.update(materialRef, {
          'quantity': currentQuantity - requestedQuantity,
          'lastUpdated': FieldValue.serverTimestamp(),
          'lastApprovedRequestId': requestId,
        });
      }

      transaction.update(requestRef, {
        'status': 'Approved',
        'approvalStatus': 'Approved',
        'approvedBy': approverUid,
        'approvedByEmail': approver.email,
        'approvedByRole': approver.role.name,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      return null;
    });

    if (failure != null) {
      throw Exception(failure);
    }
  }

  Future<void> rejectMaterialRequest(
    String requestId, {
    String? reason,
  }) async {
    final approver = await getCurrentUser();
    final approverUid = _currentAuthUid;
    final requestRef =
        _firestore.collection('material_requests').doc(requestId);
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
      'approvedBy': approverUid,
      'approvedByEmail': approver.email,
      'approvedByRole': approver.role.name,
      'approvedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });
  }
}

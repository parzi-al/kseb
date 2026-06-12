import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/services/approval_service.dart';

void main() {
  group('ApprovalService payload validation', () {
    test('accepts a valid add-material request payload', () {
      expect(
        () => ApprovalService.validateRequestPayload(
          action: ApprovalAction.addMaterial,
          payload: {
            'materialName': 'Cable',
            'materialCode': 'CBL-001',
            'requestedQuantity': 10.0,
            'unit': 'Meters',
            'materialData': {
              'materialName': 'Cable',
              'materialCode': 'CBL-001',
              'category': 'Cables & Wires',
              'quantity': 10.0,
              'unit': 'Meters',
              'unitPrice': 25.0,
              'totalValue': 250.0,
              'supplier': 'Supplier A',
              'location': 'Main Warehouse',
              'description': '',
              'status': 'Available',
            },
          },
        ),
        returnsNormally,
      );
    });

    test('rejects an add-material payload with mismatched quantity', () {
      expect(
        () => ApprovalService.validateRequestPayload(
          action: ApprovalAction.addMaterial,
          payload: {
            'materialName': 'Cable',
            'materialCode': 'CBL-001',
            'requestedQuantity': 10.0,
            'unit': 'Meters',
            'materialData': {
              'materialName': 'Cable',
              'materialCode': 'CBL-001',
              'category': 'Cables & Wires',
              'quantity': 5.0,
              'unit': 'Meters',
              'unitPrice': 25.0,
              'totalValue': 125.0,
              'supplier': 'Supplier A',
              'location': 'Main Warehouse',
              'description': '',
            },
          },
        ),
        throwsException,
      );
    });

    test('accepts a valid withdraw-material request payload', () {
      expect(
        () => ApprovalService.validateRequestPayload(
          action: ApprovalAction.withdrawMaterial,
          payload: {
            'materialId': 'material-1',
            'materialName': 'Cable',
            'requestedQuantity': 2.0,
            'unit': 'Meters',
            'projectCode': 'PRJ-001',
            'purpose': 'Field work',
            'priority': 'High',
            'requiredDate': Timestamp.fromDate(DateTime(2026, 1, 1)),
            'remarks': '',
          },
        ),
        returnsNormally,
      );
    });

    test('rejects a withdraw payload without a material reference', () {
      expect(
        () => ApprovalService.validateRequestPayload(
          action: ApprovalAction.withdrawMaterial,
          payload: {
            'materialId': '',
            'materialName': 'Cable',
            'requestedQuantity': 2.0,
            'unit': 'Meters',
            'projectCode': 'PRJ-001',
            'purpose': 'Field work',
            'priority': 'High',
            'requiredDate': Timestamp.fromDate(DateTime(2026, 1, 1)),
            'remarks': '',
          },
        ),
        throwsException,
      );
    });
  });
}

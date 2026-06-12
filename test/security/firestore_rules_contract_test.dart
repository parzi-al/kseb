import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String rules;

  setUpAll(() {
    rules = File('firestore.rules').readAsStringSync();
  });

  group('Firestore rules approval safeguards', () {
    test('approval updates are only allowed while request is pending', () {
      expect(rules, contains("resource.data.status == 'Pending'"));
    });

    test('withdraw approval must target the same material document', () {
      expect(
        rules,
        contains('isApprovedWithdrawMaterialRequestForMaterial'),
      );
      expect(rules, contains('approval.materialId == materialId'));
    });

    test('withdraw approval cannot reduce material stock below zero', () {
      expect(rules, contains('request.resource.data.quantity >= 0'));
    });

    test('material approval requests require material category marker', () {
      expect(
        rules,
        contains("request.resource.data.requestCategory == 'material'"),
      );
    });
  });
}

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

  group('Firestore rules attendance safeguards', () {
    test('attendance create validates document shape before role checks', () {
      expect(rules, contains('function isValidAttendanceCreate()'));
      expect(rules, contains('isValidAttendanceCreate()'));
      expect(
          rules,
          contains(
              "request.resource.data.status in ['present', 'absent', 'leave']"));
    });

    test('supervisors and above can create team attendance records', () {
      expect(rules, contains('isSupervisorOrAbove()'));
      expect(
        rules,
        contains('request.resource.data.userId == request.auth.uid'),
      );
    });
  });
}

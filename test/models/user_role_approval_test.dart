import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/models/user_model.dart';

void main() {
  group('UserRole approval hierarchy', () {
    test('higher authority can approve lower authority requests', () {
      expect(
        UserRole.manager.canApproveRequestFrom(UserRole.supervisor),
        isTrue,
      );
      expect(
        UserRole.coo.canApproveRequestFrom(UserRole.manager),
        isTrue,
      );
      expect(
        UserRole.director.canApproveRequestFrom(UserRole.coo),
        isTrue,
      );
    });

    test('same or lower authority cannot approve requests', () {
      expect(
        UserRole.supervisor.canApproveRequestFrom(UserRole.supervisor),
        isFalse,
      );
      expect(
        UserRole.supervisor.canApproveRequestFrom(UserRole.manager),
        isFalse,
      );
      expect(
        UserRole.staff.canApproveRequestFrom(UserRole.supervisor),
        isFalse,
      );
    });
  });
}

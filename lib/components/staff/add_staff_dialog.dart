import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'staff_form_dialog.dart';

class AddStaffDialog {
  static void show(
    BuildContext context, {
    String? defaultTeamId,
    required UserRole currentUserRole,
    VoidCallback? onStaffAdded,
  }) {
    StaffFormDialog.show(
      context,
      defaultTeamId: defaultTeamId,
      currentUserRole: currentUserRole,
      onStaffSaved: onStaffAdded,
    );
  }
}

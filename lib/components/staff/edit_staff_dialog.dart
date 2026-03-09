import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'staff_form_dialog.dart';

class EditStaffDialog {
  static void show(
    BuildContext context,
    String staffId,
    Map<String, dynamic> staffData, {
    UserRole? currentUserRole,
    VoidCallback? onStaffUpdated,
  }) {
    StaffFormDialog.show(
      context,
      staffId: staffId,
      staffData: staffData,
      currentUserRole: currentUserRole ?? UserRole.staff,
      onStaffSaved: onStaffUpdated,
    );
  }
}

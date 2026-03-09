import 'package:flutter/material.dart';
import '../../utils/app_toast.dart';
import '../../services/staff_service.dart';

class DeleteStaffDialog extends StatefulWidget {
  final String staffId;
  final VoidCallback? onStaffDeleted;

  const DeleteStaffDialog({
    Key? key,
    required this.staffId,
    this.onStaffDeleted,
  }) : super(key: key);

  static void show(
    BuildContext context,
    String staffId, {
    VoidCallback? onStaffDeleted,
  }) {
    showDialog(
      context: context,
      builder: (context) => DeleteStaffDialog(
        staffId: staffId,
        onStaffDeleted: onStaffDeleted,
      ),
    );
  }

  @override
  State<DeleteStaffDialog> createState() => _DeleteStaffDialogState();
}

class _DeleteStaffDialogState extends State<DeleteStaffDialog> {
  final _staffService = StaffService();
  bool _isLoading = false;

  Future<void> _deleteStaff() async {
    try {
      setState(() => _isLoading = true);

      await _staffService.deleteStaff(widget.staffId);

      if (mounted) {
        Navigator.pop(context);
        widget.onStaffDeleted?.call();
        AppToast.showSuccess(context, 'Staff member deleted successfully');
      }
    } catch (e) {
      AppToast.showError(context, 'Error deleting staff member: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Staff Member'),
      content: const Text('Are you sure you want to delete this staff member?'),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _deleteStaff,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}

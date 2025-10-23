import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_toast.dart';

class EditStaffDialog extends StatefulWidget {
  final String staffId;
  final Map<String, dynamic> staffData;
  final VoidCallback? onStaffUpdated;

  const EditStaffDialog({
    Key? key,
    required this.staffId,
    required this.staffData,
    this.onStaffUpdated,
  }) : super(key: key);

  static void show(
    BuildContext context,
    String staffId,
    Map<String, dynamic> staffData, {
    VoidCallback? onStaffUpdated,
  }) {
    showDialog(
      context: context,
      builder: (context) => EditStaffDialog(
        staffId: staffId,
        staffData: staffData,
        onStaffUpdated: onStaffUpdated,
      ),
    );
  }

  @override
  State<EditStaffDialog> createState() => _EditStaffDialogState();
}

class _EditStaffDialogState extends State<EditStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _roleController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staffData['name']);
    _emailController = TextEditingController(text: widget.staffData['email']);
    _phoneController = TextEditingController(text: widget.staffData['phone']);
    _roleController = TextEditingController(text: widget.staffData['role']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _updateStaff() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      setState(() => _isLoading = true);

      await FirebaseFirestore.instance
          .collection('staff_details')
          .doc(widget.staffId)
          .update({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'role': _roleController.text,
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onStaffUpdated?.call();
        AppToast.showSuccess(context, 'Staff member updated successfully');
      }
    } catch (e) {
      AppToast.showError(context, 'Error updating staff member: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Staff'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Email is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Phone is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Role'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Role is required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateStaff,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}

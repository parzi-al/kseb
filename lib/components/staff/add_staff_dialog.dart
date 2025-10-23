import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_toast.dart';

class AddStaffDialog extends StatefulWidget {
  final String supervisorId;
  final VoidCallback? onStaffAdded;

  const AddStaffDialog({
    Key? key,
    required this.supervisorId,
    this.onStaffAdded,
  }) : super(key: key);

  static void show(BuildContext context, String supervisorId,
      {VoidCallback? onStaffAdded}) {
    showDialog(
      barrierColor: Colors.black.withValues(alpha: 0.5),
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AddStaffDialog(
          supervisorId: supervisorId,
          onStaffAdded: onStaffAdded,
        ),
      ),
    );
  }

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _roleController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _addStaff() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      final phoneNumber = _phoneController.text.trim();
      final emailAddress = _emailController.text.trim();
      print(
          'Creating new staff member with phone: $phoneNumber, email: $emailAddress');

      // Check if staff with this phone number already exists
      final existingStaffByPhone = await _firestore
          .collection('staff_details')
          .where('phone', isEqualTo: phoneNumber)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet.');
        },
      );

      if (existingStaffByPhone.docs.isNotEmpty) {
        // Phone number already exists
        if (mounted) {
          setState(() => _isLoading = false);
          AppToast.showError(context,
              'A staff member with phone number $phoneNumber already exists!');
        }
        return;
      }

      // Check if staff with this email already exists
      final existingStaffByEmail = await _firestore
          .collection('staff_details')
          .where('email', isEqualTo: emailAddress)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet.');
        },
      );

      if (existingStaffByEmail.docs.isNotEmpty) {
        // Email already exists
        if (mounted) {
          setState(() => _isLoading = false);
          AppToast.showError(context,
              'A staff member with email $emailAddress already exists!');
        }
        return;
      }

      print('Phone and email are unique, proceeding with staff creation');
      print(
          'Data: ${_nameController.text.trim()}, $phoneNumber, $emailAddress');

      await _firestore.collection('staff_details').add({
        'name': _nameController.text.trim(),
        'phone': phoneNumber,
        'email': emailAddress,
        'role': _roleController.text.trim(),
        'supervisorId': widget.supervisorId,
        'joinDate': Timestamp.now(),
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Operation timed out. Please check your connection.');
        },
      );

      print('Staff added successfully to Firebase');

      // Always close dialog first to prevent hanging
      try {
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error closing dialog: $e');
      }

      // Then show success message and call callback
      try {
        if (mounted) {
          widget.onStaffAdded?.call();

          // Use a brief delay to ensure the dialog is closed before showing snackbar
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              try {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Staff added successfully'),
                      ],
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                print('Error showing snackbar: $e');
              }
            }
          });
        }
      } catch (e) {
        print('Error in callback: $e');
      }
    } catch (e) {
      print('Error adding staff: $e');
      if (mounted) {
        AppToast.showError(context, 'Error adding staff member: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      elevation: 0,
      title: _buildTitle(),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      content: _buildContent(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: _buildActions(),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_add_rounded,
            color: AppColors.primary,
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text('Add New Staff'),
      ],
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Staff Name *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                helperText: 'Must be unique - no duplicates allowed',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Phone number is required';
                }
                // Basic phone number validation
                final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
                if (!phoneRegex.hasMatch(value!.trim())) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                helperText: 'Must be unique and valid format',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Email is required';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value!)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Role/Position',
                prefixIcon: Icon(Icons.work_outline),
                border: OutlineInputBorder(),
                helperText: 'Optional - e.g., Electrician, Technician',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add_outlined,
                    color: AppColors.info,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Creating new staff member. Phone number and email must be unique across all staff. All fields marked with * are required.',
                      style: TextStyle(
                        color: AppColors.info,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions() {
    return [
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppColors.grey300),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _addStaff,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  : const Text('Add Staff'),
            ),
          ),
        ],
      ),
    ];
  }
}

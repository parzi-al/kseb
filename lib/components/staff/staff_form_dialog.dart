import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_toast.dart';
import '../../models/user_model.dart';

class StaffFormDialog extends StatefulWidget {
  final String? staffId; // null for add mode, non-null for edit mode
  final Map<String, dynamic>? staffData; // null for add mode
  final String? defaultTeamId;
  final UserRole currentUserRole;
  final VoidCallback? onStaffSaved;

  const StaffFormDialog({
    Key? key,
    this.staffId,
    this.staffData,
    this.defaultTeamId,
    required this.currentUserRole,
    this.onStaffSaved,
  }) : super(key: key);

  bool get isEditMode => staffId != null;

  static void show(
    BuildContext context, {
    String? staffId,
    Map<String, dynamic>? staffData,
    String? defaultTeamId,
    required UserRole currentUserRole,
    VoidCallback? onStaffSaved,
  }) {
    showDialog(
      barrierColor: Colors.black.withValues(alpha: 0.5),
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: StaffFormDialog(
          staffId: staffId,
          staffData: staffData,
          defaultTeamId: defaultTeamId,
          currentUserRole: currentUserRole,
          onStaffSaved: onStaffSaved,
        ),
      ),
    );
  }

  @override
  State<StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<StaffFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _areaCodeController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _selectedTeamId;
  UserRole _selectedRole = UserRole.staff;
  List<Map<String, String>> _availableTeams = [];
  bool _loadingTeams = true;

  @override
  void initState() {
    super.initState();

    // Initialize with existing data for edit mode
    if (widget.isEditMode && widget.staffData != null) {
      _nameController.text = widget.staffData!['name'] ?? '';
      _emailController.text = widget.staffData!['email'] ?? '';
      _phoneController.text = widget.staffData!['phone'] ?? '';
      _areaCodeController.text = widget.staffData!['areaCode'] ?? '';
      _selectedTeamId = widget.staffData!['teamId'];
      _selectedRole = UserRole.fromString(widget.staffData!['role'] ?? 'staff');
    } else {
      _selectedTeamId = widget.defaultTeamId;
    }

    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final teamsSnapshot =
          await FirebaseFirestore.instance.collection('teams').get();

      setState(() {
        _availableTeams = teamsSnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'name': (doc.data()['name'] ?? 'Unnamed Team') as String,
          };
        }).toList();
        _loadingTeams = false;
      });
    } catch (e) {
      print('Error loading teams: $e');
      setState(() {
        _loadingTeams = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _areaCodeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    // Close the dialog first
    Navigator.of(context).pop();

    // Show error using root context
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  Future<void> _saveStaff() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final areaCode = _areaCodeController.text.trim();

      // Check if email already exists (skip if editing same user)
      final existingUserQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        final existingDoc = existingUserQuery.docs.first;
        if (!widget.isEditMode || existingDoc.id != widget.staffId) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showError('A user with this email already exists!');
          }
          return;
        }
      }

      // Check if phone already exists (skip if editing same user)
      final existingPhoneQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (existingPhoneQuery.docs.isNotEmpty) {
        final existingDoc = existingPhoneQuery.docs.first;
        if (!widget.isEditMode || existingDoc.id != widget.staffId) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showError('A user with this phone number already exists!');
          }
          return;
        }
      }

      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'role': _selectedRole.name,
        'teamId': _selectedTeamId,
        'areaCode': areaCode.isEmpty ? null : areaCode,
        'bonusPoints': widget.staffData?['bonusPoints'] ?? 0,
        'bonusAmount': widget.staffData?['bonusAmount'] ?? 0.0,
      };

      if (widget.isEditMode) {
        // Update existing user
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.staffId)
            .update(userData);
      } else {
        // Create new user with Firebase Auth using secondary app
        // This prevents logging out the current user
        final password = _passwordController.text.trim();

        FirebaseApp? secondaryApp;
        try {
          // Create a secondary Firebase app instance
          secondaryApp = await Firebase.initializeApp(
            name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
            options: DefaultFirebaseOptions.currentPlatform,
          );

          // Get auth instance for secondary app
          final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

          // Create Firebase Auth account using secondary app
          final userCredential =
              await secondaryAuth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          // Add user document to Firestore with the Auth UID
          userData['createdAt'] = Timestamp.now();
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(userData);

          print('Staff member created with UID: ${userCredential.user!.uid}');

          // Clean up secondary app
          await secondaryApp.delete();
        } on FirebaseAuthException catch (e) {
          // Clean up secondary app if it was created
          if (secondaryApp != null) {
            await secondaryApp.delete();
          }

          if (mounted) {
            setState(() => _isLoading = false);
            String errorMessage = 'Error creating account';

            if (e.code == 'weak-password') {
              errorMessage = 'The password provided is too weak.';
            } else if (e.code == 'email-already-in-use') {
              errorMessage = 'An account already exists with this email.';
            } else {
              errorMessage = e.message ?? 'Error creating account';
            }

            _showError(errorMessage);
          }
          return;
        } catch (e) {
          // Clean up secondary app if it was created
          if (secondaryApp != null) {
            await secondaryApp.delete();
          }
          throw e;
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          widget.onStaffSaved?.call();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isEditMode
                          ? 'Staff member updated successfully'
                          : 'Staff member created successfully',
                    ),
                  ),
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
        }
      });
    } catch (e) {
      print('Error saving staff: $e');
      if (mounted) {
        AppToast.showError(context, 'Error saving staff member: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: _buildContent(),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              widget.isEditMode ? Icons.edit_rounded : Icons.person_add_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditMode ? 'Edit Staff Member' : 'Add New Staff',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEditMode
                      ? 'Update staff information'
                      : 'Create a new staff profile',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_rounded,
              required: true,
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email_rounded,
              required: true,
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
            const SizedBox(height: 20),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_rounded,
              required: true,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Phone number is required';
                }
                final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
                if (!phoneRegex.hasMatch(value!.trim())) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Password field - only shown when adding new staff
            if (!widget.isEditMode) ...[
              _buildPasswordField(),
              const SizedBox(height: 20),
            ],

            _buildTeamDropdown(),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _areaCodeController,
              label: 'Area Code',
              icon: Icons.location_on_rounded,
              required: false,
              textCapitalization: TextCapitalization.characters,
            ),

            // Role dropdown - only visible for COO and Director
            if (widget.currentUserRole == UserRole.coo ||
                widget.currentUserRole == UserRole.director) ...[
              const SizedBox(height: 20),
              _buildRoleDropdown(),
            ],

            const SizedBox(height: 20),
            _buildInfoBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool required,
    TextInputType? keyboardType,
    TextCapitalization? textCapitalization,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization ?? TextCapitalization.none,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
            hintText: 'Enter $label',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Password',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Password is required';
            }
            if (value!.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_rounded,
                color: AppColors.primary, size: 22),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: Colors.grey.shade600,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            hintText: 'Enter password (min. 6 characters)',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Team',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _loadingTeams
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Loading teams...'),
                  ],
                ),
              )
            : DropdownButtonFormField<String>(
                value: _selectedTeamId,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.groups_rounded,
                      color: AppColors.primary, size: 22),
                  hintText: 'Select a team (optional)',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No Team (Unassigned)'),
                  ),
                  ..._availableTeams.map((team) {
                    return DropdownMenuItem<String>(
                      value: team['id'],
                      child: Text(team['name']!),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedTeamId = value;
                  });
                },
              ),
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Role',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'COO/Director Only',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<UserRole>(
          value: _selectedRole,
          decoration: InputDecoration(
            prefixIcon: Icon(
              _getRoleIcon(_selectedRole),
              color: AppColors.primary,
              size: 22,
            ),
            hintText: 'Select role',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: widget.currentUserRole.manageableRoles.map((role) {
            return DropdownMenuItem<UserRole>(
              value: role,
              child: Row(
                children: [
                  Icon(_getRoleIcon(role),
                      size: 18, color: _getRoleColor(role)),
                  const SizedBox(width: 8),
                  Text(role.displayName),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getRoleColor(role).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      role.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getRoleColor(role),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedRole = value;
              });
            }
          },
        ),
      ],
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.staff:
        return Icons.person_rounded;
      case UserRole.supervisor:
        return Icons.supervisor_account_rounded;
      case UserRole.manager:
        return Icons.manage_accounts_rounded;
      case UserRole.coo:
        return Icons.admin_panel_settings_rounded;
      case UserRole.director:
        return Icons.workspace_premium_rounded;
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.staff:
        return Colors.blue;
      case UserRole.supervisor:
        return Colors.green;
      case UserRole.manager:
        return Colors.orange;
      case UserRole.coo:
        return Colors.purple;
      case UserRole.director:
        return Colors.red;
    }
  }

  Widget _buildInfoBox() {
    String message = widget.isEditMode
        ? 'Updates staff profile information.'
        : 'Creates user profile with Firebase Authentication. Staff can login with the email and password provided.';

    if (widget.currentUserRole == UserRole.coo ||
        widget.currentUserRole == UserRole.director) {
      message +=
          ' As ${widget.currentUserRole.displayName}, you can manage user roles.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withValues(alpha: 0.1),
            AppColors.info.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: AppColors.info,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.info.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveStaff,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
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
                  : Text(
                      widget.isEditMode ? 'Update Staff' : 'Add Staff',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

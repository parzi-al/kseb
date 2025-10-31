import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_toast.dart';
import '../../models/user_model.dart';

class AddStaffDialog extends StatefulWidget {
  final String? defaultTeamId;
  final UserRole currentUserRole;
  final VoidCallback? onStaffAdded;

  const AddStaffDialog({
    Key? key,
    this.defaultTeamId,
    required this.currentUserRole,
    this.onStaffAdded,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    String? defaultTeamId,
    required UserRole currentUserRole,
    VoidCallback? onStaffAdded,
  }) {
    showDialog(
      barrierColor: Colors.black.withValues(alpha: 0.5),
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AddStaffDialog(
          defaultTeamId: defaultTeamId,
          currentUserRole: currentUserRole,
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
  final _passwordController = TextEditingController();
  final _areaCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _selectedTeamId;
  List<Map<String, String>> _availableTeams = [];
  bool _loadingTeams = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _selectedTeamId = widget.defaultTeamId;
  }

  Future<void> _loadTeams() async {
    try {
      final teamsSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .get();
      
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

  Future<void> _addStaff() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final areaCode = _areaCodeController.text.trim();

      print('Creating new staff member: $email');

      // Check if email already exists in Firestore
      final existingUserQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (existingUserQuery.docs.isNotEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppToast.showError(context, 'A user with this email already exists!');
        }
        return;
      }

      // Check if phone already exists
      final existingPhoneQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (existingPhoneQuery.docs.isNotEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          AppToast.showError(context, 'A user with this phone number already exists!');
        }
        return;
      }

      // STEP 1: Save current user session
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserEmail = currentUser?.email;
      
      print('Current user saved: $currentUserEmail');

      // STEP 2: Create new Firebase Auth user
      UserCredential newUserCredential;
      try {
        newUserCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('Firebase Auth user created: ${newUserCredential.user?.uid}');
      } catch (authError) {
        if (mounted) {
          setState(() => _isLoading = false);
          String errorMessage = 'Authentication error';
          if (authError.toString().contains('email-already-in-use')) {
            errorMessage = 'Email is already registered in Firebase Auth';
          } else if (authError.toString().contains('weak-password')) {
            errorMessage = 'Password is too weak';
          }
          AppToast.showError(context, errorMessage);
        }
        return;
      }

      final newUserId = newUserCredential.user!.uid;

      // STEP 3: Create user document in Firestore
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(newUserId)
            .set({
          'name': name,
          'email': email,
          'phone': phone,
          'role': 'staff',
          'teamId': _selectedTeamId,
          'areaCode': areaCode.isEmpty ? null : areaCode,
          'bonusPoints': 0,
          'bonusAmount': 0.0,
          'createdAt': Timestamp.now(),
        });
        print('User document created in Firestore');
      } catch (firestoreError) {
        // Rollback: Delete the auth user if Firestore fails
        await newUserCredential.user?.delete();
        if (mounted) {
          setState(() => _isLoading = false);
          AppToast.showError(context, 'Error creating user profile. Please try again.');
        }
        return;
      }

      // STEP 4: Sign out the newly created user
      await FirebaseAuth.instance.signOut();
      print('New user signed out');

      // STEP 5: Important note - user will need to login again
      // We cannot automatically restore the session without the password
      
      print('Staff member added successfully');

      if (mounted) {
        Navigator.pop(context);
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          widget.onStaffAdded?.call();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Staff created! You need to login again.'),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });

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
        const SizedBox(height: 8),
        Text(
          'Create staff profile',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                helperText: 'Used for login - must be unique',
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
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password *',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                helperText: 'Minimum 6 characters',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
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
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                helperText: 'Must be unique',
              ),
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
            const SizedBox(height: 16),
            
            _loadingTeams
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
                    value: _selectedTeamId,
                    decoration: const InputDecoration(
                      labelText: 'Team',
                      prefixIcon: Icon(Icons.groups),
                      border: OutlineInputBorder(),
                      helperText: 'Optional',
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
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _areaCodeController,
              decoration: const InputDecoration(
                labelText: 'Area Code',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
                helperText: 'Optional',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Creating staff will create a Firebase Auth account. You will be logged out and need to login again.',
                      style: TextStyle(
                        color: AppColors.warning.withValues(alpha: 0.9),
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

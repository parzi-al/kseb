import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_typography.dart';
import '../../utils/app_toast.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../common/modern_dropdown.dart';\nimport '../common/app_loading.dart';

class TeamDialog extends StatefulWidget {
  final TeamModel? team; // null for creating new team, TeamModel for editing

  const TeamDialog({
    Key? key,
    this.team,
  }) : super(key: key);

  @override
  State<TeamDialog> createState() => _TeamDialogState();
}

class _TeamDialogState extends State<TeamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaCodeController = TextEditingController();
  
  String? _selectedSupervisorId;
  String? _selectedManagerId;
  List<String> _selectedStaffIds = [];
  List<Map<String, dynamic>> _supervisors = [];
  List<Map<String, dynamic>> _managers = [];
  List<Map<String, dynamic>> _allStaff = [];
  bool _isLoading = false;
  bool _isLoadingUsers = true;

  bool get isEditing => widget.team != null;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    if (isEditing) {
      _nameController.text = widget.team!.name;
      _areaCodeController.text = widget.team!.areaCode;
      // Don't set selected IDs here - wait until users are loaded
      // to validate they match the correct roles
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      final supervisorsList = <Map<String, dynamic>>[];
      final managersList = <Map<String, dynamic>>[];
      final staffList = <Map<String, dynamic>>[];

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final role = UserRole.fromString(data['role'] ?? 'staff');
        
        final userData = {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'role': role,
        };

        // Only supervisors can be supervisors
        if (role == UserRole.supervisor) {
          supervisorsList.add(userData);
        }

        // Only managers can be managers
        if (role == UserRole.manager) {
          managersList.add(userData);
        }

        // Only staff can be staff members
        if (role == UserRole.staff) {
          staffList.add(userData);
        }
      }

      setState(() {
        _supervisors = supervisorsList;
        _managers = managersList;
        _allStaff = staffList;
        _isLoadingUsers = false;
        
        // Now set selected values if editing, but only if they match the correct role
        if (isEditing) {
          // Set supervisor if the user exists in supervisors list
          final supervisorExists = supervisorsList.any((u) => u['id'] == widget.team!.supervisorId);
          _selectedSupervisorId = supervisorExists ? widget.team!.supervisorId : null;
          
          // Set manager if the user exists in managers list
          final managerExists = managersList.any((u) => u['id'] == widget.team!.managerId);
          _selectedManagerId = managerExists ? widget.team!.managerId : null;
          
          // Load existing staff members (excluding supervisor and manager)
          _selectedStaffIds = List<String>.from(widget.team!.members)
            ..remove(widget.team!.supervisorId)
            ..remove(widget.team!.managerId);
          // Only keep staff IDs that exist in the staff list
          _selectedStaffIds.retainWhere((id) => staffList.any((s) => s['id'] == id));
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      if (mounted) {
        AppToast.showError(context, 'Error loading users: $e');
      }
    }
  }

  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSupervisorId == null) {
      AppToast.showError(context, 'Please select a supervisor');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      // Build members list
      final members = <String>{_selectedSupervisorId!};
      if (_selectedManagerId != null) {
        members.add(_selectedManagerId!);
      }
      // Add selected staff members
      members.addAll(_selectedStaffIds);

      final teamData = {
        'name': _nameController.text.trim(),
        'areaCode': _areaCodeController.text.trim(),
        'supervisorId': _selectedSupervisorId,
        'managerId': _selectedManagerId,
        'members': members.toList(),
        'assets': isEditing ? widget.team!.assets : [],
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastUpdatedBy': currentUser?.uid,
      };

      if (isEditing) {
        // Update existing team
        await FirebaseFirestore.instance
            .collection('teams')
            .doc(widget.team!.id)
            .update(teamData);

        if (mounted) {
          AppToast.showSuccess(context, 'Team updated successfully!');
        }
      } else {
        // Create new team
        teamData['createdAt'] = FieldValue.serverTimestamp();
        teamData['createdBy'] = currentUser?.uid;

        await FirebaseFirestore.instance
            .collection('teams')
            .add(teamData);

        if (mounted) {
          AppToast.showSuccess(context, 'Team created successfully!');
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Error saving team: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      backgroundColor: AppColors.surface,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWithLowOpacity,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_rounded : Icons.group_add_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Team' : 'Create New Team',
                            style: TextStyle(
                              fontSize: AppTypography.fontSize2XL,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isEditing 
                                ? 'Update team information'
                                : 'Add a new team to your organization',
                            style: TextStyle(
                              fontSize: AppTypography.fontSizeSM,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Team Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Team Name',
                    hintText: 'e.g., Team 01',
                    prefixIcon: Icon(Icons.label_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter team name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.base),

                // Area Code
                TextFormField(
                  controller: _areaCodeController,
                  decoration: InputDecoration(
                    labelText: 'Area Code',
                    hintText: 'e.g., AREA_001',
                    prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter area code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.base),

                // Supervisor Dropdown
                _isLoadingUsers
                    ? const Center(child: AppLoading(variant: AppLoadingVariant.inline, message: 'Loading supervisors...'))
                    : _supervisors.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(AppSpacing.base),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                color: AppColors.grey300,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    'No supervisors available',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: AppTypography.fontSizeBase,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ModernDropdown<String>(
                            value: _selectedSupervisorId,
                            label: 'Supervisor',
                            hint: 'Select Supervisor',
                            prefixIcon: Icons.person_rounded,
                            isRequired: true,
                            items: _supervisors.map((user) {
                              return ModernDropdownItem.create<String>(
                                value: user['id'],
                                text: user['name'],
                                subtitle: (user['role'] as UserRole).displayName,
                                icon: Icons.badge_rounded,
                                iconColor: AppColors.info,
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSupervisorId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a supervisor';
                              }
                              return null;
                            },
                          ),
                const SizedBox(height: AppSpacing.base),

                // Manager Dropdown (Optional)
                _isLoadingUsers
                    ? const SizedBox()
                    : _managers.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(AppSpacing.base),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              border: Border.all(
                                color: AppColors.grey300,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    'No managers available',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: AppTypography.fontSizeBase,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ModernDropdown<String>(
                            value: _selectedManagerId,
                            label: 'Manager',
                            hint: 'Select Manager (Optional)',
                            prefixIcon: Icons.admin_panel_settings_rounded,
                            items: [
                              ModernDropdownItem.create<String>(
                                value: '',
                                text: 'None',
                                icon: Icons.block_rounded,
                                iconColor: AppColors.grey500,
                              ),
                              ..._managers.map((user) {
                                return ModernDropdownItem.create<String>(
                                  value: user['id'],
                                  text: user['name'],
                                  subtitle: (user['role'] as UserRole).displayName,
                                  icon: Icons.manage_accounts_rounded,
                                  iconColor: Colors.purple,
                                );
                              }).toList(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedManagerId = value == '' ? null : value;
                              });
                            },
                          ),
                const SizedBox(height: AppSpacing.base),

                // Staff Members Section
                if (!_isLoadingUsers) ...[
                  Text(
                    'Staff Members',
                    style: TextStyle(
                      fontSize: AppTypography.fontSizeBase,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _allStaff.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(AppSpacing.base),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: AppColors.grey300,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  'No staff members available',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: AppTypography.fontSizeBase,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(
                              color: AppColors.grey300,
                              width: 1.5,
                            ),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _allStaff.length,
                            itemBuilder: (context, index) {
                              final staff = _allStaff[index];
                        final staffId = staff['id'];
                        final isSelected = _selectedStaffIds.contains(staffId);
                        final isSupervisor = staffId == _selectedSupervisorId;
                        final isManager = staffId == _selectedManagerId;
                        
                        // Don't show if already selected as supervisor or manager
                        if (isSupervisor || isManager) {
                          return const SizedBox.shrink();
                        }

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedStaffIds.add(staffId);
                              } else {
                                _selectedStaffIds.remove(staffId);
                              }
                            });
                          },
                          title: Text(
                            staff['name'],
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: AppTypography.fontSizeBase,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            (staff['role'] as UserRole).displayName,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: AppTypography.fontSizeSM,
                            ),
                          ),
                          secondary: Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          activeColor: AppColors.primary,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 0,
                          ),
                        );
                      },
                    ),
                  ),
                  if (_allStaff.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${_selectedStaffIds.length} staff member(s) selected',
                      style: TextStyle(
                        fontSize: AppTypography.fontSizeSM,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: AppSpacing.xl),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          side: BorderSide(color: AppColors.grey300),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTeam,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                // DS-EXCEPTION: Inline button spinner — AppLoading is for page/section loading
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing ? 'Update' : 'Create',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppTypography.fontSizeLG,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

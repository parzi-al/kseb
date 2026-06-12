import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/common/app_bar_builder.dart';
import '../components/common/modern_dropdown.dart';
import '../components/common/skeleton_loader.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_decorations.dart';
import '../utils/app_typography.dart';
import '../utils/app_toast.dart';
import '../utils/page_transitions.dart';
import '../models/user_model.dart';
import 'bonus_history_screen.dart';

class BonusManagementScreen extends StatefulWidget {
  const BonusManagementScreen({super.key});

  @override
  State<BonusManagementScreen> createState() => _BonusManagementScreenState();
}

class _BonusManagementScreenState extends State<BonusManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _employees = [];

  String? _selectedTeamId;
  String? _selectedEmployeeId;
  String _selectedAction = 'add'; // 'add' or 'remove'
  final TextEditingController _bonusPointsController = TextEditingController();
  final TextEditingController _bonusAmountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadTeams();
  }

  @override
  void dispose() {
    _bonusPointsController.dispose();
    _bonusAmountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
    }
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final teamsSnapshot = await _firestore.collection('teams').get();

      _teams = teamsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc.data()['name'] ?? 'Unknown Team',
        };
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Error loading teams: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmployeesByTeam(String teamId) async {
    setState(() {
      _isLoading = true;
      _selectedEmployeeId = null;
      _employees = [];
    });

    try {
      final usersSnapshot = await _firestore
          .collection('users')
          .where('teamId', isEqualTo: teamId)
          .get();

      _employees = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'email': data['email'] ?? '',
          'role': data['role'] ?? 'staff',
          'currentBonusPoints': data['bonusPoints'] ?? 0,
          'currentBonusAmount': (data['bonusAmount'] ?? 0).toDouble(),
        };
      }).toList();

      // Sort by name
      _employees
          .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Error loading employees: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitBonus() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEmployeeId == null) {
      AppToast.showError(context, 'Please select an employee');
      return;
    }

    // At least one field must be filled
    final bonusPoints = int.tryParse(_bonusPointsController.text) ?? 0;
    final bonusAmount = double.tryParse(_bonusAmountController.text) ?? 0.0;

    if (bonusPoints == 0 && bonusAmount == 0.0) {
      AppToast.showError(
          context, 'Please enter at least bonus points or amount');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current employee data
      final employeeDoc =
          await _firestore.collection('users').doc(_selectedEmployeeId).get();

      if (!employeeDoc.exists) {
        throw Exception('Employee not found');
      }

      final currentData = employeeDoc.data()!;
      final currentPoints = currentData['bonusPoints'] ?? 0;
      final currentAmount = (currentData['bonusAmount'] ?? 0).toDouble();

      // Calculate new values
      int newPoints;
      double newAmount;

      if (_selectedAction == 'add') {
        newPoints = currentPoints + bonusPoints;
        newAmount = currentAmount + bonusAmount;
      } else {
        newPoints =
            (currentPoints - bonusPoints).clamp(0, double.infinity).toInt();
        newAmount = (currentAmount - bonusAmount).clamp(0.0, double.infinity);
      }

      // Update employee bonus totals in users collection
      await _firestore.collection('users').doc(_selectedEmployeeId).update({
        'bonusPoints': newPoints,
        'bonusAmount': newAmount,
      });

      // Create a new record in bonuses collection
      await _firestore.collection('bonuses').add({
        'userId': _selectedEmployeeId,
        'points': _selectedAction == 'add' ? bonusPoints : -bonusPoints,
        'amount': _selectedAction == 'add' ? bonusAmount : -bonusAmount,
        'reason': _reasonController.text.trim(),
        'updatedBy': _currentUserId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        AppToast.showSuccess(
          context,
          'Bonus ${_selectedAction == 'add' ? 'added' : 'removed'} successfully!',
        );
      }

      // Reload employees to show updated values
      await _loadEmployeesByTeam(_selectedTeamId!);

      // Clear form
      _bonusPointsController.clear();
      _bonusAmountController.clear();
      _reasonController.clear();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Error updating bonus: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(
        title: 'Bonus Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'View Bonus History',
            onPressed: () {
              Navigator.push(
                context,
                AppRoute(
                  builder: (context) => const BonusHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const BonusManagementSkeleton()
          : SingleChildScrollView(
              padding: EdgeInsets.all(context.responsivePadding(AppSpacing.xl)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusDefault),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.card_giftcard_rounded,
                            size: 48,
                            color: AppColors.textOnPrimary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Manage Employee Bonuses',
                            style: AppTypography.titleStyle.copyWith(
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Add or remove bonus points and amounts',
                            style: AppTypography.bodyStyle.copyWith(
                              color: AppColors.textOnPrimary
                                  .withValues(alpha: 0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.responsiveSpacing(AppSpacing.xl)),

                    // Team Selection
                    _buildSectionTitle('Select Team'),
                    const SizedBox(height: AppSpacing.md),
                    _buildTeamDropdown(),
                    const SizedBox(height: AppSpacing.xl),

                    // Employee Selection
                    if (_selectedTeamId != null) ...[
                      _buildSectionTitle('Select Employee'),
                      const SizedBox(height: AppSpacing.md),
                      _buildEmployeeDropdown(),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // Show current bonus if employee selected
                    if (_selectedEmployeeId != null) ...[
                      _buildCurrentBonusCard(),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // Action Selection (Add/Remove)
                    if (_selectedEmployeeId != null) ...[
                      _buildSectionTitle('Action'),
                      const SizedBox(height: AppSpacing.md),
                      _buildActionSelector(),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // Bonus Input Fields
                    if (_selectedEmployeeId != null) ...[
                      _buildSectionTitle('Bonus Details'),
                      const SizedBox(height: AppSpacing.md),
                      _buildInputFields(),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // Submit Button
                    if (_selectedEmployeeId != null) ...[
                      _buildSubmitButton(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.subheadingStyle.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTeamDropdown() {
    return ModernDropdown<String>(
      value: _selectedTeamId,
      label: 'Team',
      hint: 'Select a team',
      prefixIcon: Icons.groups_rounded,
      fillColor: AppColors.surface,
      items: _teams.map((team) {
        return ModernDropdownItem.create<String>(
          value: team['id'],
          text: team['name'],
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _selectedTeamId = value);
          }
        });
        _loadEmployeesByTeam(value);
      },
    );
  }

  Widget _buildEmployeeDropdown() {
    return ModernDropdown<String>(
      value: _selectedEmployeeId,
      label: 'Employee',
      hint: _employees.isEmpty
          ? 'No employees in this team'
          : 'Select an employee',
      prefixIcon: Icons.person_search_rounded,
      fillColor: AppColors.surface,
      items: _employees.map((employee) {
        return DropdownMenuItem<String>(
          value: employee['id'],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                employee['name'],
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${employee['email']} • ${UserRole.fromString(employee['role']).displayName}',
                style: AppTypography.captionStyle,
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: _employees.isEmpty
          ? null
          : (value) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _selectedEmployeeId = value);
                }
              });
            },
    );
  }

  Widget _buildCurrentBonusCard() {
    final employee = _employees.firstWhere(
      (e) => e['id'] == _selectedEmployeeId,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Current Bonus',
            style: AppTypography.subheadingStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBonusStat(
                'Points',
                employee['currentBonusPoints'].toString(),
                Icons.star_rounded,
                Colors.amber, // DS-EXCEPTION: status color
              ),
              _buildBonusStat(
                'Amount',
                '₹${employee['currentBonusAmount'].toStringAsFixed(2)}',
                Icons.currency_rupee_rounded,
                Colors.green, // DS-EXCEPTION: status color
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBonusStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.captionStyle,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.headingStyle.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Add Bonus',
            Icons.add_circle_outline_rounded,
            'add',
            Colors.green, // DS-EXCEPTION: status color
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        Expanded(
          child: _buildActionButton(
            'Remove Bonus',
            Icons.remove_circle_outline_rounded,
            'remove',
            Colors.red, // DS-EXCEPTION: status color
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    String action,
    Color color,
  ) {
    final isSelected = _selectedAction == action;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedAction = action;
        });
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected ? color : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.fontSizeBase,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        // Bonus Points
        TextFormField(
          controller: _bonusPointsController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Bonus Points (Optional)',
            hintText: 'Enter bonus points',
            prefixIcon: Icon(Icons.star_rounded, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (int.tryParse(value) == null || int.parse(value) < 0) {
                return 'Please enter a valid positive number';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.base),

        // Bonus Amount
        TextFormField(
          controller: _bonusAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Bonus Amount (₹) (Optional)',
            hintText: 'Enter bonus amount',
            prefixIcon:
                Icon(Icons.currency_rupee_rounded, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (double.tryParse(value) == null || double.parse(value) < 0) {
                return 'Please enter a valid positive amount';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.base),

        // Reason
        TextFormField(
          controller: _reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Reason',
            hintText: 'Enter reason for bonus update',
            prefixIcon: Icon(Icons.edit_note_rounded, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a reason';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Note: Enter at least one value (points or amount)',
          style: AppTypography.captionStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _selectedAction == 'add'
              ? [
                  Colors.green,
                  Colors.green.shade700
                ] // DS-EXCEPTION: status color
              : [Colors.red, Colors.red.shade700], // DS-EXCEPTION: status color
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: (_selectedAction == 'add'
                    ? Colors.green
                    : Colors.red) // DS-EXCEPTION: status color
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _submitBonus,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    // DS-EXCEPTION: Inline button spinner — AppLoading is for page/section loading
                    child: CircularProgressIndicator(
                      color: AppColors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _selectedAction == 'add'
                            ? Icons.add_rounded
                            : Icons.remove_rounded,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _selectedAction == 'add' ? 'Add Bonus' : 'Remove Bonus',
                        style: AppTypography.subheadingStyle.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

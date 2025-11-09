import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import '../utils/app_toast.dart';
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
      appBar: AppBar(
        title: Text(
          'Bonus Management',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadowLight,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'View Bonus History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BonusHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.card_giftcard_rounded,
                            size: 48,
                            color: AppColors.textOnDark,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Manage Employee Bonuses',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add or remove bonus points and amounts',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  AppColors.textOnDark.withValues(alpha: 0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Team Selection
                    _buildSectionTitle('Select Team'),
                    const SizedBox(height: 12),
                    _buildTeamDropdown(),
                    const SizedBox(height: 24),

                    // Employee Selection
                    if (_selectedTeamId != null) ...[
                      _buildSectionTitle('Select Employee'),
                      const SizedBox(height: 12),
                      _buildEmployeeDropdown(),
                      const SizedBox(height: 24),
                    ],

                    // Show current bonus if employee selected
                    if (_selectedEmployeeId != null) ...[
                      _buildCurrentBonusCard(),
                      const SizedBox(height: 24),
                    ],

                    // Action Selection (Add/Remove)
                    if (_selectedEmployeeId != null) ...[
                      _buildSectionTitle('Action'),
                      const SizedBox(height: 12),
                      _buildActionSelector(),
                      const SizedBox(height: 24),
                    ],

                    // Bonus Input Fields
                    if (_selectedEmployeeId != null) ...[
                      _buildSectionTitle('Bonus Details'),
                      const SizedBox(height: 12),
                      _buildInputFields(),
                      const SizedBox(height: 24),
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
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTeamDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedTeamId,
          hint: Text(
            'Select a team',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
          items: _teams.map((team) {
            return DropdownMenuItem<String>(
              value: team['id'],
              child: Text(
                team['name'],
                style: TextStyle(color: AppColors.textPrimary),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedTeamId = value;
              });
              _loadEmployeesByTeam(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmployeeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedEmployeeId,
          hint: Text(
            _employees.isEmpty
                ? 'No employees in this team'
                : 'Select an employee',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
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
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: _employees.isEmpty
              ? null
              : (value) {
                  setState(() {
                    _selectedEmployeeId = value;
                  });
                },
        ),
      ),
    );
  }

  Widget _buildCurrentBonusCard() {
    final employee = _employees.firstWhere(
      (e) => e['id'] == _selectedEmployeeId,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Current Bonus',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBonusStat(
                'Points',
                employee['currentBonusPoints'].toString(),
                Icons.star_rounded,
                Colors.amber,
              ),
              _buildBonusStat(
                'Amount',
                '₹${employee['currentBonusAmount'].toStringAsFixed(2)}',
                Icons.currency_rupee_rounded,
                Colors.green,
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
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
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            'Remove Bonus',
            Icons.remove_circle_outline_rounded,
            'remove',
            Colors.red,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
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
              borderRadius: BorderRadius.circular(12),
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
        const SizedBox(height: 16),

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
              borderRadius: BorderRadius.circular(12),
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
        const SizedBox(height: 12),
        Text(
          'Note: Enter at least one value (points or amount)',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
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
              ? [Colors.green, Colors.green.shade700]
              : [Colors.red, Colors.red.shade700],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (_selectedAction == 'add' ? Colors.green : Colors.red)
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
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
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
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedAction == 'add' ? 'Add Bonus' : 'Remove Bonus',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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

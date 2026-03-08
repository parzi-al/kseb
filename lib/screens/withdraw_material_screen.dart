import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/common/app_bar_builder.dart';
import '../components/common/app_loading.dart';
import '../utils/app_colors.dart';
import '../utils/app_decorations.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../utils/app_toast.dart';

class WithdrawMaterialScreen extends StatefulWidget {
  const WithdrawMaterialScreen({super.key});

  @override
  State<WithdrawMaterialScreen> createState() => _WithdrawMaterialScreenState();
}

class _WithdrawMaterialScreenState extends State<WithdrawMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  final _quantityController = TextEditingController();
  final _projectCodeController = TextEditingController();
  final _purposeController = TextEditingController();
  final _remarksController = TextEditingController();

  // Dropdown values
  String? _selectedMaterial;
  String? _selectedPriority;
  DateTime? _requiredDate;

  final List<String> _priorities = [
    'Low',
    'Medium',
    'High',
    'Critical',
  ];

  // Stream for fetching materials from Firestore
  List<Map<String, dynamic>> _availableMaterials = [];
  bool _isLoadingMaterials = true;

  @override
  void initState() {
    super.initState();
    _fetchAvailableMaterials();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _projectCodeController.dispose();
    _purposeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableMaterials() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('materials')
          .where('status', isEqualTo: 'Available')
          .get();

      setState(() {
        _availableMaterials = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': data['materialName'] ?? 'Unknown Material',
            'available': data['quantity'] ?? 0,
            'unit': data['unit'] ?? 'Units',
            'materialCode': data['materialCode'] ?? '',
            'category': data['category'] ?? 'Other',
          };
        }).toList();
        _isLoadingMaterials = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMaterials = false;
        });
        AppErrorHandler.handleError(context, e,
            customMessage: 'Failed to load materials');
      }
    }
  }

  Future<void> _submitWithdrawRequest() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.showError(context, 'Please fill all required fields correctly.');
      return;
    }

    if (_requiredDate == null) {
      AppToast.showError(context, 'Please select required date.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      final selectedMaterialData = _availableMaterials
          .firstWhere((material) => material['name'] == _selectedMaterial);

      final requestData = {
        'materialId': selectedMaterialData['id'],
        'materialName': _selectedMaterial,
        'requestedQuantity': double.parse(_quantityController.text.trim()),
        'unit': selectedMaterialData['unit'],
        'projectCode': _projectCodeController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'priority': _selectedPriority,
        'requiredDate': Timestamp.fromDate(_requiredDate!),
        'remarks': _remarksController.text.trim(),
        'requestedBy': user.uid,
        'requestedByEmail': user.email,
        'requestTimestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
        'approvalStatus': 'Awaiting Approval',
      };

      await FirebaseFirestore.instance
          .collection('material_requests')
          .add(requestData);

      if (mounted) {
        AppToast.showSuccess(
            context, 'Withdrawal request submitted successfully! 📋');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(context, e,
            customMessage: 'Failed to submit request');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectRequiredDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _requiredDate) {
      setState(() {
        _requiredDate = picked;
      });
    }
  }

  String _getAvailableQuantity() {
    if (_selectedMaterial == null) return '';
    final material =
        _availableMaterials.firstWhere((m) => m['name'] == _selectedMaterial);
    return '${material['available']} ${material['unit']} available';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(
        title: 'Withdraw Material',
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.base),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isLoadingMaterials = true;
                });
                _fetchAvailableMaterials();
              },
              icon: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryWithLowOpacity,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              tooltip: 'Refresh Materials',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: AppLoading(),
            )
          : Column(
              children: [
                // Modern Header Section
                Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(context.responsivePadding(AppSpacing.xl), context.responsivePadding(AppSpacing.xl), context.responsivePadding(AppSpacing.xl), context.responsivePadding(AppSpacing.xxl)),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.primaryWithLowOpacity,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.remove_circle_outline_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        Text(
                          'Withdraw Material',
                          style: AppTypography.displayLargeStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Request materials for your project',
                          style: AppTypography.subheadingStyle.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                // Form Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchAvailableMaterials,
                    color: AppColors.primary,
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(context.responsivePadding(AppSpacing.xl)),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMaterialSelectionCard(),
                            SizedBox(height: context.responsiveSpacing(AppSpacing.xl)),
                            _buildProjectDetailsCard(),
                            SizedBox(height: context.responsiveSpacing(AppSpacing.xl)),
                            _buildRequestDetailsCard(),
                            SizedBox(height: context.responsiveSpacing(AppSpacing.xxl)),
                            // Submit Button
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.warning,
                                    AppColors.warning.withValues(alpha: 0.8)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusDefault),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.warning
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _submitWithdrawRequest,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusDefault),
                                  child: Center(
                                    child: Text(
                                      'SUBMIT REQUEST',
                                      style: AppTypography.subheadingStyle
                                          .copyWith(
                                        color: AppColors.textOnPrimary,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryWithLowOpacity,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            title,
            style: AppTypography.titleStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialSelectionCard() {
    return Container(
      decoration: AppDecorations.modernCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            _buildSectionHeader('Material Selection', Icons.inventory_outlined),
            const SizedBox(height: AppSpacing.sm),

            // Material Dropdown
            _isLoadingMaterials
                ? Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.grey300, width: 1),
                    ),
                    child: const Center(
                      child: AppLoading(
                        variant: AppLoadingVariant.inline,
                        message: 'Loading materials...',
                      ),
                    ),
                  )
                : _availableMaterials.isEmpty
                    ? Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          border:
                              Border.all(color: AppColors.grey300, width: 1),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_outlined,
                                  color: AppColors.textSecondary),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'No materials available',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextButton.icon(
                                onPressed: _fetchAvailableMaterials,
                                icon: Icon(Icons.refresh,
                                    color: AppColors.primary),
                                label: Text(
                                  'Refresh',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _buildDropdown(
                        value: _selectedMaterial,
                        label: 'Select Material',
                        icon: Icons.inventory_2_outlined,
                        items: _availableMaterials
                            .map((m) => m['name'] as String)
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedMaterial = value),
                        validator: (value) =>
                            value == null ? 'Please select a material' : null,
                      ),

            if (_selectedMaterial != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border:
                      Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _getAvailableQuantity(),
                      style: TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.base),

            // Quantity
            _buildTextField(
              controller: _quantityController,
              label: 'Requested Quantity',
              icon: Icons.numbers_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Quantity is required';
                final qty = double.tryParse(value!);
                if (qty == null) return 'Invalid number';
                if (qty <= 0) return 'Quantity must be greater than 0';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectDetailsCard() {
    return Container(
      decoration: AppDecorations.modernCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            _buildSectionHeader(
                'Project Details', Icons.business_center_outlined),
            const SizedBox(height: AppSpacing.sm),

            // Project Code
            _buildTextField(
              controller: _projectCodeController,
              label: 'Project Code',
              icon: Icons.assignment_outlined,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Project code is required' : null,
            ),
            const SizedBox(height: AppSpacing.base),

            // Purpose
            _buildTextField(
              controller: _purposeController,
              label: 'Purpose/Usage',
              icon: Icons.description_outlined,
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Purpose is required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestDetailsCard() {
    return Container(
      decoration: AppDecorations.modernCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            _buildSectionHeader('Request Details', Icons.schedule_outlined),
            const SizedBox(height: AppSpacing.sm),

            // Priority
            _buildDropdown(
              value: _selectedPriority,
              label: 'Priority Level',
              icon: Icons.priority_high_outlined,
              items: _priorities,
              onChanged: (value) => setState(() => _selectedPriority = value),
              validator: (value) =>
                  value == null ? 'Please select priority' : null,
            ),
            const SizedBox(height: AppSpacing.base),

            // Required Date
            Container(
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.grey300, width: 1),
              ),
              child: InkWell(
                onTap: _selectRequiredDate,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Required Date',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.calendar_today_outlined,
                        color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                  ),
                  child: Text(
                    _requiredDate != null
                        ? '${_requiredDate!.day}/${_requiredDate!.month}/${_requiredDate!.year}'
                        : 'Select required date',
                    style: TextStyle(
                      color: _requiredDate != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),

            // Remarks
            _buildTextField(
              controller: _remarksController,
              label: 'Additional Remarks (Optional)',
              icon: Icons.note_add_outlined,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: AppDecorations.modernCardDecoration,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: AppTypography.bodyMediumStyle.copyWith(
          fontSize: AppTypography.fontSizeLG,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryWithLowOpacity,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.surface,
          alignLabelWithHint: maxLines > 1,
          contentPadding: const EdgeInsets.all(AppSpacing.lg),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: AppDecorations.modernCardDecoration,
      child: DropdownButtonFormField<String>(
        value: value,
        validator: validator,
        style: AppTypography.bodyMediumStyle.copyWith(
          fontSize: AppTypography.fontSizeLG,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryWithLowOpacity,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.all(AppSpacing.lg),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: AppTypography.bodyMediumStyle.copyWith(
                      fontSize: AppTypography.fontSizeLG,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        dropdownColor: AppColors.surface,
        icon: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

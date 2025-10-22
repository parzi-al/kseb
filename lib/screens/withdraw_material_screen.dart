import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
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
      appBar: AppBar(
        leading: Container(
          margin: const EdgeInsets.all(8),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ),
        title: Text(
          'Withdraw Material',
          style: AppColors.getResponsiveTextStyle(context, AppColors.headingStyle),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadowLight,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _isLoadingMaterials = true;
                });
                _fetchAvailableMaterials();
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryWithLowOpacity,
                  borderRadius: BorderRadius.circular(12),
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
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : Column(
              children: [
                // Modern Header Section
                Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppColors.getResponsivePadding(context, 12), 
                      AppColors.getResponsivePadding(context, 12), 
                      AppColors.getResponsivePadding(context, 12), 
                      AppColors.getResponsivePadding(context, 16)
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppColors.getResponsivePadding(context, 8)),
                          decoration: BoxDecoration(
                            color: AppColors.primaryWithLowOpacity,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.remove_circle_outline_rounded,
                            size: AppColors.getResponsiveHeight(context, 32),
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: AppColors.getResponsiveSpacing(context, 12)),
                        Text(
                          'Withdraw Material',
                          style: AppColors.getResponsiveTextStyle(context, AppColors.displayStyle).copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppColors.getResponsiveSpacing(context, 6)),
                        Text(
                          'Request materials for your project',
                          style: TextStyle(
                            fontSize: AppColors.getResponsiveFontSize(context, AppColors.fontSizeBase),
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
                        padding: EdgeInsets.all(AppColors.getResponsivePadding(context, 8.0)),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMaterialSelectionCard(),
                            SizedBox(height: AppColors.getResponsiveSpacing(context, 16)),
                            _buildProjectDetailsCard(),
                            SizedBox(height: AppColors.getResponsiveSpacing(context, 16)),
                            _buildRequestDetailsCard(),
                            SizedBox(height: AppColors.getResponsiveSpacing(context, 20)),
                            // Submit Button
                            Container(
                              width: double.infinity,
                              height: AppColors.getResponsiveHeight(context, 44),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.warning,
                                    AppColors.warning.withValues(alpha: 0.8)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
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
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: Text(
                                      'SUBMIT REQUEST',
                                      style: TextStyle(
                                        color: AppColors.textOnDark,
                                        fontSize: AppColors.getResponsiveFontSize(context, AppColors.fontSizeBase),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
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
      padding: EdgeInsets.only(bottom: AppColors.getResponsiveSpacing(context, 12.0)),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppColors.getResponsivePadding(context, 6)),
            decoration: BoxDecoration(
              color: AppColors.primaryWithLowOpacity,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.primary, size: AppColors.getResponsiveHeight(context, 18)),
          ),
          SizedBox(width: AppColors.getResponsiveSpacing(context, 8)),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppColors.getResponsiveFontSize(context, AppColors.fontSizeLG),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialSelectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppColors.getResponsivePadding(context, 12.0)),
        child: Column(
          children: [
            _buildSectionHeader('Material Selection', Icons.inventory_outlined),
            SizedBox(height: AppColors.getResponsiveSpacing(context, 16)),

            // Material Dropdown
            _isLoadingMaterials
                ? Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppColors.getResponsivePadding(context, 8)),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey300, width: 1),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Loading materials...',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : _availableMaterials.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppColors.getResponsivePadding(context, 8)),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                          color: AppColors.grey50,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.grey300, width: 1),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_outlined,
                                  color: AppColors.textSecondary),
                              const SizedBox(height: 8),
                              Text(
                                'No materials available',
                                style:
                                    TextStyle(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 8),
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

            SizedBox(height: AppColors.getResponsiveSpacing(context, 12)),

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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppColors.getResponsivePadding(context, 12.0)),
        child: Column(
          children: [
            _buildSectionHeader(
                'Project Details', Icons.business_center_outlined),
            SizedBox(height: AppColors.getResponsiveSpacing(context, 16)),

            // Project Code
            _buildTextField(
              controller: _projectCodeController,
              label: 'Project Code',
              icon: Icons.assignment_outlined,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Project code is required' : null,
            ),
            SizedBox(height: AppColors.getResponsiveSpacing(context, 12)),

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
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppColors.getResponsivePadding(context, 12.0)),
        child: Column(
          children: [
            _buildSectionHeader('Request Details', Icons.schedule_outlined),
            SizedBox(height: AppColors.getResponsiveSpacing(context, 16)),

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
            SizedBox(height: AppColors.getResponsiveSpacing(context, 12)),

            // Required Date
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppColors.getResponsivePadding(context, 8)),
              child: Container(
                decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey300, width: 1),
              ),
              child: InkWell(
                onTap: _selectRequiredDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Required Date',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.calendar_today_outlined,
                        color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 12),

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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppColors.getResponsivePadding(context, 8)),
      child: Container(
        decoration: AppColors.modernCardDecoration,
        child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryWithLowOpacity,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.surface,
          alignLabelWithHint: maxLines > 1,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppColors.getResponsivePadding(context, 8)),
      child: Container(
        decoration: AppColors.modernCardDecoration,
        child: DropdownButtonFormField<String>(
        value: value,
        validator: validator,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryWithLowOpacity,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        dropdownColor: AppColors.surface,
        menuMaxHeight: 300,
        isDense: true,
        isExpanded: true,
        icon: Container(
          padding: const EdgeInsets.all(4),
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
      ),
    );
  }
}

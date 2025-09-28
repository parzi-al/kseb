import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import '../utils/app_toast.dart';

class AddMaterialScreen extends StatefulWidget {
  const AddMaterialScreen({super.key});

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  final _materialNameController = TextEditingController();
  final _materialCodeController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _supplierController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Dropdown values
  String? _selectedCategory;
  String? _selectedUnit;
  String? _selectedLocation;

  final List<String> _categories = [
    'Electrical Components',
    'Cables & Wires',
    'Transformers',
    'Poles & Structures',
    'Safety Equipment',
    'Tools & Equipment',
    'Meters & Instruments',
    'Other',
  ];

  final List<String> _units = [
    'Pieces',
    'Meters',
    'Kilograms',
    'Liters',
    'Boxes',
    'Rolls',
    'Sets',
  ];

  final List<String> _locations = [
    'Main Warehouse',
    'Sub Station A',
    'Sub Station B',
    'Field Storage',
    'Office Inventory',
  ];

  @override
  void dispose() {
    _materialNameController.dispose();
    _materialCodeController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _supplierController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitMaterial() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.showError(context, 'Please fill all required fields correctly.');
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

      final materialData = {
        'materialName': _materialNameController.text.trim(),
        'materialCode': _materialCodeController.text.trim(),
        'category': _selectedCategory,
        'quantity': double.parse(_quantityController.text.trim()),
        'unit': _selectedUnit,
        'unitPrice': double.parse(_unitPriceController.text.trim()),
        'totalValue': double.parse(_quantityController.text.trim()) *
            double.parse(_unitPriceController.text.trim()),
        'supplier': _supplierController.text.trim(),
        'location': _selectedLocation,
        'description': _descriptionController.text.trim(),
        'addedBy': user.uid,
        'addedByEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Available',
      };

      await FirebaseFirestore.instance
          .collection('materials')
          .add(materialData);

      if (mounted) {
        AppToast.showSuccess(context, 'Material added successfully! 📦');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(context, e,
            customMessage: 'Failed to add material');
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Add Material',
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
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primaryWithLowOpacity,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_circle_outline_rounded,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Add New Material',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Register new materials to inventory',
                          style: TextStyle(
                            fontSize: 16,
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
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildBasicInfoCard(),
                          const SizedBox(height: 24),
                          _buildQuantityPricingCard(),
                          const SizedBox(height: 24),
                          _buildLocationDetailsCard(),
                          const SizedBox(height: 32),
                          // Submit Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.success,
                                  AppColors.success.withValues(alpha: 0.8)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.success.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _submitMaterial,
                                borderRadius: BorderRadius.circular(16),
                                child: Center(
                                  child: Text(
                                    'ADD MATERIAL',
                                    style: TextStyle(
                                      color: AppColors.textOnDark,
                                      fontSize: 16,
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
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryWithLowOpacity,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildSectionHeader(
                'Basic Information', Icons.info_outline_rounded),
            const SizedBox(height: 8),

            // Material Name
            _buildTextField(
              controller: _materialNameController,
              label: 'Material Name',
              icon: Icons.inventory_2_outlined,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Material name is required' : null,
            ),
            const SizedBox(height: 16),

            // Material Code
            _buildTextField(
              controller: _materialCodeController,
              label: 'Material Code',
              icon: Icons.qr_code_rounded,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Material code is required' : null,
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            _buildDropdown(
              value: _selectedCategory,
              label: 'Category',
              icon: Icons.category_outlined,
              items: _categories,
              onChanged: (value) => setState(() => _selectedCategory = value),
              validator: (value) =>
                  value == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 16),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Description (Optional)',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityPricingCard() {
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildSectionHeader('Quantity & Pricing', Icons.calculate_outlined),
            const SizedBox(height: 8),
            Column(
              children: [
                _buildTextField(
                  controller: _quantityController,
                  label: 'Quantity',
                  icon: Icons.numbers_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Quantity is required';
                    if (double.tryParse(value!) == null)
                      return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  value: _selectedUnit,
                  label: 'Unit',
                  icon: Icons.straighten_rounded,
                  items: _units,
                  onChanged: (value) => setState(() => _selectedUnit = value),
                  validator: (value) =>
                      value == null ? 'Please select unit' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _unitPriceController,
              label: 'Unit Price (₹)',
              icon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Unit price is required';
                if (double.tryParse(value!) == null) return 'Invalid price';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _supplierController,
              label: 'Supplier',
              icon: Icons.business_outlined,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Supplier is required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDetailsCard() {
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildSectionHeader('Storage Location', Icons.location_on_outlined),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _selectedLocation,
              label: 'Storage Location',
              icon: Icons.warehouse_outlined,
              items: _locations,
              onChanged: (value) => setState(() => _selectedLocation = value),
              validator: (value) =>
                  value == null ? 'Please select storage location' : null,
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
    return Container(
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
    );
  }
}

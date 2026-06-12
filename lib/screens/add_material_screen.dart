import 'package:flutter/material.dart';
import '../components/common/app_bar_builder.dart';
import '../components/common/modern_dropdown.dart';
import '../components/common/skeleton_loader.dart';
import '../utils/app_colors.dart';
import '../utils/app_decorations.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../utils/app_toast.dart';
import '../services/approval_service.dart';

class AddMaterialScreen extends StatefulWidget {
  const AddMaterialScreen({super.key});

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApprovalService _approvalService = ApprovalService();
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
        'status': 'Available',
      };

      await _approvalService.submitRequest(
        action: ApprovalAction.addMaterial,
        payload: {
          'materialName': _materialNameController.text.trim(),
          'materialCode': _materialCodeController.text.trim(),
          'requestedQuantity': double.parse(_quantityController.text.trim()),
          'unit': _selectedUnit,
          'materialData': materialData,
        },
      );

      if (mounted) {
        AppToast.showSuccess(
            context, 'Material request submitted for approval.');
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
      appBar: buildAppBar(title: 'Add Material'),
      body: _isLoading
          ? const AddMaterialSkeleton()
          : Column(
              children: [
                // Modern Header Section
                Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                        context.responsivePadding(AppSpacing.xl),
                        context.responsivePadding(AppSpacing.xl),
                        context.responsivePadding(AppSpacing.xl),
                        context.responsivePadding(AppSpacing.xxl)),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
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
                        const SizedBox(height: AppSpacing.base),
                        Text(
                          'Add New Material',
                          style: AppTypography.displayLargeStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Register new materials to inventory',
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
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(
                          context.responsivePadding(AppSpacing.xl)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildBasicInfoCard(),
                          SizedBox(
                              height: context.responsiveSpacing(AppSpacing.xl)),
                          _buildQuantityPricingCard(),
                          SizedBox(
                              height: context.responsiveSpacing(AppSpacing.xl)),
                          _buildLocationDetailsCard(),
                          SizedBox(
                              height:
                                  context.responsiveSpacing(AppSpacing.xxl)),
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
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusDefault),
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
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusDefault),
                                child: Center(
                                  child: Text(
                                    'ADD MATERIAL',
                                    style:
                                        AppTypography.subheadingStyle.copyWith(
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

  Widget _buildBasicInfoCard() {
    return Container(
      decoration: AppDecorations.modernCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            _buildSectionHeader(
                'Basic Information', Icons.info_outline_rounded),
            const SizedBox(height: AppSpacing.sm),

            // Material Name
            _buildTextField(
              controller: _materialNameController,
              label: 'Material Name',
              icon: Icons.inventory_2_outlined,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Material name is required' : null,
            ),
            const SizedBox(height: AppSpacing.base),

            // Material Code
            _buildTextField(
              controller: _materialCodeController,
              label: 'Material Code',
              icon: Icons.qr_code_rounded,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Material code is required' : null,
            ),
            const SizedBox(height: AppSpacing.base),

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
            const SizedBox(height: AppSpacing.base),

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
      decoration: AppDecorations.modernCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            _buildSectionHeader('Quantity & Pricing', Icons.calculate_outlined),
            const SizedBox(height: AppSpacing.sm),
            Column(
              children: [
                _buildTextField(
                  controller: _quantityController,
                  label: 'Quantity',
                  icon: Icons.numbers_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Quantity is required';
                    final quantity = double.tryParse(value!);
                    if (quantity == null) {
                      return 'Invalid number';
                    }
                    if (quantity <= 0) return 'Quantity must be greater than 0';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.base),
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
            const SizedBox(height: AppSpacing.base),
            _buildTextField(
              controller: _unitPriceController,
              label: 'Unit Price (₹)',
              icon: Icons.currency_rupee_rounded,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Unit price is required';
                final price = double.tryParse(value!);
                if (price == null) return 'Invalid price';
                if (price < 0) return 'Price cannot be negative';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.base),
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
      decoration: AppDecorations.modernCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            _buildSectionHeader('Storage Location', Icons.location_on_outlined),
            const SizedBox(height: AppSpacing.sm),
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
    return ModernDropdown<String>(
      value: value,
      label: label,
      prefixIcon: icon,
      fillColor: AppColors.surface,
      validator: validator,
      onChanged: onChanged,
      items: items
          .map(
            (item) => ModernDropdownItem.create<String>(
              value: item,
              text: item,
            ),
          )
          .toList(),
    );
  }
}

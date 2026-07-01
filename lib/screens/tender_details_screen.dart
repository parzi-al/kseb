import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/common/app_bar_builder.dart';
import '../components/common/app_button.dart';
import '../components/common/app_segmented_tabs.dart';
import '../components/common/app_text_field.dart';
import '../components/common/modern_dropdown.dart';
import '../utils/app_colors.dart';
import '../utils/app_decorations.dart';
import '../utils/app_spacing.dart';
import '../utils/app_toast.dart';
import '../utils/app_typography.dart';

class TenderDetailsScreen extends StatefulWidget {
  const TenderDetailsScreen({super.key});

  @override
  State<TenderDetailsScreen> createState() => _TenderDetailsScreenState();
}

class _TenderDetailsScreenState extends State<TenderDetailsScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd MMM yyyy');

  int _selectedTabIndex = 0;
  bool _isExporting = false;

  final _tenderReferenceController = TextEditingController();
  final _tenderTitleController = TextEditingController();
  final _departmentController = TextEditingController();
  final _officeController = TextEditingController();
  final _locationController = TextEditingController();
  final _noticeDateController = TextEditingController();
  final _submissionDeadlineController = TextEditingController();
  final _openingDateController = TextEditingController();
  final _workStartDateController = TextEditingController();
  final _estimateAmountController = TextEditingController();
  final _emdAmountController = TextEditingController();
  final _securityDepositController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _selectedTenderType;
  String? _selectedWorkCategory;

  @override
  void dispose() {
    _tenderReferenceController.dispose();
    _tenderTitleController.dispose();
    _departmentController.dispose();
    _officeController.dispose();
    _locationController.dispose();
    _noticeDateController.dispose();
    _submissionDeadlineController.dispose();
    _openingDateController.dispose();
    _workStartDateController.dispose();
    _estimateAmountController.dispose();
    _emdAmountController.dispose();
    _securityDepositController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  String _textValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? '-' : value;
  }

  String _stringValue(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  List<MapEntry<String, String>> get _previewRows => [
        MapEntry(
            'Tender / Work Reference', _textValue(_tenderReferenceController)),
        MapEntry('Tender Title', _textValue(_tenderTitleController)),
        MapEntry('Tender Type', _stringValue(_selectedTenderType)),
        MapEntry('Work Category', _stringValue(_selectedWorkCategory)),
        MapEntry('Department', _textValue(_departmentController)),
        MapEntry('Office', _textValue(_officeController)),
        MapEntry('Location', _textValue(_locationController)),
        MapEntry('Notice Date', _textValue(_noticeDateController)),
        MapEntry(
            'Submission Deadline', _textValue(_submissionDeadlineController)),
        MapEntry('Bid Opening Date', _textValue(_openingDateController)),
        MapEntry('Work Start Date', _textValue(_workStartDateController)),
        MapEntry('Estimate Amount', _textValue(_estimateAmountController)),
        MapEntry('EMD Amount', _textValue(_emdAmountController)),
        MapEntry('Security Deposit', _textValue(_securityDepositController)),
        MapEntry('Contact Person', _textValue(_contactPersonController)),
        MapEntry('Contact Phone', _textValue(_contactPhoneController)),
        MapEntry('Remarks', _textValue(_remarksController)),
      ];

  Future<void> _pickDate(TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      controller.text = _dateFormat.format(pickedDate);
      setState(() {});
    }
  }

  Future<void> _exportToXlsx() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.showError(context, 'Please fill all required fields correctly.');
      return;
    }

    setState(() => _isExporting = true);

    try {
      final excel = xls.Excel.createExcel();
      final sheet = excel['Tender Details'];

      sheet.appendRow([
        xls.TextCellValue('Tender Details Export'),
      ]);
      sheet.appendRow([
        xls.TextCellValue('Field'),
        xls.TextCellValue('Value'),
      ]);
      for (final row in _previewRows) {
        sheet.appendRow([
          xls.TextCellValue(row.key),
          xls.TextCellValue(row.value),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Unable to generate the workbook.');
      }

      final saveLocation = await getSaveLocation(
        suggestedName: _buildFileName(),
        acceptedTypeGroups: const [
          XTypeGroup(label: 'Excel Workbook', extensions: ['xlsx']),
        ],
      );

      if (saveLocation == null) {
        if (mounted) {
          AppToast.showError(context, 'Export cancelled.');
        }
        return;
      }

      await File(saveLocation.path).writeAsBytes(bytes, flush: true);

      if (mounted) {
        AppToast.showSuccess(context, 'XLSX file saved successfully.');
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          customMessage: 'Failed to export the XLSX file',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _buildFileName() {
    final baseName = _tenderReferenceController.text.trim().isEmpty
        ? 'tender_details'
        : _tenderReferenceController.text.trim();
    final safeName = baseName.replaceAll(RegExp(r'[^a-zA-Z0-9-_]+'), '_');
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    return '${safeName}_$stamp.xlsx';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(title: 'Tender Details'),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildFormTab(),
                _buildPreviewTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.responsivePadding(AppSpacing.xl),
          context.responsivePadding(AppSpacing.xl),
          context.responsivePadding(AppSpacing.xl),
          context.responsivePadding(AppSpacing.xl),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primaryWithLowOpacity,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: AppTypography.iconSizeHero,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Tender Details',
              style: AppTypography.titleStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Fill the form and download it as an Excel workbook.',
              style: AppTypography.bodyStyle.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return AppSegmentedTabs(
      selectedIndex: _selectedTabIndex,
      onChanged: (index) => setState(() => _selectedTabIndex = index),
      tabs: const [
        AppSegmentedTab(icon: Icons.edit_document, label: 'Form'),
        AppSegmentedTab(icon: Icons.preview_outlined, label: 'Preview'),
      ],
    );
  }

  Widget _buildFormTab() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.responsivePadding(AppSpacing.lg)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionCard(
              title: 'Tender Information',
              icon: Icons.assignment_turned_in_outlined,
              children: [
                AppTextField(
                  label: 'Tender / Work Reference *',
                  controller: _tenderReferenceController,
                  prefixIcon:
                      const Icon(Icons.tag_rounded, color: AppColors.primary),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter reference.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.base),
                AppTextField(
                  label: 'Tender Title *',
                  controller: _tenderTitleController,
                  prefixIcon:
                      const Icon(Icons.title_rounded, color: AppColors.primary),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter title.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.base),
                AppTextField(
                  label: 'Department',
                  controller: _departmentController,
                  prefixIcon: const Icon(Icons.account_balance_rounded,
                      color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.base),
                AppTextField(
                  label: 'Office',
                  controller: _officeController,
                  prefixIcon: const Icon(Icons.location_city_rounded,
                      color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.base),
                ModernDropdown<String>(
                  value: _selectedTenderType,
                  label: 'Tender Type',
                  prefixIcon: Icons.category_outlined,
                  items: const [
                    'Open Tender',
                    'Limited Tender',
                    'E-Tender',
                    'Work Order',
                    'Estimate',
                  ]
                      .map(
                        (value) => ModernDropdownItem.create<String>(
                          value: value,
                          text: value,
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedTenderType = value),
                ),
                const SizedBox(height: AppSpacing.base),
                ModernDropdown<String>(
                  value: _selectedWorkCategory,
                  label: 'Work Category',
                  prefixIcon: Icons.construction_rounded,
                  items: const [
                    'Electrical',
                    'Civil',
                    'Electrical + Civil',
                    'Maintenance',
                    'Materials',
                  ]
                      .map(
                        (value) => ModernDropdownItem.create<String>(
                          value: value,
                          text: value,
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedWorkCategory = value),
                ),
                const SizedBox(height: AppSpacing.base),
                AppTextField(
                  label: 'Location / Section',
                  controller: _locationController,
                  prefixIcon: const Icon(Icons.place_outlined,
                      color: AppColors.primary),
                ),
              ],
            ),
            SizedBox(height: context.responsiveSpacing(AppSpacing.xl)),
            _buildSectionCard(
              title: 'Dates & Deadlines',
              icon: Icons.event_available_rounded,
              children: [
                _buildDateField(
                  label: 'Notice Date',
                  controller: _noticeDateController,
                ),
                const SizedBox(height: AppSpacing.base),
                _buildDateField(
                  label: 'Submission Deadline',
                  controller: _submissionDeadlineController,
                ),
                const SizedBox(height: AppSpacing.base),
                _buildDateField(
                  label: 'Bid Opening Date',
                  controller: _openingDateController,
                ),
                const SizedBox(height: AppSpacing.base),
                _buildDateField(
                  label: 'Work Start Date',
                  controller: _workStartDateController,
                ),
              ],
            ),
            SizedBox(height: context.responsiveSpacing(AppSpacing.xl)),
            _buildSectionCard(
              title: 'Financial Details',
              icon: Icons.payments_outlined,
              children: [
                AppTextField(
                  label: 'Estimate Amount',
                  controller: _estimateAmountController,
                  prefixIcon: const Icon(Icons.currency_rupee_rounded,
                      color: AppColors.primary),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.base),
                AppTextField(
                  label: 'EMD Amount',
                  controller: _emdAmountController,
                  prefixIcon: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.primary),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.base),
                AppTextField(
                  label: 'Security Deposit',
                  controller: _securityDepositController,
                  prefixIcon: const Icon(Icons.security_rounded,
                      color: AppColors.primary),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            SizedBox(height: context.responsiveSpacing(AppSpacing.xl)),
            _buildSectionCard(
              title: 'Contact & Notes',
              icon: Icons.contact_mail_outlined,
              children: [
                AppTextField(
                  label: 'Contact Person',
                  controller: _contactPersonController,
                  prefixIcon: const Icon(Icons.person_outline_rounded,
                      color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.base),
                AppTextField(
                  label: 'Contact Phone',
                  controller: _contactPhoneController,
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: AppColors.primary),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.base),
                AppTextField(
                  label: 'Remarks',
                  controller: _remarksController,
                  prefixIcon:
                      const Icon(Icons.notes_rounded, color: AppColors.primary),
                  maxLines: 4,
                ),
              ],
            ),
            SizedBox(height: context.responsiveSpacing(AppSpacing.xxl)),
            AppButton(
              label: _isExporting ? 'Generating XLSX...' : 'Download XLSX',
              icon: Icons.download_rounded,
              isLoading: _isExporting,
              onPressed: _isExporting ? null : _exportToXlsx,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTab() {
    return ListView(
      padding: EdgeInsets.all(context.responsivePadding(AppSpacing.lg)),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: AppDecorations.modernCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Workbook Preview', style: AppTypography.subheadingStyle),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'These rows will be written to the exported XLSX file.',
                style: AppTypography.bodyStyle.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        ..._previewRows.map(
          (row) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.base),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: AppDecorations.modernCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.key,
                  style: AppTypography.captionStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(row.value, style: AppTypography.bodyStyle),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.base),
        AppButton(
          label: 'Download XLSX',
          icon: Icons.download_rounded,
          isLoading: _isExporting,
          onPressed: _isExporting ? null : _exportToXlsx,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: AppDecorations.modernCardDecoration,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryWithLowOpacity,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.base),
              Text(title, style: AppTypography.subheadingStyle),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
  }) {
    return InkWell(
      onTap: () => _pickDate(controller),
      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      child: AbsorbPointer(
        child: AppTextField(
          label: label,
          controller: controller,
          hintText: 'Select date',
          prefixIcon: const Icon(Icons.event_rounded, color: AppColors.primary),
          suffixIcon: const Icon(Icons.calendar_today_rounded,
              color: AppColors.primary),
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../components/common/app_bar_builder.dart';
import '../components/common/app_button.dart';
import '../components/common/app_segmented_tabs.dart';
import '../components/common/app_text_field.dart';
import '../components/common/modern_dropdown.dart';
import '../components/common/shell_bottom_nav.dart';
import '../utils/app_colors.dart';
import '../utils/app_decorations.dart';
import '../utils/generated_file_actions.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd MMM yyyy');
  final _compareHorizontalScrollController = ScrollController();

  int _selectedTabIndex = 0;
  bool _isSubmitting = false;
  bool _isExporting = false;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  int _comparePage = 0;
  static const int _comparePageSize = 10;
  final Set<int> _visibleCompareColumns = {0, 1, 2, 3, 4, 5, 6, 7, 8};
  String? _editingTenderId;

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
    _compareHorizontalScrollController.dispose();
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

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = _selectedTabIndex.clamp(0, 1);
  }

  String _textValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? '-' : value;
  }

  String _stringValue(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  Map<String, String> get _currentTenderData => {
        'reference': _textValue(_tenderReferenceController),
        'title': _textValue(_tenderTitleController),
        'tenderType': _stringValue(_selectedTenderType),
        'workCategory': _stringValue(_selectedWorkCategory),
        'department': _textValue(_departmentController),
        'office': _textValue(_officeController),
        'location': _textValue(_locationController),
        'noticeDate': _textValue(_noticeDateController),
        'submissionDeadline': _textValue(_submissionDeadlineController),
        'openingDate': _textValue(_openingDateController),
        'workStartDate': _textValue(_workStartDateController),
        'estimateAmount': _textValue(_estimateAmountController),
        'emdAmount': _textValue(_emdAmountController),
        'securityDeposit': _textValue(_securityDepositController),
        'contactPerson': _textValue(_contactPersonController),
        'contactPhone': _textValue(_contactPhoneController),
        'remarks': _textValue(_remarksController),
      };

  List<MapEntry<String, String>> _rowsFromTenderData(
    Map<String, dynamic> data,
  ) =>
      [
        MapEntry(
          'Tender / Work Reference',
          _stringValue(data['reference']?.toString()),
        ),
        MapEntry('Tender Title', _stringValue(data['title']?.toString())),
        MapEntry('Tender Type', _stringValue(data['tenderType']?.toString())),
        MapEntry(
          'Work Category',
          _stringValue(data['workCategory']?.toString()),
        ),
        MapEntry('Department', _stringValue(data['department']?.toString())),
        MapEntry('Office', _stringValue(data['office']?.toString())),
        MapEntry('Location', _stringValue(data['location']?.toString())),
        MapEntry('Notice Date', _stringValue(data['noticeDate']?.toString())),
        MapEntry(
          'Submission Deadline',
          _stringValue(data['submissionDeadline']?.toString()),
        ),
        MapEntry(
          'Bid Opening Date',
          _stringValue(data['openingDate']?.toString()),
        ),
        MapEntry(
          'Work Start Date',
          _stringValue(data['workStartDate']?.toString()),
        ),
        MapEntry(
          'Estimate Amount',
          _stringValue(data['estimateAmount']?.toString()),
        ),
        MapEntry('EMD Amount', _stringValue(data['emdAmount']?.toString())),
        MapEntry(
          'Security Deposit',
          _stringValue(data['securityDeposit']?.toString()),
        ),
        MapEntry(
          'Contact Person',
          _stringValue(data['contactPerson']?.toString()),
        ),
        MapEntry(
          'Contact Phone',
          _stringValue(data['contactPhone']?.toString()),
        ),
        MapEntry('Remarks', _stringValue(data['remarks']?.toString())),
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

  Future<void> _submitTender() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.showError(context, 'Please fill all required fields correctly.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in.');
      }

      final tendersRef = FirebaseFirestore.instance
          .collection('user_tenders')
          .doc(user.uid)
          .collection('tenders');

      if (_editingTenderId == null) {
        await tendersRef.add({
          ..._currentTenderData,
          'ownerId': user.uid,
          'ownerEmail': user.email,
          'submittedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await tendersRef.doc(_editingTenderId).update({
          ..._currentTenderData,
          'ownerEmail': user.email,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        AppToast.showSuccess(
          context,
          _editingTenderId == null
              ? 'Tender submitted successfully.'
              : 'Tender updated successfully.',
        );
        setState(() => _selectedTabIndex = 1);
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          customMessage: 'Failed to submit tender',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _loadTenderForEdit(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    BuildContext? closeContext,
  }) {
    if (closeContext != null) {
      Navigator.of(closeContext).pop();
    }

    final data = doc.data();
    setState(() {
      _editingTenderId = doc.id;
      _selectedTabIndex = 0;
      _tenderReferenceController.text =
          _stringValue(data['reference']?.toString());
      _tenderTitleController.text = _stringValue(data['title']?.toString());
      _departmentController.text = _stringValue(data['department']?.toString());
      _officeController.text = _stringValue(data['office']?.toString());
      _locationController.text = _stringValue(data['location']?.toString());
      _noticeDateController.text = _stringValue(data['noticeDate']?.toString());
      _submissionDeadlineController.text =
          _stringValue(data['submissionDeadline']?.toString());
      _openingDateController.text =
          _stringValue(data['openingDate']?.toString());
      _workStartDateController.text =
          _stringValue(data['workStartDate']?.toString());
      _estimateAmountController.text =
          _stringValue(data['estimateAmount']?.toString());
      _emdAmountController.text = _stringValue(data['emdAmount']?.toString());
      _securityDepositController.text =
          _stringValue(data['securityDeposit']?.toString());
      _contactPersonController.text =
          _stringValue(data['contactPerson']?.toString());
      _contactPhoneController.text =
          _stringValue(data['contactPhone']?.toString());
      _remarksController.text = _stringValue(data['remarks']?.toString());
      _selectedTenderType = _nullableTenderValue(data['tenderType']);
      _selectedWorkCategory = _nullableTenderValue(data['workCategory']);
    });
  }

  String? _nullableTenderValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text == '-' ? null : text;
  }

  void _clearTenderForm() {
    setState(() {
      _editingTenderId = null;
      _tenderReferenceController.clear();
      _tenderTitleController.clear();
      _departmentController.clear();
      _officeController.clear();
      _locationController.clear();
      _noticeDateController.clear();
      _submissionDeadlineController.clear();
      _openingDateController.clear();
      _workStartDateController.clear();
      _estimateAmountController.clear();
      _emdAmountController.clear();
      _securityDepositController.clear();
      _contactPersonController.clear();
      _contactPhoneController.clear();
      _remarksController.clear();
      _selectedTenderType = null;
      _selectedWorkCategory = null;
    });
  }

  Future<void> _exportTenderToXlsx(Map<String, dynamic> data) async {
    setState(() => _isExporting = true);

    try {
      final excel = xls.Excel.createExcel();
      final sheet = excel['Tender Details'];
      final fileName = _buildTenderFileName(data, 'xlsx');

      sheet.appendRow([
        xls.TextCellValue('Tender Details Export'),
      ]);
      sheet.appendRow([
        xls.TextCellValue('Field'),
        xls.TextCellValue('Value'),
      ]);
      for (final row in _rowsFromTenderData(data)) {
        sheet.appendRow([
          xls.TextCellValue(row.key),
          xls.TextCellValue(row.value),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Unable to generate the workbook.');
      }

      final exported = await GeneratedFileActions.saveOrShowActions(
        context: context,
        bytes: Uint8List.fromList(bytes),
        fileName: fileName,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        typeGroup: const XTypeGroup(
          label: 'Excel Workbook',
          extensions: ['xlsx'],
        ),
        title: 'Tender XLSX ready',
      );

      if (mounted && exported) {
        AppToast.showSuccess(
          context,
          'Tender XLSX downloaded successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          customMessage: 'Failed to export the tender XLSX file',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportTenderToPdf(Map<String, dynamic> data) async {
    setState(() => _isExporting = true);

    try {
      final fileName = _buildTenderFileName(data, 'pdf');
      final pdf = pw.Document(theme: await _buildPdfTheme());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text(
              'Tender Details',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 24),
            pw.TableHelper.fromTextArray(
              headers: const ['Field', 'Value'],
              data: _rowsFromTenderData(data)
                  .map((row) => <String>[row.key, row.value])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(8),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      if (!mounted) return;

      final exported = await GeneratedFileActions.saveOrShowActions(
        context: context,
        bytes: bytes,
        fileName: fileName,
        mimeType: 'application/pdf',
        typeGroup: const XTypeGroup(
          label: 'PDF Document',
          extensions: ['pdf'],
        ),
        title: 'Tender PDF ready',
      );

      if (mounted && exported) {
        AppToast.showSuccess(
          context,
          'Tender PDF downloaded successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          customMessage: 'Failed to export the tender PDF file',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<pw.ThemeData> _buildPdfTheme() async {
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    return pw.ThemeData.withFont(
      base: baseFont,
      bold: boldFont,
      fontFallback: [baseFont],
    );
  }

  String _buildTenderFileName(Map<String, dynamic> data, String extension) {
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final reference = _stringValue(data['reference']?.toString())
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    final suffix = reference == '-' ? timestamp : '${reference}_$timestamp';
    return 'TenderDetails_$suffix.$extension';
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _tenderStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return FirebaseFirestore.instance
        .collection('user_tenders')
        .doc(user.uid)
        .collection('tenders')
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortedTenderDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final sorted = [...docs];
    sorted.sort((a, b) {
      final result = _compareTenderField(
        a.data(),
        b.data(),
        _sortColumnIndex,
      );
      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  int _compareTenderField(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
    int columnIndex,
  ) {
    if (columnIndex == 7 || columnIndex == 8) {
      return _numberValue(left, columnIndex)
          .compareTo(_numberValue(right, columnIndex));
    }

    return _tableValue(left, columnIndex)
        .toLowerCase()
        .compareTo(_tableValue(right, columnIndex).toLowerCase());
  }

  num _numberValue(Map<String, dynamic> data, int columnIndex) {
    final text = _tableValue(data, columnIndex).replaceAll(',', '');
    return num.tryParse(text) ?? 0;
  }

  String _tableValue(Map<String, dynamic> data, int columnIndex) {
    return switch (columnIndex) {
      0 => _stringValue(data['reference']?.toString()),
      1 => _stringValue(data['title']?.toString()),
      2 => _stringValue(data['tenderType']?.toString()),
      3 => _stringValue(data['workCategory']?.toString()),
      4 => _stringValue(data['office']?.toString()),
      5 => _stringValue(data['location']?.toString()),
      6 => _stringValue(data['submissionDeadline']?.toString()),
      7 => _stringValue(data['estimateAmount']?.toString()),
      8 => _stringValue(data['emdAmount']?.toString()),
      _ => '',
    };
  }

  String _sortColumnLabel(int columnIndex) {
    return switch (columnIndex) {
      0 => 'Reference',
      1 => 'Title',
      2 => 'Type',
      3 => 'Category',
      4 => 'Office',
      5 => 'Location',
      6 => 'Submission Date',
      7 => 'Bid Amount',
      8 => 'EMD',
      _ => 'Reference',
    };
  }

  void _sortTenderTable(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _comparePage = 0;
    });
  }

  void _toggleCompareColumn(int columnIndex, bool visible) {
    setState(() {
      if (visible) {
        _visibleCompareColumns.add(columnIndex);
      } else if (_visibleCompareColumns.length > 1) {
        _visibleCompareColumns.remove(columnIndex);
      }
    });
  }

  List<int> get _visibleCompareColumnIndexes {
    return List.generate(9, (index) => index)
        .where(_visibleCompareColumns.contains)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: buildAppBar(
        title: 'Tender Details',
      ),
      bottomNavigationBar: const ShellBottomNav(),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 1100) {
                  return _buildWideTenderWorkspace();
                }

                return Column(
                  children: [
                    _buildTabs(),
                    Expanded(
                      child: IndexedStack(
                        index: _selectedTabIndex,
                        children: [
                          _buildFormTab(),
                          _buildListTab(),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return AppSegmentedTabs(
      selectedIndex: _selectedTabIndex,
      onChanged: (index) => setState(() => _selectedTabIndex = index),
      tabs: const [
        AppSegmentedTab(icon: Icons.edit_document, label: 'Form'),
        AppSegmentedTab(icon: Icons.view_list_rounded, label: 'List'),
      ],
    );
  }

  Widget _buildWideTenderWorkspace() {
    return Padding(
      padding: EdgeInsets.all(context.responsivePadding(AppSpacing.lg)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: _buildWorkspacePanel(
              title: 'Tender Form',
              icon: Icons.edit_document,
              child: _buildFormTab(includeOuterPadding: false),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            flex: 6,
            child: _buildWorkspacePanel(
              title: 'Tender List',
              icon: Icons.view_list_rounded,
              child: _buildListTab(includeOuterPadding: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspacePanel({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      height: double.infinity,
      decoration: AppDecorations.modernCardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: AppTypography.subheadingStyle),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildFormTab({bool includeOuterPadding = true}) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: includeOuterPadding
            ? EdgeInsets.all(context.responsivePadding(AppSpacing.lg))
            : const EdgeInsets.all(AppSpacing.lg),
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
              label: _isSubmitting
                  ? (_editingTenderId == null ? 'Submitting...' : 'Updating...')
                  : (_editingTenderId == null
                      ? 'Submit Tender'
                      : 'Update Tender'),
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submitTender,
            ),
            if (_editingTenderId != null) ...[
              const SizedBox(height: AppSpacing.base),
              AppButton(
                label: 'Cancel edit',
                icon: Icons.close_rounded,
                variant: AppButtonVariant.outline,
                onPressed: _clearTenderForm,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildListTab({bool includeOuterPadding = true}) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _tenderStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _buildPanelMessage(
            'Unable to load submitted tenders: ${snapshot.error}',
          );
        }

        final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[
          ...snapshot.data?.docs ??
              const <QueryDocumentSnapshot<Map<String, dynamic>>>[],
        ];
        final tenders = _sortedTenderDocs(docs);
        if (tenders.isEmpty) {
          return _buildPanelMessage(
            'No submitted tenders yet. Submit the form to list records.',
          );
        }

        final groupedTenders = _groupTendersByProject(tenders);

        return ListView(
          padding: includeOuterPadding
              ? EdgeInsets.all(context.responsivePadding(AppSpacing.lg))
              : const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Reference-wise Tenders',
                style: AppTypography.subheadingStyle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Open a project to compare its tenders. Use the pen icon to edit and the download icons for individual tender files.',
              style: AppTypography.bodyStyle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...groupedTenders.entries.map(
              (entry) => _buildProjectTenderCard(entry.key, entry.value),
            ),
          ],
        );
      },
    );
  }

  Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _groupTendersByProject(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> tenders,
  ) {
    final grouped =
        <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final tender in tenders) {
      final key = _projectKey(tender.data());
      grouped.putIfAbsent(key, () => []).add(tender);
    }
    return grouped;
  }

  String _projectKey(Map<String, dynamic> data) {
    final reference = _stringValue(data['reference']?.toString());
    if (reference != '-') return reference;
    final category = _stringValue(data['workCategory']?.toString());
    if (category != '-') return category;
    return 'Unassigned Reference';
  }

  Widget _buildProjectTenderCard(
    String projectName,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> tenders,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.modernCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(projectName, style: AppTypography.subheadingStyle),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${tenders.length} tender${tenders.length == 1 ? '' : 's'}',
                    style: AppTypography.captionStyle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
              final compareButton = TextButton.icon(
                onPressed: () {
                  _openProjectCompareDialog(projectName, tenders);
                },
                icon: const Icon(Icons.compare_arrows_rounded),
                label: const Text('Compare'),
              );

              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: compareButton,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: title),
                  compareButton,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.base),
          ...tenders.map(_buildTenderActionTile),
        ],
      ),
    );
  }

  Widget _buildTenderActionTile(
    QueryDocumentSnapshot<Map<String, dynamic>> tender,
  ) {
    final data = tender.data();
    final details = [
      _stringValue(data['tenderType']?.toString()),
      'Bid: ${_stringValue(data['estimateAmount']?.toString())}',
      'Start: ${_stringValue(data['workStartDate']?.toString())}',
      'Submit: ${_stringValue(data['submissionDeadline']?.toString())}',
      _stringValue(data['office']?.toString()),
    ].where((value) => value != '-').join(' - ');

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 430;
          final detailsColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _stringValue(data['title']?.toString()),
                style: AppTypography.bodyMediumStyle,
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  details,
                  style: AppTypography.captionStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          );
          final actions = _buildTenderActionButtons(tender, data);

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                detailsColumn,
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: actions,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: detailsColumn),
              const SizedBox(width: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                children: actions,
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildTenderActionButtons(
    QueryDocumentSnapshot<Map<String, dynamic>> tender,
    Map<String, dynamic> data,
  ) {
    return [
      _buildCompactTenderAction(
        tooltip: 'View tender details',
        icon: Icons.visibility_outlined,
        onPressed: () => _showTenderDetails(data),
      ),
      _buildCompactTenderAction(
        tooltip: 'Edit tender',
        icon: Icons.edit_rounded,
        onPressed: () => _loadTenderForEdit(tender),
      ),
      _buildCompactTenderAction(
        tooltip: 'Download PDF',
        icon: Icons.picture_as_pdf_rounded,
        onPressed: _isExporting ? null : () => _exportTenderToPdf(data),
      ),
      _buildCompactTenderAction(
        tooltip: 'Download XLSX',
        icon: Icons.table_chart_outlined,
        onPressed: _isExporting ? null : () => _exportTenderToXlsx(data),
      ),
    ];
  }

  Widget _buildCompactTenderAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      iconSize: 20,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.primaryWithLowOpacity,
        disabledForegroundColor: AppColors.textSecondary,
      ),
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }

  void _showTenderDetails(Map<String, dynamic> data) {
    final rows = _rowsFromTenderData(data);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.42,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  _stringValue(data['title']?.toString()),
                  style: AppTypography.titleStyle,
                ),
                const SizedBox(height: AppSpacing.base),
                ...rows.map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.base),
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
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isExporting
                            ? null
                            : () => _exportTenderToPdf(data),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: const Text('Download PDF'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isExporting
                            ? null
                            : () => _exportTenderToXlsx(data),
                        icon: const Icon(Icons.table_chart_outlined),
                        label: const Text('Download XLSX'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openProjectCompareDialog(
    String projectName,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> tenders,
  ) {
    setState(() => _comparePage = 0);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final sortedTenders = _sortedTenderDocs(tenders);
            void refreshDialog() => setDialogState(() {});

            return Dialog(
              insetPadding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1100,
                  maxHeight: 720,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.compare_arrows_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.base),
                          Expanded(
                            child: Text(
                              'Compare: $projectName',
                              style: AppTypography.subheadingStyle,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Close',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: _buildTenderTable(
                          sortedTenders,
                          closeContext: dialogContext,
                          onTableChanged: refreshDialog,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCompareTableHeader(VoidCallback onTableChanged) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.base,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 240,
                child: ModernDropdown<int>(
                  value: _sortColumnIndex,
                  label: 'Sort by',
                  prefixIcon: Icons.sort_rounded,
                  items: List.generate(
                    9,
                    (index) => ModernDropdownItem.create<int>(
                      value: index,
                      text: _sortColumnLabel(index),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;
                    _sortTenderTable(value, _sortAscending);
                    onTableChanged();
                  },
                ),
              ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    icon: Icon(Icons.arrow_upward_rounded),
                    label: Text('Ascending'),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    icon: Icon(Icons.arrow_downward_rounded),
                    label: Text('Descending'),
                  ),
                ],
                selected: {_sortAscending},
                onSelectionChanged: (selection) {
                  _sortTenderTable(_sortColumnIndex, selection.first);
                  onTableChanged();
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Columns',
                style: AppTypography.captionStyle.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ...List.generate(
                9,
                (index) => _buildCompareColumnCheckbox(
                  index,
                  onTableChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompareColumnCheckbox(
    int columnIndex,
    VoidCallback onTableChanged,
  ) {
    final selected = _visibleCompareColumns.contains(columnIndex);
    final canUncheck = selected && _visibleCompareColumns.length > 1;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      onTap: () {
        if (!selected || canUncheck) {
          _toggleCompareColumn(columnIndex, !selected);
          onTableChanged();
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: selected,
              activeColor: AppColors.primary,
              onChanged: !selected || canUncheck
                  ? (value) {
                      _toggleCompareColumn(columnIndex, value ?? false);
                      onTableChanged();
                    }
                  : null,
            ),
            Text(
              _sortColumnLabel(columnIndex),
              style: AppTypography.captionStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTenderTable(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> tenders, {
    BuildContext? closeContext,
    VoidCallback? onTableChanged,
  }) {
    final visibleColumns = _visibleCompareColumnIndexes;
    final displayedSortColumnIndex = visibleColumns.indexOf(_sortColumnIndex);
    final totalPages = (tenders.length / _comparePageSize).ceil();
    final page = _comparePage.clamp(0, totalPages - 1);
    final startIndex = page * _comparePageSize;
    final endIndex = (startIndex + _comparePageSize).clamp(
      0,
      tenders.length,
    );
    final visibleTenders = tenders.sublist(startIndex, endIndex);

    if (page != _comparePage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _comparePage = page);
        }
      });
    }

    return Container(
      decoration: AppDecorations.modernCardDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildCompareTableHeader(onTableChanged ?? () {}),
          const Divider(height: 1),
          Scrollbar(
            controller: _compareHorizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _compareHorizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortColumnIndex: displayedSortColumnIndex == -1
                    ? null
                    : displayedSortColumnIndex,
                sortAscending: _sortAscending,
                showCheckboxColumn: false,
                columnSpacing: AppSpacing.lg,
                columns: [
                  ...visibleColumns.map(
                    (index) => _buildDataColumn(
                      _sortColumnLabel(index),
                      index,
                      onTableChanged,
                    ),
                  ),
                  const DataColumn(label: Text('Actions')),
                ],
                rows: visibleTenders.map((doc) {
                  final data = doc.data();
                  return DataRow(
                    onSelectChanged: null,
                    cells: [
                      ...visibleColumns.map(
                        (index) => DataCell(
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: index == 1 ? 220 : 120,
                              maxWidth: index == 1 ? 320 : 180,
                            ),
                            child: Text(
                              _tableValue(data, index),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_rounded,
                                  color: AppColors.primary),
                              onPressed: () => _loadTenderForEdit(
                                doc,
                                closeContext: closeContext,
                              ),
                            ),
                            IconButton(
                              tooltip: 'PDF',
                              icon: const Icon(Icons.picture_as_pdf_rounded,
                                  color: AppColors.primary),
                              onPressed: _isExporting
                                  ? null
                                  : () => _exportTenderToPdf(data),
                            ),
                            IconButton(
                              tooltip: 'XLSX',
                              icon: const Icon(Icons.table_chart_outlined,
                                  color: AppColors.primary),
                              onPressed: _isExporting
                                  ? null
                                  : () => _exportTenderToXlsx(data),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Showing ${startIndex + 1}-$endIndex of ${tenders.length}',
                    style: AppTypography.captionStyle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: page == 0
                      ? null
                      : () => setState(() => _comparePage = page - 1),
                  child: const Text('Previous'),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: page >= totalPages - 1
                      ? null
                      : () => setState(() => _comparePage = page + 1),
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataColumn _buildDataColumn(
    String label,
    int index,
    VoidCallback? onSortChanged,
  ) {
    return DataColumn(
      label: Text(label),
      onSort: (columnIndex, ascending) {
        _sortTenderTable(columnIndex, ascending);
        onSortChanged?.call();
      },
    );
  }

  Widget _buildPanelMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodyStyle.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
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

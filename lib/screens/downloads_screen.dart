import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as xls;
import 'package:file_selector/file_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../components/common/app_bar_builder.dart';
import '../components/common/app_button.dart';
import '../components/common/modern_dropdown.dart';
import '../components/common/shell_bottom_nav.dart';
import '../models/user_model.dart';
import '../services/approval_service.dart';
import '../services/user_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_decorations.dart';
import '../utils/app_spacing.dart';
import '../utils/app_toast.dart';
import '../utils/app_typography.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  String? _activeExport;

  bool get _isExporting => _activeExport != null;
  bool _isActiveExport(String exportKey) => _activeExport == exportKey;

  static const _allStatuses = 'All statuses';
  static const _allProjects = 'All projects';
  static const _allOffices = 'All offices';
  static const _allEmployees = 'All employees';

  final UserService _userService = UserService();

  String _value(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  int _timestampMillis(Map<String, dynamic> data, String field) {
    final timestamp = data[field];
    if (timestamp is Timestamp) {
      return timestamp.toDate().millisecondsSinceEpoch;
    }
    return 0;
  }

  bool _isInDateRange(
    Map<String, dynamic> data,
    String field,
    DateTimeRange? range,
  ) {
    if (range == null) return true;
    final timestamp = data[field];
    if (timestamp is! Timestamp) return false;

    final value = timestamp.toDate();
    final start =
        DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );
    return !value.isBefore(start) && !value.isAfter(end);
  }

  String _rangeLabel(DateTimeRange? range) {
    if (range == null) return 'Any time';
    return '${DateFormat('dd MMM yyyy').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}';
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _fetchSubmittedTenders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in.');

    final snapshot = await FirebaseFirestore.instance
        .collection('user_tenders')
        .doc(user.uid)
        .collection('tenders')
        .get();
    final docs = snapshot.docs;
    docs.sort((a, b) => _timestampMillis(b.data(), 'submittedAt')
        .compareTo(_timestampMillis(a.data(), 'submittedAt')));
    return docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _fetchWorksheetRequests(UserModel currentUser) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in.');

    QuerySnapshot<Map<String, dynamic>> snapshot;
    if (currentUser.role.isSupervisor) {
      snapshot = await FirebaseFirestore.instance
          .collection('worksheet_requests')
          .where('action', isEqualTo: ApprovalAction.worksheet.value)
          .get();
    } else {
      snapshot = await FirebaseFirestore.instance
          .collection('worksheet_requests')
          .where('action', isEqualTo: ApprovalAction.worksheet.value)
          .where('requestedBy', isEqualTo: user.uid)
          .get();
    }

    final docs = snapshot.docs.where((doc) {
      final data = doc.data();
      if (data['requestedBy'] == user.uid) return true;
      if (currentUser.role == UserRole.director) return true;

      final requesterRole = UserRole.fromString(
        data['requestedByRole']?.toString() ?? 'staff',
      );
      return currentUser.role.canApproveRequestFrom(requesterRole);
    }).toList();

    docs.sort((a, b) => _timestampMillis(b.data(), 'requestTimestamp')
        .compareTo(_timestampMillis(a.data(), 'requestTimestamp')));
    return docs;
  }

  Future<UserModel> _fetchCurrentUserModel() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw Exception('User not logged in.');
    }

    final userModel = await _userService.getUserByEmail(email);
    if (userModel == null) {
      throw Exception('Current user profile was not found.');
    }
    return userModel;
  }

  List<MapEntry<String, String>> _tenderRows(Map<String, dynamic> data) => [
        MapEntry('Tender / Work Reference', _value(data['reference'])),
        MapEntry('Tender Title', _value(data['title'])),
        MapEntry('Tender Type', _value(data['tenderType'])),
        MapEntry('Work Category', _value(data['workCategory'])),
        MapEntry('Department', _value(data['department'])),
        MapEntry('Office', _value(data['office'])),
        MapEntry('Location', _value(data['location'])),
        MapEntry('Notice Date', _value(data['noticeDate'])),
        MapEntry('Submission Deadline', _value(data['submissionDeadline'])),
        MapEntry('Bid Opening Date', _value(data['openingDate'])),
        MapEntry('Work Start Date', _value(data['workStartDate'])),
        MapEntry('Estimate Amount', _value(data['estimateAmount'])),
        MapEntry('EMD Amount', _value(data['emdAmount'])),
        MapEntry('Security Deposit', _value(data['securityDeposit'])),
        MapEntry('Contact Person', _value(data['contactPerson'])),
        MapEntry('Contact Phone', _value(data['contactPhone'])),
        MapEntry('Remarks', _value(data['remarks'])),
      ];

  List<MapEntry<String, String>> _worksheetRows(Map<String, dynamic> data) {
    final worksheetData =
        Map<String, dynamic>.from(data['worksheetData'] ?? {});
    final worksheetType =
        _value(data['worksheetType'] ?? worksheetData['workType']);

    return [
      MapEntry('Worksheet Title', _value(data['worksheetTitle'])),
      MapEntry('Worksheet Type', worksheetType),
      MapEntry('Office', _value(worksheetData['office'])),
      if (worksheetType == 'Project') ...[
        MapEntry('Project', _value(worksheetData['projectSelection'])),
        MapEntry('Project Name', _value(worksheetData['projectName'])),
      ],
      MapEntry('Permit Book', _value(worksheetData['permitBook'])),
      MapEntry('Location', _value(worksheetData['location'])),
      MapEntry('Notes', _value(worksheetData['moreInfo'])),
      MapEntry('Requested By', _value(data['requestedByName'])),
      MapEntry('Requester Email', _value(data['requestedByEmail'])),
      MapEntry('Status', _value(data['status'])),
      if (data['requestTimestamp'] is Timestamp)
        MapEntry(
          'Submitted At',
          DateFormat('dd MMM yyyy, hh:mm a')
              .format((data['requestTimestamp'] as Timestamp).toDate()),
        ),
    ];
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterWorksheets(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    _WorksheetExportFilters filters,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      final worksheetData =
          Map<String, dynamic>.from(data['worksheetData'] ?? {});
      final statusMatches = filters.status == _allStatuses ||
          _value(data['status']).toLowerCase() == filters.status.toLowerCase();
      final officeMatches = filters.office == _allOffices ||
          _value(worksheetData['office']) == filters.office;
      final employeeMatches = filters.employeeId == null ||
          filters.employeeId == _allEmployees ||
          data['requestedBy'] == filters.employeeId;
      return statusMatches &&
          officeMatches &&
          employeeMatches &&
          _isInDateRange(data, 'requestTimestamp', filters.dateRange);
    }).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterTenders(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    _TenderExportFilters filters,
  ) {
    return docs.where((doc) {
      final data = doc.data();
      final projectMatches = filters.project == _allProjects ||
          _value(data['reference']) == filters.project;
      return projectMatches &&
          _isInDateRange(data, 'submittedAt', filters.dateRange);
    }).toList();
  }

  List<String> _tenderProjectOptions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final projects = docs
        .map((doc) => _value(doc.data()['reference']))
        .where((project) => project != '-')
        .toSet()
        .toList()
      ..sort();
    return [_allProjects, ...projects];
  }

  List<String> _worksheetOfficeOptions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final offices = docs
        .map((doc) {
          final worksheetData =
              Map<String, dynamic>.from(doc.data()['worksheetData'] ?? {});
          return _value(worksheetData['office']);
        })
        .where((office) => office != '-')
        .toSet()
        .toList()
      ..sort();
    return [_allOffices, ...offices];
  }

  List<_EmployeeOption> _worksheetEmployeeOptions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final optionsById = <String, _EmployeeOption>{};
    for (final doc in docs) {
      final data = doc.data();
      final id = data['requestedBy']?.toString();
      if (id == null || id.trim().isEmpty) continue;
      optionsById[id] = _EmployeeOption(
        id: id,
        name: _value(data['requestedByName']),
        email: _value(data['requestedByEmail']),
        role: _value(data['requestedByRole']),
      );
    }

    final options = optionsById.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return [
      const _EmployeeOption(
        id: _allEmployees,
        name: _allEmployees,
        email: '',
        role: '',
      ),
      ...options,
    ];
  }

  Widget _buildFilterSummary({
    required int matchingCount,
    required int totalCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.primaryWithLowOpacity,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(Icons.summarize_rounded, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$matchingCount of $totalCount records will be exported',
              style: AppTypography.bodyMediumStyle.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<_WorksheetExportFilters?> _showWorksheetExportDialog(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> worksheets,
    UserModel currentUser,
  ) {
    final officeOptions = _worksheetOfficeOptions(worksheets);
    final employeeOptions = currentUser.role == UserRole.director
        ? _worksheetEmployeeOptions(worksheets)
        : const <_EmployeeOption>[];
    var selectedStatus = _allStatuses;
    var selectedOffice = _allOffices;
    String? selectedEmployeeId =
        currentUser.role == UserRole.director ? _allEmployees : null;
    DateTimeRange? selectedRange;

    return showDialog<_WorksheetExportFilters>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentFilters = _WorksheetExportFilters(
              status: selectedStatus,
              office: selectedOffice,
              employeeId: selectedEmployeeId,
              dateRange: selectedRange,
            );
            final matchingCount =
                _filterWorksheets(worksheets, currentFilters).length;

            return AlertDialog(
              title: const Text('Worksheet Export Options'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ModernDropdown<String>(
                      value: selectedStatus,
                      label: 'Status',
                      prefixIcon: Icons.fact_check_outlined,
                      items: const [
                        _allStatuses,
                        'Pending',
                        'Approved',
                        'Rejected',
                      ]
                          .map(
                            (status) => ModernDropdownItem.create<String>(
                              value: status,
                              text: status,
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedStatus = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.base),
                    ModernDropdown<String>(
                      value: selectedOffice,
                      label: 'Office',
                      prefixIcon: Icons.location_city_rounded,
                      items: officeOptions
                          .map(
                            (office) => ModernDropdownItem.create<String>(
                              value: office,
                              text: office,
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedOffice = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.base),
                    if (currentUser.role == UserRole.director) ...[
                      ModernDropdown<String>(
                        value: selectedEmployeeId,
                        label: 'Employee',
                        prefixIcon: Icons.person_search_rounded,
                        items: employeeOptions
                            .map(
                              (employee) => ModernDropdownItem.create<String>(
                                value: employee.id,
                                text: employee.label,
                                subtitle: employee.subtitle,
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedEmployeeId = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.base),
                    ],
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: dialogContext,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDateRange: selectedRange,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedRange = picked);
                        }
                      },
                      icon: const Icon(Icons.date_range_rounded),
                      label: Text(_rangeLabel(selectedRange)),
                    ),
                    if (selectedRange != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              setDialogState(() => selectedRange = null),
                          icon: const Icon(Icons.clear_rounded),
                          label: const Text('Clear date range'),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.base),
                    _buildFilterSummary(
                      matchingCount: matchingCount,
                      totalCount: worksheets.length,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: matchingCount == 0
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(currentFilters);
                        },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<_TenderExportFilters?> _showTenderExportDialog(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> tenders,
    String label,
  ) {
    final projectOptions = _tenderProjectOptions(tenders);
    var selectedProject = _allProjects;
    DateTimeRange? selectedRange;

    return showDialog<_TenderExportFilters>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentFilters = _TenderExportFilters(
              project: selectedProject,
              dateRange: selectedRange,
            );
            final matchingCount =
                _filterTenders(tenders, currentFilters).length;

            return AlertDialog(
              title: Text('$label Export Options'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ModernDropdown<String>(
                      value: selectedProject,
                      label: 'Tender / Work Reference',
                      prefixIcon: Icons.work_outline_rounded,
                      items: projectOptions
                          .map(
                            (project) => ModernDropdownItem.create<String>(
                              value: project,
                              text: project,
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedProject = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.base),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: dialogContext,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDateRange: selectedRange,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedRange = picked);
                        }
                      },
                      icon: const Icon(Icons.date_range_rounded),
                      label: Text(_rangeLabel(selectedRange)),
                    ),
                    if (selectedRange != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              setDialogState(() => selectedRange = null),
                          icon: const Icon(Icons.clear_rounded),
                          label: const Text('Clear date range'),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.base),
                    _buildFilterSummary(
                      matchingCount: matchingCount,
                      totalCount: tenders.length,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: matchingCount == 0
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(currentFilters);
                        },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<pw.ThemeData> _pdfTheme() async {
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    return pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      fontFallback: [regular],
    );
  }

  String _bulkFileName(String prefix, String extension) {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${prefix}_$stamp.$extension';
  }

  Future<void> _saveFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required XTypeGroup typeGroup,
    String? mobileTitle,
  }) async {
    if (_shouldUseShareSheetForDownload) {
      await _shareGeneratedFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
        title: mobileTitle ?? 'Save $fileName',
      );
      return;
    }

    final saveLocation = await getSaveLocation(
      suggestedName: fileName,
      acceptedTypeGroups: [typeGroup],
    );
    if (saveLocation == null) {
      if (mounted) {
        AppToast.showError(context, 'Export cancelled.');
      }
      return;
    }

    await XFile.fromData(
      bytes,
      name: fileName,
      mimeType: mimeType,
    ).saveTo(saveLocation.path);
  }

  Future<void> _savePdfFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (_shouldUseShareSheetForDownload) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      return;
    }

    await _saveFile(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/pdf',
      typeGroup: const XTypeGroup(
        label: 'PDF Document',
        extensions: ['pdf'],
      ),
    );
  }

  bool get _shouldUseShareSheetForDownload {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  Future<void> _shareGeneratedFile({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String title,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        title: title,
        files: [
          XFile.fromData(
            bytes,
            mimeType: mimeType,
          ),
        ],
        fileNameOverrides: [fileName],
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _exportAllWorksheetsPdf() async {
    if (_isExporting) return;

    try {
      final currentUser = await _fetchCurrentUserModel();
      final allWorksheets = await _fetchWorksheetRequests(currentUser);
      if (allWorksheets.isEmpty) {
        if (mounted) {
          AppToast.showInfo(context, 'No worksheets to download.');
        }
        return;
      }

      final filters = await _showWorksheetExportDialog(
        allWorksheets,
        currentUser,
      );
      if (filters == null) return;

      final worksheets = _filterWorksheets(allWorksheets, filters);
      if (worksheets.isEmpty) {
        if (mounted) {
          AppToast.showInfo(context, 'No worksheets match those filters.');
        }
        return;
      }

      setState(() => _activeExport = 'worksheets_pdf');
      final document = pw.Document(theme: await _pdfTheme());
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (context) => [
            pw.Text(
              'Worksheet Download Pack',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: const ['Title', 'Type', 'Office', 'Status'],
              data: worksheets.map((doc) {
                final data = doc.data();
                final worksheetData =
                    Map<String, dynamic>.from(data['worksheetData'] ?? {});
                return [
                  _value(data['worksheetTitle']),
                  _value(data['worksheetType'] ?? worksheetData['workType']),
                  _value(worksheetData['office']),
                  _value(data['status']),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellPadding: const pw.EdgeInsets.all(6),
            ),
          ],
        ),
      );

      for (final doc in worksheets) {
        final data = doc.data();
        document.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (context) => [
              pw.Text(
                _value(data['worksheetTitle']),
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: const ['Field', 'Value'],
                data: _worksheetRows(data)
                    .map((row) => [row.key, row.value])
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
      }

      await _savePdfFile(
        bytes: Uint8List.fromList(await document.save()),
        fileName: _bulkFileName('all_worksheets', 'pdf'),
      );

      if (mounted) {
        AppToast.showSuccess(context, 'All worksheets PDF downloaded.');
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          customMessage: 'Failed to export worksheets PDF',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _activeExport = null);
      }
    }
  }

  Future<void> _exportAllTendersPdf() async {
    if (_isExporting) return;

    try {
      final allTenders = await _fetchSubmittedTenders();
      if (allTenders.isEmpty) {
        if (mounted) {
          AppToast.showInfo(context, 'No submitted tenders to download.');
        }
        return;
      }

      final filters = await _showTenderExportDialog(
        allTenders,
        'Tender PDF',
      );
      if (filters == null) return;

      final tenders = _filterTenders(allTenders, filters);
      if (tenders.isEmpty) {
        if (mounted) {
          AppToast.showInfo(context, 'No tenders match those filters.');
        }
        return;
      }

      setState(() => _activeExport = 'tenders_pdf');
      final document = pw.Document(theme: await _pdfTheme());
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(28),
          build: (context) => [
            pw.Text(
              'All Submitted Tenders',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Generated on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
              style: const pw.TextStyle(color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: const [
                'Reference',
                'Title',
                'Type',
                'Office',
                'Deadline',
                'Estimate',
                'EMD',
              ],
              data: tenders.map((doc) {
                final data = doc.data();
                return [
                  _value(data['reference']),
                  _value(data['title']),
                  _value(data['tenderType']),
                  _value(data['office']),
                  _value(data['submissionDeadline']),
                  _value(data['estimateAmount']),
                  _value(data['emdAmount']),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey300),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.all(5),
            ),
          ],
        ),
      );

      for (final doc in tenders) {
        final data = doc.data();
        document.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (context) => [
              pw.Text(
                '${_value(data['reference'])} - ${_value(data['title'])}',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: const ['Field', 'Value'],
                data: _tenderRows(data)
                    .map((row) => [row.key, row.value])
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
      }

      await _savePdfFile(
        bytes: Uint8List.fromList(await document.save()),
        fileName: _bulkFileName('all_tenders', 'pdf'),
      );

      if (mounted) AppToast.showSuccess(context, 'All tenders PDF downloaded.');
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          customMessage: 'Failed to export tenders PDF',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _activeExport = null);
      }
    }
  }

  Future<void> _exportAllTendersXlsx() async {
    if (_isExporting) return;

    try {
      final allTenders = await _fetchSubmittedTenders();
      if (allTenders.isEmpty) {
        if (mounted) {
          AppToast.showInfo(context, 'No submitted tenders to download.');
        }
        return;
      }

      final filters = await _showTenderExportDialog(
        allTenders,
        'Tender XLSX',
      );
      if (filters == null) return;

      final tenders = _filterTenders(allTenders, filters);
      if (tenders.isEmpty) {
        if (mounted) {
          AppToast.showInfo(context, 'No tenders match those filters.');
        }
        return;
      }

      setState(() => _activeExport = 'tenders_xlsx');
      final excel = xls.Excel.createExcel();
      excel.rename('Sheet1', 'Tender Summary');
      final summary = excel['Tender Summary'];
      excel.setDefaultSheet('Tender Summary');

      final headers = _tenderRows(tenders.first.data())
          .map((row) => xls.TextCellValue(row.key))
          .toList();
      summary.appendRow(headers);

      final sortedTenders = [...tenders]..sort((a, b) {
          final referenceCompare = _value(a.data()['reference'])
              .compareTo(_value(b.data()['reference']));
          if (referenceCompare != 0) return referenceCompare;
          return _value(a.data()['title']).compareTo(_value(b.data()['title']));
        });

      for (final doc in sortedTenders) {
        final data = doc.data();
        summary.appendRow([
          for (final row in _tenderRows(data)) xls.TextCellValue(row.value),
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        throw Exception('Unable to generate workbook.');
      }

      await _saveFile(
        bytes: Uint8List.fromList(bytes),
        fileName: _bulkFileName('all_tenders', 'xlsx'),
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        mobileTitle: 'Save tenders XLSX',
        typeGroup: const XTypeGroup(
          label: 'Excel Workbook',
          extensions: ['xlsx'],
        ),
      );

      if (mounted) {
        AppToast.showSuccess(context, 'All tenders XLSX downloaded.');
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          customMessage: 'Failed to export tenders XLSX',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _activeExport = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(title: 'Downloads'),
      bottomNavigationBar: const ShellBottomNav(),
      body: ListView(
        padding: EdgeInsets.all(context.responsivePadding(AppSpacing.lg)),
        children: [
          Text(
            'Bulk Downloads',
            style: context.responsiveTextStyle(AppTypography.headingStyle),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Single item downloads stay on worksheet and tender cards. Use this page for documentation packs and comparison exports.',
            style: AppTypography.bodyStyle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _BulkDownloadCard(
            icon: Icons.assignment_rounded,
            title: 'Worksheets',
            description:
                'Download all your submitted worksheets as one PDF pack.',
            actions: [
              AppButton(
                label: 'Download All PDF',
                icon: Icons.picture_as_pdf_rounded,
                isLoading: _isActiveExport('worksheets_pdf'),
                onPressed: _isExporting ? null : _exportAllWorksheetsPdf,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          _BulkDownloadCard(
            icon: Icons.description_rounded,
            title: 'Tenders',
            description:
                'Download all submitted tenders for documentation and comparison.',
            actions: [
              AppButton(
                label: 'Download All PDF',
                icon: Icons.picture_as_pdf_rounded,
                isLoading: _isActiveExport('tenders_pdf'),
                onPressed: _isExporting ? null : _exportAllTendersPdf,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Download All XLSX',
                icon: Icons.table_chart_outlined,
                variant: AppButtonVariant.outline,
                isLoading: _isActiveExport('tenders_xlsx'),
                onPressed: _isExporting ? null : _exportAllTendersXlsx,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          _BulkDownloadCard(
            icon: Icons.account_balance_wallet_rounded,
            title: 'EMD / SD',
            description:
                'Bulk exports for EMD and SD records will be added here later.',
            actions: [
              AppButton(
                label: 'Coming Later',
                icon: Icons.schedule_rounded,
                variant: AppButtonVariant.outline,
                onPressed: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulkDownloadCard extends StatelessWidget {
  const _BulkDownloadCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actions,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.modernCardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.primaryWithLowOpacity,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: AppTypography.subheadingStyle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.bodyStyle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                ...actions,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorksheetExportFilters {
  const _WorksheetExportFilters({
    required this.status,
    required this.office,
    required this.employeeId,
    required this.dateRange,
  });

  final String status;
  final String office;
  final String? employeeId;
  final DateTimeRange? dateRange;
}

class _EmployeeOption {
  const _EmployeeOption({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final String role;

  String get label => name == '-' ? email : name;

  String? get subtitle {
    final parts = [
      if (email.isNotEmpty && email != '-') email,
      if (role.isNotEmpty && role != '-') role,
    ];
    return parts.isEmpty ? null : parts.join(' - ');
  }
}

class _TenderExportFilters {
  const _TenderExportFilters({
    required this.project,
    required this.dateRange,
  });

  final String project;
  final DateTimeRange? dateRange;
}

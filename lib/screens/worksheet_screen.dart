import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/app_colors.dart';
import '../utils/app_spacing.dart';
import '../utils/app_decorations.dart';
import '../utils/app_typography.dart';
import '../utils/app_toast.dart';
import '../components/common/app_bar_builder.dart';
import '../components/common/app_loading.dart';
import '../components/common/app_segmented_tabs.dart';
import '../components/common/modern_dropdown.dart';
import '../components/common/skeleton_loader.dart';
import '../models/user_model.dart';
import '../services/approval_service.dart';

class WorksheetScreen extends StatefulWidget {
  const WorksheetScreen({super.key});

  @override
  State<WorksheetScreen> createState() => _WorksheetScreenState();
}

class _WorksheetScreenState extends State<WorksheetScreen>
    with AutomaticKeepAliveClientMixin {
  // --- State & Controllers ---
  final _formKey = GlobalKey<FormState>(); // Key for form validation
  final ApprovalService _approvalService = ApprovalService();
  bool _isLoading = false;
  UserModel? _currentUser;
  String? _busyRequestId;
  bool _isDownloadingPdf = false;
  int _selectedTabIndex = 0;

  // Form controllers to manage text field data
  final _projectNameController = TextEditingController();
  String? _selectedWorkType;

  // Form controllers to manage text field data

  final _permitBookController = TextEditingController();
  final _locationController = TextEditingController();
  final _moreInfoController = TextEditingController();

  // Variables for dropdowns
  String? _selectedOffice;
  String? _selectedProject;

  // Image upload related variables
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed.
    _projectNameController.dispose();
    _permitBookController.dispose();
    _locationController.dispose();
    _moreInfoController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _approvalService.getCurrentUser();
      if (mounted) setState(() => _currentUser = user);
    } catch (_) {
      // Submit flow still handles missing user explicitly.
    }
  }

  // --- Functions ---

  // Function to show image source selection dialog
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Select Photo Source',
                style: TextStyle(
                  fontSize: AppTypography.fontSizeLG,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  // Helper widget for image source options
  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.primaryWithLowOpacity,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypography.fontSizeLG,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _uploadedImageUrl =
              null; // Reset uploaded URL when new image is selected
        });

        // Upload the image immediately after selection
        await _uploadImageToFirebase();
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(context, e,
            customMessage: 'Error selecting image');
      }
    }
  }

  // Function to upload image to Firebase Storage
  Future<void> _uploadImageToFirebase() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in.");
      }

      // Create a unique filename using timestamp and user ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'worksheets/${user.uid}/$timestamp.jpg';

      // Create reference to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

      // Upload the file
      final uploadTask = storageRef.putFile(_selectedImage!);

      // Get download URL after upload completes
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _uploadedImageUrl = downloadUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        AppToast.showSuccess(context, 'Photo uploaded successfully! 📷');
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      if (mounted) {
        AppErrorHandler.handleError(context, e,
            customMessage: 'Error uploading photo');
      }
    }
  }

  Future<void> _submitWorksheet() async {
    // Validate the form before proceeding
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

      // Prepare the data to be saved
      final worksheetData = <String, dynamic>{
        'submittedByUid': user.uid,
        'submittedByEmail': user.email,
        'timestamp': FieldValue.serverTimestamp(),
        'office': _selectedOffice,
        'workType': _selectedWorkType,
        'permitBook': _permitBookController.text,
        'location': _locationController.text,
        'moreInfo': _moreInfoController.text,
        'photoUrl': _uploadedImageUrl, // URL from Firebase Storage
      };

      if (_selectedWorkType == 'Project') {
        worksheetData.addAll({
          'projectSelection': _selectedProject,
          'projectName': _projectNameController.text.trim(),
        });
      }

      await _approvalService.submitRequest(
        action: ApprovalAction.worksheet,
        payload: {
          'worksheetType': _selectedWorkType,
          'worksheetTitle': _worksheetTitle,
          'worksheetData': worksheetData,
        },
      );

      if (mounted) {
        AppToast.showSuccess(context, 'Worksheet submitted successfully! 📄');
        Navigator.of(context).pop(); // Go back to the previous screen
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(context, e,
            customMessage: 'Failed to submit worksheet');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String get _worksheetTitle {
    if (_selectedWorkType == 'Project' &&
        _projectNameController.text.trim().isNotEmpty) {
      return _projectNameController.text.trim();
    }
    return '${_selectedWorkType ?? 'Daily'} Worksheet';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(title: 'Daily Worksheet'),
      body: Column(
        children: [
          _buildWorksheetTabs(),
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _isLoading ? const WorksheetSkeleton() : _buildSubmitTab(),
                _buildMyStatusTab(),
                _buildApprovalsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildWorksheetTabs() {
    return AppSegmentedTabs(
      selectedIndex: _selectedTabIndex,
      onChanged: (index) => setState(() => _selectedTabIndex = index),
      tabs: const [
        AppSegmentedTab(icon: Icons.edit_document, label: 'Submit'),
        AppSegmentedTab(icon: Icons.fact_check_outlined, label: 'Status'),
        AppSegmentedTab(icon: Icons.verified_outlined, label: 'Approvals'),
      ],
    );
  }

  Widget _buildSubmitTab() {
    return Column(
      children: [
        // Page Header Section
        Container(
          width: double.infinity,
          color: AppColors.surface,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                context.responsivePadding(AppSpacing.xl),
                context.responsivePadding(AppSpacing.xl),
                context.responsivePadding(AppSpacing.xl),
                context.responsivePadding(AppSpacing.xl)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWithLowOpacity,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.assignment_rounded,
                    size: AppTypography.iconSizeHero,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  'Daily Worksheet',
                  style: AppTypography.titleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Submit your daily work report',
                  style: AppTypography.bodyStyle.copyWith(
                    color: AppColors.textSecondary,
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
              padding: EdgeInsets.all(context.responsivePadding(AppSpacing.lg)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProjectDetailsCard(),
                  SizedBox(height: context.responsiveSpacing(AppSpacing.xl)),
                  _buildDocumentationCard(),
                  SizedBox(height: context.responsiveSpacing(AppSpacing.xxl)),
                  // Submit Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                      ),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDefault),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _submitWorksheet,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusDefault),
                        child: Center(
                          child: Text(
                            'SUBMIT WORKSHEET',
                            style: TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: AppTypography.fontSizeBase,
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
    );
  }

  Widget _buildMyStatusTab() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return _buildMessage('Login required to view worksheet status.');
    }

    return _buildWorksheetRequestStream(
      stream: FirebaseFirestore.instance
          .collection('worksheet_requests')
          .where('action', isEqualTo: ApprovalAction.worksheet.value)
          .where('requestedBy', isEqualTo: currentUid)
          .snapshots(),
      filter: (data) => data['requestedBy'] == currentUid,
      emptyMessage: 'No worksheet requests submitted yet.',
      showActions: false,
    );
  }

  Widget _buildApprovalsTab() {
    return _buildWorksheetRequestStream(
      stream: FirebaseFirestore.instance
          .collection('worksheet_requests')
          .where('action', isEqualTo: ApprovalAction.worksheet.value)
          .snapshots(),
      filter: (data) {
        final requesterRole =
            UserRole.fromString(data['requestedByRole'] ?? 'staff');
        return _currentUser?.role.canApproveRequestFrom(requesterRole) ?? false;
      },
      emptyMessage: 'No worksheet requests for your approval.',
      showActions: true,
    );
  }

  Widget _buildWorksheetRequestStream({
    required Stream<QuerySnapshot> stream,
    required bool Function(Map<String, dynamic>) filter,
    required String emptyMessage,
    required bool showActions,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildMessage('Unable to load worksheet requests.');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return filter(data);
        }).toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['requestTimestamp'];
            final bTime = bData['requestTimestamp'];
            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }
            return 0;
          });

        if (docs.isEmpty) return _buildMessage(emptyMessage);

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.base),
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _buildWorksheetRequestCard(
              doc.id,
              doc.data() as Map<String, dynamic>,
              showActions: showActions,
            );
          },
        );
      },
    );
  }

  Widget _buildWorksheetRequestCard(
    String requestId,
    Map<String, dynamic> data, {
    required bool showActions,
  }) {
    final worksheetData =
        Map<String, dynamic>.from(data['worksheetData'] ?? {});
    final status = data['status'] ?? 'Pending';
    final isPending = status == 'Pending';
    final isRejected = status == 'Rejected';
    final isBusy = _busyRequestId == requestId;
    final statusColor = isPending
        ? AppColors.warning
        : isRejected
            ? AppColors.error
            : AppColors.success;

    return Container(
      decoration: AppDecorations.modernCardDecoration,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['worksheetTitle'] ?? 'Worksheet',
                  style: AppTypography.subheadingStyle,
                ),
              ),
              _buildStatusChip(status.toString(), statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${data['worksheetType'] ?? worksheetData['workType'] ?? 'Daily'} • ${worksheetData['office'] ?? 'Office not set'}',
            style: AppTypography.bodyStyle,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Raised by ${data['requestedByName'] ?? data['requestedByEmail'] ?? 'User'}',
            style: AppTypography.captionStyle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (!isPending && data['approvedByEmail'] != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${isRejected ? 'Rejected' : 'Approved'} by ${data['approvedByEmail']}',
              style: AppTypography.captionStyle.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.base),
          _buildWorksheetActions(
            requestId: requestId,
            data: data,
            showApprovalActions: showActions && isPending,
            isBusy: isBusy,
          ),
        ],
      ),
    );
  }

  Widget _buildWorksheetActions({
    required String requestId,
    required Map<String, dynamic> data,
    required bool showApprovalActions,
    required bool isBusy,
  }) {
    if (!showApprovalActions) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showWorksheetDetails(data),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('View Details'),
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          IconButton.filledTonal(
            tooltip: 'Download PDF',
            onPressed:
                _isDownloadingPdf ? null : () => _downloadWorksheetPdf(data),
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showWorksheetDetails(data),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('View Details'),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            IconButton.filledTonal(
              tooltip: 'Download PDF',
              onPressed:
                  _isDownloadingPdf ? null : () => _downloadWorksheetPdf(data),
              icon: const Icon(Icons.picture_as_pdf_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy ? null : () => _rejectWorksheet(requestId),
                child: const Text('Reject'),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: ElevatedButton(
                onPressed: isBusy ? null : () => _approveWorksheet(requestId),
                child: Text(isBusy ? 'Please wait...' : 'Approve'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        status,
        style: AppTypography.captionStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
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

  Future<void> _approveWorksheet(String requestId) async {
    setState(() => _busyRequestId = requestId);
    try {
      await _approvalService.approveWorksheetRequest(requestId);
      if (mounted) AppToast.showSuccess(context, 'Worksheet approved.');
    } catch (e) {
      if (mounted) AppErrorHandler.handleError(context, e);
    } finally {
      if (mounted) setState(() => _busyRequestId = null);
    }
  }

  Future<void> _rejectWorksheet(String requestId) async {
    setState(() => _busyRequestId = requestId);
    try {
      await _approvalService.rejectWorksheetRequest(requestId);
      if (mounted) AppToast.showSuccess(context, 'Worksheet rejected.');
    } catch (e) {
      if (mounted) AppErrorHandler.handleError(context, e);
    } finally {
      if (mounted) setState(() => _busyRequestId = null);
    }
  }

  void _showWorksheetDetails(Map<String, dynamic> data) {
    final worksheetData =
        Map<String, dynamic>.from(data['worksheetData'] ?? {});
    final worksheetType =
        _detailValue(data['worksheetType'] ?? worksheetData['workType']);
    final fields = <MapEntry<String, String>>[
      MapEntry('Type', worksheetType),
      MapEntry('Office', _detailValue(worksheetData['office'])),
      if (worksheetType == 'Project') ...[
        MapEntry('Project', _detailValue(worksheetData['projectSelection'])),
        MapEntry('Project Name', _detailValue(worksheetData['projectName'])),
      ],
      MapEntry('Permit Book', _detailValue(worksheetData['permitBook'])),
      MapEntry('Location', _detailValue(worksheetData['location'])),
      if (_hasDetailValue(worksheetData['moreInfo']))
        MapEntry('Notes', _detailValue(worksheetData['moreInfo'])),
      if (_hasDetailValue(worksheetData['photoUrl']))
        MapEntry('Photo URL', _detailValue(worksheetData['photoUrl'])),
    ];

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
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  data['worksheetTitle'] ?? 'Worksheet Details',
                  style: AppTypography.titleStyle,
                ),
                const SizedBox(height: AppSpacing.base),
                ...fields.map(
                  (field) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.base),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.key,
                          style: AppTypography.captionStyle.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(field.value, style: AppTypography.bodyStyle),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloadingPdf
                        ? null
                        : () => _downloadWorksheetPdf(data),
                    icon: const Icon(Icons.download_rounded),
                    label: Text(
                      _isDownloadingPdf ? 'Downloading PDF...' : 'Download PDF',
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _hasDetailValue(Object? value) =>
      value != null && value.toString().trim().isNotEmpty;

  String _detailValue(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  Future<void> _downloadWorksheetPdf(Map<String, dynamic> data) async {
    if (_isDownloadingPdf) return;

    setState(() => _isDownloadingPdf = true);

    try {
      final pdfBytes = await _buildWorksheetPdfBytes(data);
      final fileName = _buildWorksheetPdfFileName(data);

      if (_shouldUseShareSheetForDownload) {
        await Printing.sharePdf(
          bytes: Uint8List.fromList(pdfBytes),
          filename: fileName,
        );
        if (mounted) {
          AppToast.showSuccess(
              context, 'Worksheet PDF ready to save or share.');
        }
        return;
      }

      final saveLocation = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'PDF Document', extensions: ['pdf']),
        ],
      );

      if (saveLocation == null) {
        if (mounted) {
          AppToast.showError(context, 'PDF download cancelled.');
        }
        return;
      }

      await XFile.fromData(
        Uint8List.fromList(pdfBytes),
        name: fileName,
        mimeType: 'application/pdf',
      ).saveTo(saveLocation.path);

      if (mounted) {
        AppToast.showSuccess(context, 'Worksheet PDF downloaded successfully.');
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          customMessage: 'Failed to download worksheet PDF',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
      }
    }
  }

  bool get _shouldUseShareSheetForDownload {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  Future<List<int>> _buildWorksheetPdfBytes(Map<String, dynamic> data) async {
    final worksheetData =
        Map<String, dynamic>.from(data['worksheetData'] ?? {});
    final worksheetType =
        _detailValue(data['worksheetType'] ?? worksheetData['workType']);
    final photoUrl = worksheetData['photoUrl']?.toString().trim() ?? '';
    final hasPhoto = photoUrl.isNotEmpty;

    final rows = <MapEntry<String, String>>[
      MapEntry('Worksheet Title', _detailValue(data['worksheetTitle'])),
      MapEntry('Worksheet Type', worksheetType),
      MapEntry('Office', _detailValue(worksheetData['office'])),
      if (worksheetType == 'Project') ...[
        MapEntry('Project', _detailValue(worksheetData['projectSelection'])),
        MapEntry('Project Name', _detailValue(worksheetData['projectName'])),
      ],
      MapEntry('Permit Book', _detailValue(worksheetData['permitBook'])),
      MapEntry('Location', _detailValue(worksheetData['location'])),
      if (_hasDetailValue(worksheetData['moreInfo']))
        MapEntry('Notes', _detailValue(worksheetData['moreInfo'])),
      if (hasPhoto) MapEntry('Photo URL', _detailValue(photoUrl)),
      MapEntry('Requested By', _detailValue(data['requestedByName'])),
      MapEntry('Requester Email', _detailValue(data['requestedByEmail'])),
      MapEntry('Status', _detailValue(data['status'])),
      if (_hasDetailValue(data['approvedByEmail']))
        MapEntry('Approved By', _detailValue(data['approvedByEmail'])),
      if (data['requestTimestamp'] is Timestamp)
        MapEntry(
          'Submitted At',
          DateFormat('dd MMM yyyy, hh:mm a')
              .format((data['requestTimestamp'] as Timestamp).toDate()),
        ),
    ];

    final document = pw.Document(theme: await _buildPdfTheme());
    final photoImage = hasPhoto ? await networkImage(photoUrl) : null;

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (context) => [
          pw.Text(
            _detailValue(data['worksheetTitle']),
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: pdf.PdfColors.blueGrey900,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Worksheet Details',
            style: pw.TextStyle(
              fontSize: 11,
              color: pdf.PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 16),
          if (photoImage != null) ...[
            pw.Text(
              'Uploaded Photo',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: pdf.PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: pdf.PdfColors.grey400, width: 0.7),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Image(
                    photoImage,
                    fit: pw.BoxFit.contain,
                    height: 240,
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    photoUrl,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],
          pw.TableHelper.fromTextArray(
            headers: const ['Field', 'Value'],
            data: rows.map((row) => [row.key, row.value]).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: pdf.PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: pdf.PdfColors.blueGrey800,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(4),
            },
            border: pw.TableBorder.all(
              color: pdf.PdfColors.grey400,
              width: 0.6,
            ),
            oddRowDecoration: pw.BoxDecoration(
              color: pdf.PdfColors.grey100,
            ),
          ),
        ],
      ),
    );

    return document.save();
  }

  Future<pw.ThemeData> _buildPdfTheme() async {
    return pw.ThemeData.withFont(
      base: await PdfGoogleFonts.notoSansRegular(),
      bold: await PdfGoogleFonts.notoSansBold(),
      italic: await PdfGoogleFonts.notoSansItalic(),
      boldItalic: await PdfGoogleFonts.notoSansBoldItalic(),
    );
  }

  String _buildWorksheetPdfFileName(Map<String, dynamic> data) {
    final title = _detailValue(data['worksheetTitle'])
        .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final safeTitle = title.isEmpty ? 'worksheet' : title;
    final dateStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return '${safeTitle}_$dateStamp.pdf';
  }

  // Helper widget for a section header
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
            child: Icon(icon, color: AppColors.primary, size: AppSpacing.xl),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            title,
            style: TextStyle(
              fontSize: AppTypography.fontSize2XL,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Card for the first group of inputs
  Widget _buildProjectDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: <Widget>[
            _buildSectionHeader('Project Details', Icons.business_center),
            const SizedBox(height: AppSpacing.sm),

            // Office Selection Dropdown
            _buildDropdown(
              value: _selectedOffice,
              label: 'Office Selection',
              icon: Icons.location_city,
              items: const ['Office A', 'Office B', 'Office C'],
              validator: (value) =>
                  value == null ? 'Please select an office.' : null,
              onChanged: (value) => setState(() => _selectedOffice = value),
            ),
            const SizedBox(height: AppSpacing.base),

            // Work Type Field
            _buildDropdown(
              value: _selectedWorkType,
              label: 'Work Type',
              icon: Icons.construction,
              items: const ['Project', 'Maintenance', 'Calamity'],
              validator: (value) =>
                  value == null ? 'Please select a work type.' : null,
              onChanged: (value) {
                setState(() {
                  _selectedWorkType = value;
                  if (value != 'Project') {
                    _selectedProject = null;
                    _projectNameController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.base),

            // Show project-specific fields only when Work Type is Project
            if (_selectedWorkType == 'Project') ...[
              // Project Selection Dropdown
              _buildDropdown(
                value: _selectedProject,
                label: 'Project Selection',
                icon: Icons.assignment,
                items: const ['Project X', 'Project Y', 'Project Z'],
                validator: (value) =>
                    value == null ? 'Please select a project.' : null,
                onChanged: (value) => setState(() => _selectedProject = value),
              ),
              const SizedBox(height: AppSpacing.base),

              // Project Name Field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.grey300, width: 1),
                ),
                child: TextFormField(
                  controller: _projectNameController,
                  decoration: InputDecoration(
                    labelText: 'Project Name',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.label_important_outline,
                        color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Card for the second group of inputs
  Widget _buildDocumentationCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: <Widget>[
            _buildSectionHeader('Documentation & Location', Icons.folder_copy),
            const SizedBox(height: AppSpacing.sm),

            // Permit Book Field
            Container(
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.grey300, width: 1),
              ),
              child: TextFormField(
                controller: _permitBookController,
                decoration: InputDecoration(
                  labelText: 'Permit Book',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon:
                      Icon(Icons.book_outlined, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.grey50,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),

            // Location Field
            Container(
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.grey300, width: 1),
              ),
              child: TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.location_on_outlined,
                      color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.grey50,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Upload Photo Button with Preview
            _buildPhotoUploadSection(),
            const SizedBox(height: AppSpacing.base),

            // Additional Information Field
            Container(
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.grey300, width: 1),
              ),
              child: TextFormField(
                controller: _moreInfoController,
                decoration: InputDecoration(
                  labelText: 'Additional Information',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.notes, color: AppColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.grey50,
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return ModernDropdown<String>(
      value: value,
      label: label,
      prefixIcon: icon,
      fillColor: AppColors.grey50,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 12,
      ),
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

  // Widget for photo upload section with preview
  Widget _buildPhotoUploadSection() {
    if (_selectedImage != null || _uploadedImageUrl != null) {
      // Show image preview with option to change
      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              border: Border.all(color: AppColors.grey300),
              image: _selectedImage != null
                  ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _selectedImage == null && _uploadedImageUrl != null
                ? ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDefault),
                    child: Image.network(
                      _uploadedImageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: AppLoading());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 40, color: AppColors.error),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                : (_isUploadingImage
                    ? const AppLoading(message: 'Uploading...')
                    : null),
          ),
          const SizedBox(height: AppSpacing.base),
          // Change photo button
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              color: Colors.transparent,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isUploadingImage ? null : _showImageSourceDialog,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.change_circle_outlined,
                      size: 24,
                      color: _isUploadingImage
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _isUploadingImage ? 'Uploading...' : 'Change Photo',
                      style: TextStyle(
                        fontSize: AppTypography.fontSizeLG,
                        fontWeight: FontWeight.w600,
                        color: _isUploadingImage
                            ? AppColors.textSecondary
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Show upload button when no image is selected
      return Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          color: AppColors.primaryWithLowOpacity,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showImageSourceDialog,
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_rounded,
                    size: 28, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Upload Photo',
                  style: TextStyle(
                    fontSize: AppTypography.fontSizeLG,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

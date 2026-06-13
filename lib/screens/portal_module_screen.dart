import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../components/common/app_bar_builder.dart';
import '../components/common/app_button.dart';
import '../components/common/app_loading.dart';
import '../components/common/app_text_field.dart';
import '../components/common/modern_dropdown.dart';
import '../utils/app_colors.dart';
import '../utils/app_decorations.dart';
import '../utils/app_spacing.dart';
import '../utils/app_toast.dart';
import '../utils/app_typography.dart';

enum PortalFieldType { text, number, date, dropdown, multiline, upload }

class PortalModuleField {
  final String label;
  final IconData icon;
  final PortalFieldType type;
  final List<String> options;
  final bool required;

  const PortalModuleField({
    required this.label,
    required this.icon,
    this.type = PortalFieldType.text,
    this.options = const [],
    this.required = false,
  });
}

class PortalModuleSection {
  final String title;
  final List<String> features;
  final List<PortalModuleField> fields;

  const PortalModuleSection({
    required this.title,
    this.features = const [],
    this.fields = const [],
  });
}

class PortalModuleScreen extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<PortalModuleSection> sections;

  const PortalModuleScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.sections,
  });

  @override
  State<PortalModuleScreen> createState() => _PortalModuleScreenState();
}

class _PortalModuleScreenState extends State<PortalModuleScreen> {
  final ImagePicker _picker = ImagePicker();
  final Map<String, File> _selectedFiles = {};
  final Map<String, String> _uploadedUrls = {};
  final Set<String> _uploadingFields = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(title: widget.title),
      body: ListView(
        padding: EdgeInsets.all(context.responsivePadding(AppSpacing.lg)),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: AppDecorations.modernCardDecoration,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWithLowOpacity,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusDefault),
                  ),
                  child: Icon(widget.icon, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTypography.titleStyle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...widget.sections.map(_buildSection),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Save Draft',
            icon: Icons.save_outlined,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'Submit for Review',
            icon: Icons.send_rounded,
            variant: AppButtonVariant.outline,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSection(PortalModuleSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.modernCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: AppTypography.subheadingStyle),
          if (section.features.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.base),
            ...section.features.map(_buildFeatureRow),
          ],
          if (section.fields.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ...section.fields.map(_buildField),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              feature,
              style: AppTypography.bodyStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(PortalModuleField field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: switch (field.type) {
        PortalFieldType.dropdown => ModernDropdown<String>(
            value: null,
            label: field.label,
            prefixIcon: field.icon,
            isRequired: field.required,
            onChanged: (_) {},
            items: field.options
                .map(
                  (option) => ModernDropdownItem.create<String>(
                    value: option,
                    text: option,
                  ),
                )
                .toList(),
          ),
        PortalFieldType.upload => _buildUploadField(field),
        PortalFieldType.multiline => AppTextField(
            label: field.required ? '${field.label} *' : field.label,
            prefixIcon: Icon(field.icon, color: AppColors.primary),
            maxLines: 3,
          ),
        _ => AppTextField(
            label: field.required ? '${field.label} *' : field.label,
            prefixIcon: Icon(field.icon, color: AppColors.primary),
            keyboardType: field.type == PortalFieldType.number
                ? TextInputType.number
                : TextInputType.text,
            suffixIcon: field.type == PortalFieldType.date
                ? Icon(Icons.calendar_today_rounded, color: AppColors.primary)
                : null,
          ),
      },
    );
  }

  Widget _buildUploadField(PortalModuleField field) {
    final uploadKey = field.label;
    final selectedFile = _selectedFiles[uploadKey];
    final uploadedUrl = _uploadedUrls[uploadKey];
    final isUploading = _uploadingFields.contains(uploadKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedFile != null || uploadedUrl != null) ...[
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              border: Border.all(color: AppColors.grey300),
              image: selectedFile != null
                  ? DecorationImage(
                      image: FileImage(selectedFile),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: isUploading
                ? const AppLoading(message: 'Uploading...')
                : selectedFile == null && uploadedUrl != null
                    ? Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 40,
                        ),
                      )
                    : null,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Container(
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.primaryWithLowOpacity,
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isUploading ? null : () => _showImageSourceSheet(field),
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                child: Row(
                  children: [
                    Icon(field.icon, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: Text(
                        _uploadLabel(
                            field, selectedFile, uploadedUrl, isUploading),
                        style: AppTypography.bodyMediumStyle.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Icon(
                      uploadedUrl == null
                          ? Icons.upload_file_rounded
                          : Icons.change_circle_outlined,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _uploadLabel(
    PortalModuleField field,
    File? selectedFile,
    String? uploadedUrl,
    bool isUploading,
  ) {
    if (isUploading) return 'Uploading ${field.label}...';
    if (uploadedUrl != null) return 'Change ${field.label}';
    if (selectedFile != null) return 'Upload selected';
    return field.required ? '${field.label} *' : field.label;
  }

  Future<void> _showImageSourceSheet(PortalModuleField field) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) {
        return Padding(
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
              Text('Select Upload Source',
                  style: AppTypography.subheadingStyle),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _buildSourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUpload(field, ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: _buildSourceOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUpload(field, ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.primaryWithLowOpacity,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTypography.bodyMediumStyle.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(
    PortalModuleField field,
    ImageSource source,
  ) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image == null) return;

      final uploadKey = field.label;
      setState(() {
        _selectedFiles[uploadKey] = File(image.path);
        _uploadedUrls.remove(uploadKey);
      });

      await _uploadSelectedFile(field);
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          customMessage: 'Unable to select photo',
        );
      }
    }
  }

  Future<void> _uploadSelectedFile(PortalModuleField field) async {
    final uploadKey = field.label;
    final file = _selectedFiles[uploadKey];
    if (file == null) return;

    setState(() => _uploadingFields.add(uploadKey));

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in.');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeModule = widget.title.toLowerCase().replaceAll(' ', '_');
      final safeField = uploadKey.toLowerCase().replaceAll(' ', '_');
      final path = 'portal/$safeModule/${user.uid}/${safeField}_$timestamp.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(path);
      final snapshot = await storageRef.putFile(file);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() => _uploadedUrls[uploadKey] = downloadUrl);

      if (mounted) {
        AppToast.showSuccess(context, '${field.label} uploaded successfully.');
      }
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          customMessage: 'Unable to upload photo',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingFields.remove(uploadKey));
      }
    }
  }
}

import 'package:flutter/material.dart';

import '../components/common/app_bar_builder.dart';
import '../components/common/app_button.dart';
import '../components/common/app_text_field.dart';
import '../components/common/modern_dropdown.dart';
import '../utils/app_colors.dart';
import '../utils/app_decorations.dart';
import '../utils/app_spacing.dart';
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

class PortalModuleScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(title: title),
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
                  child: Icon(icon, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleStyle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...sections.map(_buildSection),
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
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.primaryWithLowOpacity,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Row(
              children: [
                Icon(field.icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Text(
                    field.required ? '${field.label} *' : field.label,
                    style: AppTypography.bodyMediumStyle.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Icon(Icons.upload_file_rounded, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

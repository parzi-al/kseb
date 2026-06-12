import 'package:flutter/material.dart';

import '../components/common/app_bar_builder.dart';
import '../utils/app_colors.dart';
import '../utils/app_decorations.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';

class PortalModuleSection {
  final String title;
  final List<String> features;

  const PortalModuleSection({
    required this.title,
    required this.features,
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
          const SizedBox(height: AppSpacing.base),
          ...section.features.map(
            (feature) => Padding(
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
            ),
          ),
        ],
      ),
    );
  }
}

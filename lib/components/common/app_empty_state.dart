import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_typography.dart';
import 'app_button.dart';

/// A consistently-styled empty state using design system tokens.
///
/// Displays a centered icon, title, optional subtitle, and optional
/// action button for screens/sections that have no data to show.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.grey400),
          SizedBox(height: AppSpacing.base),
          Text(title, style: AppTypography.subheadingStyle),
          if (subtitle != null) ...[
            SizedBox(height: AppSpacing.sm),
            Text(subtitle!, style: AppTypography.captionStyle),
          ],
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: AppSpacing.lg),
            AppButton(
              label: actionLabel!,
              variant: AppButtonVariant.outline,
              onPressed: onAction,
              fullWidth: false,
            ),
          ],
        ],
      ),
    );
  }
}

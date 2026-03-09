import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_typography.dart';
import 'app_button.dart';

/// A consistently-styled error state using design system tokens.
///
/// Displays a persistent inline error with icon, message, and optional
/// retry button. Complements [AppToast] (transient) for section/page-level
/// failures where the user must explicitly retry.
class AppErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorState({
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: AppColors.error),
          SizedBox(height: AppSpacing.base),
          Text(
            message,
            style: AppTypography.bodyStyle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (onRetry != null) ...[
            SizedBox(height: AppSpacing.base),
            AppButton(
              label: 'Retry',
              variant: AppButtonVariant.outline,
              onPressed: onRetry,
              fullWidth: false,
              icon: Icons.refresh,
            ),
          ],
        ],
      ),
    );
  }
}

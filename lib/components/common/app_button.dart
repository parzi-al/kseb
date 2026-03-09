import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_typography.dart';

/// Button variant styles for [AppButton].
enum AppButtonVariant { primary, outline, destructive, text }

/// A consistently-styled button using design system tokens.
///
/// Supports 4 variants: primary (gradient), outline, destructive, text.
/// Features loading state (spinner replaces label), disabled state (50% opacity),
/// optional icon, and full-width/wrap-content modes.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;

  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    super.key,
  });

  bool get _isDisabled => onPressed == null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final button = switch (variant) {
      AppButtonVariant.primary => _buildPrimary(context),
      AppButtonVariant.outline => _buildOutline(context),
      AppButtonVariant.destructive => _buildDestructive(context),
      AppButtonVariant.text => _buildText(context),
    };

    if (_isDisabled) {
      return Opacity(opacity: 0.5, child: IgnorePointer(child: button));
    }
    return button;
  }

  Widget _buildContent(
      {required Color textColor, required Color spinnerColor}) {
    if (isLoading) {
      return SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation(spinnerColor),
        ),
      );
    }
    final textWidget = Text(
      label,
      style: AppTypography.bodyMediumStyle.copyWith(
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
    );
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 20),
          SizedBox(width: AppSpacing.sm),
          textWidget,
        ],
      );
    }
    return textWidget;
  }

  Widget _buildPrimary(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        ),
        alignment: Alignment.center,
        child: _buildContent(
          textColor: AppColors.textOnPrimary,
          spinnerColor: AppColors.textOnPrimary,
        ),
      ),
    );
  }

  Widget _buildOutline(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        alignment: Alignment.center,
        child: _buildContent(
          textColor: AppColors.primary,
          spinnerColor: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDestructive(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        ),
        alignment: Alignment.center,
        child: _buildContent(
          textColor: AppColors.textOnPrimary,
          spinnerColor: AppColors.textOnPrimary,
        ),
      ),
    );
  }

  Widget _buildText(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        alignment: Alignment.center,
        child: _buildContent(
          textColor: AppColors.primary,
          spinnerColor: AppColors.primary,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_typography.dart';

/// Loading indicator variant styles for [AppLoading].
enum AppLoadingVariant { fullPage, inline, overlay }

/// A consistently-styled loading indicator using design system tokens.
///
/// Supports 3 variants: fullPage (centered), inline (row), overlay (backdrop).
class AppLoading extends StatelessWidget {
  final AppLoadingVariant variant;
  final String? message;

  const AppLoading({
    this.variant = AppLoadingVariant.fullPage,
    this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      AppLoadingVariant.fullPage => _buildFullPage(),
      AppLoadingVariant.inline => _buildInline(),
      AppLoadingVariant.overlay => _buildOverlay(),
    };
  }

  Widget _spinner({double size = 36}) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }

  Widget _buildFullPage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _spinner(),
          if (message != null) ...[
            SizedBox(height: AppSpacing.md),
            Text(message!, style: AppTypography.captionStyle),
          ],
        ],
      ),
    );
  }

  Widget _buildInline() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _spinner(size: 24),
        if (message != null) ...[
          SizedBox(width: AppSpacing.md),
          Text(message!, style: AppTypography.captionStyle),
        ],
      ],
    );
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: Container(
        color: AppColors.black.withValues(alpha: 0.3),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _spinner(),
            if (message != null) ...[
              SizedBox(height: AppSpacing.md),
              Text(
                message!,
                style: AppTypography.captionStyle.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

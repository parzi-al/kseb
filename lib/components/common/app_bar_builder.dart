import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_typography.dart';

/// Builds a consistently-styled AppBar using design system tokens.
///
/// Provides the same styling set in [AppBarTheme] so that even bare
/// `AppBar(title: Text(...))` inherits correctly, but this builder
/// is convenient when actions, leading, or bottom widgets are needed.
AppBar buildAppBar({
  required String title,
  List<Widget>? actions,
  Widget? leading,
  bool centerTitle = true,
  bool automaticallyImplyLeading = true,
  PreferredSizeWidget? bottom,
}) {
  return AppBar(
    title: Text(title),
    actions: actions,
    leading: leading,
    centerTitle: centerTitle,
    automaticallyImplyLeading: automaticallyImplyLeading,
    bottom: bottom,
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    elevation: 0.5,
    surfaceTintColor: Colors.transparent,
    shadowColor: AppColors.shadowLight,
    titleTextStyle: AppTypography.headingStyle,
  );
}

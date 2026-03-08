import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_decorations.dart';

/// A consistently-styled page wrapper using design system tokens.
///
/// Goes inside [Scaffold.body] — NOT a Scaffold replacement. Provides
/// standard page padding, background color, and optional scroll behavior
/// so every screen has uniform outer spacing.
class AppPageWrapper extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const AppPageWrapper({
    required this.child,
    this.scrollable = true,
    this.padding,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ??
        EdgeInsets.fromLTRB(
          context.responsivePadding(AppSpacing.xl),
          context.responsivePadding(AppSpacing.xl),
          context.responsivePadding(AppSpacing.xl),
          context.responsivePadding(100),
        );

    final content = Padding(
      padding: effectivePadding,
      child: child,
    );

    return Container(
      color: backgroundColor ?? AppColors.background,
      child: scrollable
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: content,
            )
          : content,
    );
  }
}

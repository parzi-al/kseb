import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_decorations.dart';

/// A consistently-styled card using design system tokens.
///
/// **Default**: surface bg, radiusDefault corners, 2-layer shadow, base padding.
/// **Accent**: same as default + a colored 1px border at 10% opacity.
/// **Tappable**: wraps content in [InkWell] when [onTap] is provided.
class AppCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AppCard({
    required this.child,
    this.accentColor,
    this.padding,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = accentColor != null
        ? AppDecorations.modernCardDecorationWithColor(accentColor!)
        : AppDecorations.modernCardDecoration;

    final content = Padding(
      padding: padding ?? EdgeInsets.all(AppSpacing.base),
      child: child,
    );

    return Container(
      decoration: decoration,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              child: content,
            )
          : content,
    );
  }
}

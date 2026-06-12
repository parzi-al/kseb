import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_typography.dart';

class ModernDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool isRequired;
  final bool isDense;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;

  const ModernDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.onChanged,
    this.validator,
    this.isRequired = false,
    this.isDense = true,
    this.fillColor,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(
          color: AppColors.grey300,
          width: 1.5,
        ),
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: AppTypography.captionStyle.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.6),
            fontSize: AppTypography.fontSizeBase,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: AppColors.primary,
                  size: 22,
                )
              : null,
          border: InputBorder.none,
          contentPadding: contentPadding ??
              EdgeInsets.only(
                left: prefixIcon != null ? AppSpacing.xs : AppSpacing.base,
                right: AppSpacing.xs,
                top: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
          errorStyle: TextStyle(
            color: AppColors.error,
            fontSize: AppTypography.fontSizeSM,
          ),
          filled: true,
          fillColor: fillColor ?? AppColors.background,
        ),
        icon: Padding(
          padding: EdgeInsets.only(right: AppSpacing.sm),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        dropdownColor: AppColors.surface,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: AppTypography.fontSizeBase,
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
        ),
        isExpanded: true,
        isDense: isDense,
        items: items,
        onChanged: onChanged,
        validator: validator,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        elevation: 8,
        menuMaxHeight: 300,
      ),
    );
  }
}

/// Helper class for creating modern dropdown items
class ModernDropdownItem {
  static DropdownMenuItem<T> create<T>({
    required T value,
    required String text,
    String? subtitle,
    IconData? icon,
    Color? iconColor,
  }) {
    return DropdownMenuItem<T>(
      value: value,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 2.0,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: iconColor ?? AppColors.primary,
              ),
              SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: subtitle != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          text,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: AppTypography.fontSizeSM,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: AppTypography.fontSizeXS,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    )
                  : Text(
                      text,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppTypography.fontSizeSM,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

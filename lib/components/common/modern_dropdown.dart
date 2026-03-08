import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ModernDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool isRequired;

  const ModernDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.onChanged,
    this.validator,
    this.isRequired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.grey300,
          width: 1.5,
        ),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          labelStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.6),
            fontSize: 14,
          ),
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  color: AppColors.primary,
                  size: 22,
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(
            left: prefixIcon != null ? 4 : 16,
            right: 4,
            top: 12,
            bottom: 12,
          ),
          errorStyle: TextStyle(
            color: AppColors.error,
            fontSize: 12,
          ),
        ),
        icon: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        dropdownColor: AppColors.surface,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
        ),
        isExpanded: true,
        isDense: true,
        items: items,
        onChanged: onChanged,
        validator: validator,
        borderRadius: BorderRadius.circular(12),
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
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: iconColor ?? AppColors.primary,
              ),
              const SizedBox(width: 8),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
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
                        fontSize: 13,
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

import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_typography.dart';

class AppSegmentedTab {
  const AppSegmentedTab({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class AppSegmentedTabs extends StatelessWidget {
  const AppSegmentedTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<AppSegmentedTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SegmentedButton<int>(
            segments: [
              for (var i = 0; i < tabs.length; i++)
                ButtonSegment(
                  value: i,
                  icon: Icon(tabs[i].icon, size: AppTypography.iconSizeMd),
                  label: Text(tabs[i].label),
                ),
            ],
            selected: {selectedIndex},
            onSelectionChanged: (selection) => onChanged(selection.first),
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? AppColors.primary
                    : AppColors.textSecondary;
              }),
              textStyle: WidgetStatePropertyAll(AppTypography.captionStyle),
            ),
          ),
        ),
      ),
    );
  }
}

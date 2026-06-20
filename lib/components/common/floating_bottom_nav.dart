import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_typography.dart';

class FloatingBottomNavDestination {
  const FloatingBottomNavDestination({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class FloatingBottomNav extends StatelessWidget {
  const FloatingBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<FloatingBottomNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const minItemWidth = 128.0;
            final itemWidth =
                (constraints.maxWidth / destinations.length).clamp(
              minItemWidth,
              double.infinity,
            );

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    SizedBox(
                      width: itemWidth,
                      child: _FloatingBottomNavItem(
                        destination: destinations[i],
                        selected: selectedIndex == i,
                        compact: false,
                        onTap: () => onDestinationSelected(i),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FloatingBottomNavItem extends StatelessWidget {
  const _FloatingBottomNavItem({
    required this.destination,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final FloatingBottomNavDestination destination;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 64,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color:
                selected ? AppColors.primaryWithLowOpacity : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                destination.icon,
                size: AppTypography.iconSizeLg,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              if (selected && !compact)
                Flexible(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionStyle.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/app_spacing.dart';
import '../utils/app_decorations.dart';
import '../components/common/app_bar_builder.dart';
import '../components/common/app_card.dart';
import '../components/common/shell_bottom_nav.dart';
import '../utils/page_transitions.dart';
import 'add_material_screen.dart';
import 'material_approval_screen.dart';
import 'withdraw_material_screen.dart';

class MaterialManagementScreen extends StatelessWidget {
  const MaterialManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(title: 'Material Management'),
      bottomNavigationBar: const ShellBottomNav(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Modern Header Section
            Container(
              width: double.infinity,
              color: AppColors.surface,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  context.responsivePadding(AppSpacing.xl),
                  context.responsivePadding(AppSpacing.xl),
                  context.responsivePadding(AppSpacing.xl),
                  context.responsivePadding(AppSpacing.xl),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primaryWithLowOpacity,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        size: AppTypography.iconSizeHero,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.base),
                    Text(
                      'Material Management',
                      style: AppTypography.titleStyle,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Manage inventory and material requests',
                      style: AppTypography.bodyStyle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.responsiveSpacing(AppSpacing.xl)),

            // Modern Content Section
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: context.responsivePadding(AppSpacing.lg)),
              child: Column(
                children: [
                  _buildManagementCard(
                    context,
                    label: 'ADD MATERIAL',
                    description: 'Raise a request to add inventory',
                    icon: Icons.add_circle_outline_rounded,
                    color: AppColors.success,
                    onTap: () {
                      Navigator.push(
                        context,
                        AppRoute(
                          builder: (context) => const AddMaterialScreen(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: context.responsiveSpacing(AppSpacing.lg)),
                  _buildManagementCard(
                    context,
                    label: 'WITHDRAW MATERIAL',
                    description: 'Request materials for projects',
                    icon: Icons.remove_circle_outline_rounded,
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.push(
                        context,
                        AppRoute(
                          builder: (context) => const WithdrawMaterialScreen(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: context.responsiveSpacing(AppSpacing.lg)),
                  _buildManagementCard(
                    context,
                    label: 'APPROVE REQUESTS',
                    description: 'Review requests from lower authority roles',
                    icon: Icons.verified_rounded,
                    color: AppColors.info,
                    onTap: () {
                      Navigator.push(
                        context,
                        AppRoute(
                          builder: (context) => const MaterialApprovalScreen(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: AppSpacing.page),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required String label,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      accentColor: color,
      padding: EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            ),
            child: Icon(icon, size: AppTypography.iconSizeLg, color: color),
          ),
          SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.subheadingStyle),
                SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.captionStyle,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.grey200,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textSecondary,
              size: AppTypography.iconSizeSm,
            ),
          ),
        ],
      ),
    );
  }
}

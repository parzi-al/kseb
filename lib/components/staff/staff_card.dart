import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_typography.dart';

class StaffCard extends StatelessWidget {
  final Map<String, dynamic> staffData;
  final String staffId;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canEdit;

  const StaffCard({
    super.key,
    required this.staffData,
    required this.staffId,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          staffData['name'] ?? 'Staff Member',
                          style: const TextStyle(
                            fontSize: AppTypography.fontSizeLG,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (staffData['phone'] != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_rounded,
                                size: 14,
                                color: AppColors.grey600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  staffData['phone'],
                                  style: TextStyle(
                                    color: AppColors.grey600,
                                    fontSize: 13,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (staffData['email'] != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.email_rounded,
                                size: 14,
                                color: AppColors.grey600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  staffData['email'],
                                  style: TextStyle(
                                    color: AppColors.grey600,
                                    fontSize: 13,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (canEdit)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit_rounded,
                          color: AppColors.info,
                          onTap: onEdit,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _buildActionButton(
                          icon: Icons.delete_rounded,
                          color: AppColors.error,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withValues(alpha: 0.8),
            AppColors.info,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.info.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          (staffData['name']?.isNotEmpty ?? false)
              ? staffData['name']!.substring(0, 1).toUpperCase()
              : 'S',
          style: const TextStyle(
            color: AppColors.white,
            fontSize: AppTypography.fontSizeXL,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_typography.dart';

class StaffDetailsBottomSheet extends StatelessWidget {
  final Map<String, dynamic> staffData;

  const StaffDetailsBottomSheet({
    super.key,
    required this.staffData,
  });

  static void show(BuildContext context, Map<String, dynamic> staffData) {
    showDialog(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.page,
        ),
        child: StaffDetailsBottomSheet(staffData: staffData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final name = staffData['name'] ?? 'Staff Member';
    final role = staffData['role'] ?? 'N/A';
    final initial =
        name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : 'S';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.base,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryWithLowOpacity,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: AppTypography.titleStyle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.base),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: Text(
                      role.toString(),
                      style: AppTypography.captionStyle.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final joinedAt = staffData['joinDate'] ?? staffData['createdAt'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          _detailRow(Icons.badge_outlined, 'Name', staffData['name'] ?? 'N/A'),
          _detailRow(
              Icons.mail_outline_rounded, 'Email', staffData['email'] ?? 'N/A'),
          _detailRow(
              Icons.phone_outlined, 'Phone', staffData['phone'] ?? 'N/A'),
          _detailRow(Icons.groups_outlined, 'Team',
              staffData['teamId'] ?? 'Not assigned'),
          _detailRow(Icons.location_on_outlined, 'Area',
              staffData['areaCode'] ?? 'N/A'),
          _detailRow(
            Icons.event_outlined,
            'Join Date',
            joinedAt is Timestamp
                ? joinedAt.toDate().toString().split(' ')[0]
                : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.textSecondary,
            size: AppTypography.iconSizeMd,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: AppTypography.bodyMediumStyle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.bodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}

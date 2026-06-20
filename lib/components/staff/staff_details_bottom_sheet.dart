import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';
import '../../utils/app_typography.dart';

class StaffDetailsBottomSheet extends StatefulWidget {
  const StaffDetailsBottomSheet({
    super.key,
    required this.staffData,
  });

  final Map<String, dynamic> staffData;

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
  State<StaffDetailsBottomSheet> createState() =>
      _StaffDetailsBottomSheetState();
}

class _StaffDetailsBottomSheetState extends State<StaffDetailsBottomSheet> {
  String? _teamName;
  bool _isLoadingTeam = false;

  Map<String, dynamic> get staffData => widget.staffData;

  @override
  void initState() {
    super.initState();
    _loadTeamName();
  }

  Future<void> _loadTeamName() async {
    final teamId = staffData['teamId'];
    if (teamId == null || teamId.toString().isEmpty) return;

    setState(() => _isLoadingTeam = true);

    try {
      final teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId.toString())
          .get();

      if (!mounted) return;

      setState(() {
        _teamName = teamDoc.data()?['name']?.toString();
        _isLoadingTeam = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingTeam = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final name = staffData['name'] ?? 'Staff Member';
    final role = staffData['role'] ?? 'N/A';
    final email = staffData['email'] ?? 'No email';
    final initial =
        name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : 'S';

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  AppColors.accent.withValues(alpha: 0.14),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.person_rounded,
                  color: AppColors.primary.withValues(alpha: 0.18),
                  size: AppTypography.iconSizeHero,
                ),
                Text(
                  initial,
                  style: AppTypography.titleStyle.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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
                  Text(
                    email,
                    style: AppTypography.captionStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _chip(role.toString(), AppColors.info),
                      _chip(_resolvedTeamName, AppColors.primary),
                    ],
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

  Widget _buildContent() {
    final joinedAt = staffData['joinDate'] ?? staffData['createdAt'];
    final joinDate = joinedAt is Timestamp
        ? joinedAt.toDate().toString().split(' ')[0]
        : 'N/A';

    return Container(
      width: double.infinity,
      color: AppColors.surfaceVariant,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  Icons.phone_outlined,
                  'Phone',
                  staffData['phone'] ?? 'N/A',
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _infoTile(
                  Icons.location_on_outlined,
                  'Area',
                  staffData['areaCode'] ?? 'N/A',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  Icons.groups_outlined,
                  'Team',
                  _resolvedTeamName,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _infoTile(
                  Icons.event_outlined,
                  'Joined',
                  joinDate,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _resolvedTeamName {
    if (_isLoadingTeam) return 'Loading...';
    if (_teamName != null && _teamName!.isNotEmpty) return _teamName!;
    final teamId = staffData['teamId'];
    if (teamId == null || teamId.toString().isEmpty) return 'Not assigned';
    return 'Unknown team';
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: AppTypography.captionStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.textSecondary,
                size: AppTypography.iconSizeMd,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.captionStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.bodyMediumStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

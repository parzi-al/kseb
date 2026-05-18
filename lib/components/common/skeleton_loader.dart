import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_spacing.dart';

/// Custom shimmer animation that sweeps a highlight across child content.
///
/// Uses a gradient [LinearGradient] animated via [AnimationController].
/// No external package required.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const Shimmer({
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
    super.key,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect reduced-motion preferences
    if (MediaQuery.of(context).disableAnimations) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE9ECEF), // grey200
                Color(0xFFF8F9FA), // grey100 highlight
                Color(0xFFE9ECEF), // grey200
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single rectangular skeleton placeholder.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    this.width,
    this.height = 16,
    this.borderRadius = 4,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A circular skeleton placeholder (e.g. avatar, icon).
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({this.size = 40, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.grey200,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ─── Screen-specific skeleton layouts ───────────────────────────────

/// Skeleton matching WorkerHomeScreen: welcome header with greeting/name/role/
/// active badge, 2 stat cards, "Quick Actions" title, and 2×2 dashboard grid.
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome header (matches the surface Container) ──
            Container(
              width: double.infinity,
              color: AppColors.grey50,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        // Greeting text
                        SkeletonBox(width: 120, height: 14),
                        SizedBox(height: AppSpacing.sm),
                        // Name
                        SkeletonBox(width: 180, height: 26),
                        SizedBox(height: AppSpacing.sm),
                        // Role badge pill
                        SkeletonBox(
                            width: 90,
                            height: 28,
                            borderRadius: AppSpacing.radiusMd),
                      ],
                    ),
                  ),
                  // Active badge
                  const SkeletonBox(
                      width: 80,
                      height: 32,
                      borderRadius: AppSpacing.radiusPill),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // ── Stat cards row ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(child: _SkeletonStatCard()),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _SkeletonStatCard()),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // ── "Quick Actions" title ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: const SkeletonBox(width: 130, height: 20),
            ),
            const SizedBox(height: AppSpacing.lg),
            // ── Dashboard card grid ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                children:
                    List.generate(4, (_) => const _SkeletonDashboardCard()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonStatCard extends StatelessWidget {
  const _SkeletonStatCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container
          SkeletonBox(width: 42, height: 42, borderRadius: AppSpacing.radiusMd),
          const SizedBox(height: AppSpacing.md),
          // Value
          const SkeletonBox(width: 60, height: 26),
          const SizedBox(height: AppSpacing.xs),
          // Label
          const SkeletonBox(width: 90, height: 12),
        ],
      ),
    );
  }
}

class _SkeletonDashboardCard extends StatelessWidget {
  const _SkeletonDashboardCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkeletonBox(width: 40, height: 40, borderRadius: AppSpacing.radiusMd),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonBox(width: 80, height: 14),
        ],
      ),
    );
  }
}

/// Skeleton matching StaffManagementScreen staff tab: tall cards with avatar
/// circle, name, phone row, email row, and edit/delete buttons.
class StaffListSkeleton extends StatelessWidget {
  final int itemCount;

  const StaffListSkeleton({this.itemCount = 5, super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.base, AppSpacing.lg, AppSpacing.base, 100),
        itemCount: itemCount,
        itemBuilder: (_, __) => const _SkeletonStaffCard(),
      ),
    );
  }
}

class _SkeletonStaffCard extends StatelessWidget {
  const _SkeletonStaffCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar circle
            const SkeletonCircle(size: 48),
            const SizedBox(width: AppSpacing.base),
            // Name + phone + email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 140, height: 16),
                  const SizedBox(height: 6),
                  // Phone row (icon + text)
                  Row(
                    children: const [
                      SkeletonBox(width: 14, height: 14, borderRadius: 2),
                      SizedBox(width: 6),
                      SkeletonBox(width: 100, height: 13),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Email row (icon + text)
                  Row(
                    children: const [
                      SkeletonBox(width: 14, height: 14, borderRadius: 2),
                      SizedBox(width: 6),
                      SkeletonBox(width: 160, height: 13),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Edit/delete action buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SkeletonBox(
                    width: 32, height: 32, borderRadius: AppSpacing.radiusSm),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(
                    width: 32, height: 32, borderRadius: AppSpacing.radiusSm),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton matching Teams tab: cards with square team icon, team name,
/// area code + member count row, and edit/delete icon buttons.
class TeamListSkeleton extends StatelessWidget {
  final int itemCount;

  const TeamListSkeleton({this.itemCount = 4, super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.base),
        itemCount: itemCount,
        itemBuilder: (_, __) => const _SkeletonTeamCard(),
      ),
    );
  }
}

class _SkeletonTeamCard extends StatelessWidget {
  const _SkeletonTeamCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Team icon square
            SkeletonBox(
                width: 52, height: 52, borderRadius: AppSpacing.radiusMd),
            const SizedBox(width: AppSpacing.base),
            // Team info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 130, height: 16),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: const [
                      SkeletonBox(width: 14, height: 14, borderRadius: 2),
                      SizedBox(width: AppSpacing.xs),
                      SkeletonBox(width: 60, height: 13),
                      SizedBox(width: AppSpacing.md),
                      SkeletonBox(width: 14, height: 14, borderRadius: 2),
                      SizedBox(width: AppSpacing.xs),
                      SkeletonBox(width: 75, height: 13),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SkeletonBox(
                    width: 36, height: 36, borderRadius: AppSpacing.radiusPill),
                SizedBox(width: AppSpacing.xs),
                SkeletonBox(
                    width: 36, height: 36, borderRadius: AppSpacing.radiusPill),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic list skeleton for simple screens (attendance history, etc.).
class ListScreenSkeleton extends StatelessWidget {
  final int itemCount;
  final EdgeInsets padding;

  const ListScreenSkeleton({
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(AppSpacing.base),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        padding: padding,
        child: Column(
          children: List.generate(
            itemCount,
            (_) => const _SkeletonListTile(),
          ),
        ),
      ),
    );
  }
}

class _SkeletonListTile extends StatelessWidget {
  const _SkeletonListTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        ),
        child: Row(
          children: [
            const SkeletonCircle(size: 44),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 14),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(width: 140, height: 12),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const SkeletonBox(width: 60, height: 24, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}

/// Skeleton matching BonusManagementScreen: gradient header card with icon +
/// title + subtitle, then dropdown fields.
class BonusManagementSkeleton extends StatelessWidget {
  const BonusManagementSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              ),
              child: Column(
                children: const [
                  SkeletonCircle(size: 48),
                  SizedBox(height: AppSpacing.md),
                  SkeletonBox(width: 200, height: 20),
                  SizedBox(height: AppSpacing.sm),
                  SkeletonBox(width: 240, height: 14),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // "Select Team" label
            const SkeletonBox(width: 100, height: 16),
            const SizedBox(height: AppSpacing.md),
            // Team dropdown
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.grey200),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // "Select Employee" label
            const SkeletonBox(width: 130, height: 16),
            const SizedBox(height: AppSpacing.md),
            // Employee dropdown
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.grey200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton matching WorksheetScreen: circle icon header + title + subtitle,
/// then 2 grouped form cards (section header + input fields) + submit button.
class WorksheetSkeleton extends StatelessWidget {
  const WorksheetSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          // Header matching the actual screen
          Container(
            width: double.infinity,
            color: AppColors.grey50,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
            child: Column(
              children: const [
                SkeletonCircle(size: 80),
                SizedBox(height: AppSpacing.base),
                SkeletonBox(width: 160, height: 22),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 200, height: 14),
              ],
            ),
          ),
          // Form content
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card 1: "Project Details" section
                  _buildSkeletonFormCard(fieldCount: 3),
                  const SizedBox(height: AppSpacing.xl),
                  // Card 2: "Documentation" section
                  _buildSkeletonFormCard(fieldCount: 2),
                  const SizedBox(height: AppSpacing.xxl),
                  // Submit button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDefault),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSkeletonFormCard({required int fieldCount}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(color: AppColors.shadowLight, blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header (icon + title)
          Row(
            children: const [
              SkeletonBox(
                  width: 36, height: 36, borderRadius: AppSpacing.radiusSm),
              SizedBox(width: AppSpacing.md),
              SkeletonBox(width: 140, height: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          for (int i = 0; i < fieldCount; i++) ...[
            // Label
            SkeletonBox(width: 100 + (i * 15), height: 14),
            const SizedBox(height: AppSpacing.sm),
            // Text field
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            if (i < fieldCount - 1) const SizedBox(height: AppSpacing.base),
          ],
        ],
      ),
    );
  }
}

/// Skeleton matching AddMaterialScreen: circle icon header, then 3 grouped
/// form cards (Basic Info, Quantity & Pricing, Location) + submit button.
class AddMaterialSkeleton extends StatelessWidget {
  const AddMaterialSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.grey50,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
            child: Column(
              children: const [
                SkeletonCircle(size: 80),
                SizedBox(height: AppSpacing.base),
                SkeletonBox(width: 170, height: 24),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 220, height: 14),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WorksheetSkeleton._buildSkeletonFormCard(fieldCount: 3),
                  const SizedBox(height: AppSpacing.xl),
                  WorksheetSkeleton._buildSkeletonFormCard(fieldCount: 2),
                  const SizedBox(height: AppSpacing.xl),
                  WorksheetSkeleton._buildSkeletonFormCard(fieldCount: 2),
                  const SizedBox(height: AppSpacing.xxl),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDefault),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton matching WithdrawMaterialScreen: circle icon header, then 3
/// grouped cards (Material Selection, Project Details, Request Details) +
/// submit button.
class WithdrawMaterialSkeleton extends StatelessWidget {
  const WithdrawMaterialSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.grey50,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
            child: Column(
              children: const [
                SkeletonCircle(size: 80),
                SizedBox(height: AppSpacing.base),
                SkeletonBox(width: 180, height: 24),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 230, height: 14),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WorksheetSkeleton._buildSkeletonFormCard(fieldCount: 2),
                  const SizedBox(height: AppSpacing.xl),
                  WorksheetSkeleton._buildSkeletonFormCard(fieldCount: 2),
                  const SizedBox(height: AppSpacing.xl),
                  WorksheetSkeleton._buildSkeletonFormCard(fieldCount: 2),
                  const SizedBox(height: AppSpacing.xxl),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDefault),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton matching bonus history cards: icon circle + title/by-line, then
/// points/amount value row, then reason info box.
class BonusHistorySkeleton extends StatelessWidget {
  final int itemCount;

  const BonusHistorySkeleton({this.itemCount = 5, super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: List.generate(
            itemCount,
            (_) => const _SkeletonBonusCard(),
          ),
        ),
      ),
    );
  }
}

/// Skeleton matching AttendanceScreen: circle avatar in padded circle bg,
/// name, role badge, then stats 3-column card, calendar grid with day cells,
/// circular progress card, and full-width mark attendance button.
class AttendanceScreenSkeleton extends StatelessWidget {
  const AttendanceScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // ── Header (avatar in circle bg + name + role badge) ──
            Container(
              width: double.infinity,
              color: AppColors.grey50,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
              child: Column(
                children: [
                  // Avatar with circle background (matches primaryWithLowOpacity bg)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.grey300,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const SkeletonBox(width: 170, height: 24),
                  const SizedBox(height: AppSpacing.sm),
                  const SkeletonBox(
                      width: 100,
                      height: 30,
                      borderRadius: AppSpacing.radiusLg),
                ],
              ),
            ),
            // ── Content ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 100),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.lg),
                  // Stats card (3 columns: This Month / This Year / Status)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDefault),
                      boxShadow: [
                        BoxShadow(color: AppColors.shadowLight, blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: const [
                        _SkeletonStatColumn(),
                        _SkeletonStatColumn(),
                        _SkeletonStatColumn(),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Calendar (month header + day labels + 5 rows of cells)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.base),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDefault),
                      boxShadow: [
                        BoxShadow(color: AppColors.shadowLight, blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SkeletonBox(width: 140, height: 18),
                        const SizedBox(height: AppSpacing.md),
                        // Day-of-week labels
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(
                              7,
                              (_) => const SkeletonBox(
                                  width: 28, height: 14, borderRadius: 2)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // 5 rows of day cells
                        for (int row = 0; row < 5; row++) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: List.generate(
                                  7,
                                  (_) => const SkeletonBox(
                                      width: 32,
                                      height: 32,
                                      borderRadius: AppSpacing.radiusSm)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Progress card (title + circular indicator + count text)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.grey50,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(color: AppColors.shadowLight, blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SkeletonBox(width: 130, height: 16),
                        const SizedBox(height: AppSpacing.xl),
                        const SkeletonCircle(size: 160),
                        const SizedBox(height: AppSpacing.md),
                        const SkeletonBox(width: 190, height: 14),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Mark Attendance button
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDefault),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonStatColumn extends StatelessWidget {
  const _SkeletonStatColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SkeletonBox(width: 36, height: 26),
        SizedBox(height: AppSpacing.xs),
        SkeletonBox(width: 65, height: 12),
      ],
    );
  }
}

class _SkeletonBonusCard extends StatelessWidget {
  const _SkeletonBonusCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          border: Border.all(color: AppColors.grey200, width: 2),
          boxShadow: [
            BoxShadow(color: AppColors.shadowLight, blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle + title + by-line
            Row(
              children: [
                SkeletonBox(
                    width: 48, height: 48, borderRadius: AppSpacing.radiusMd),
                const SizedBox(width: AppSpacing.base),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 110, height: 16),
                      SizedBox(height: AppSpacing.xs),
                      SkeletonBox(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            // Points / Amount value row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: const [
                    SkeletonBox(width: 50, height: 12),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonBox(width: 40, height: 18),
                  ],
                ),
                Column(
                  children: const [
                    SkeletonBox(width: 55, height: 12),
                    SizedBox(height: AppSpacing.xs),
                    SkeletonBox(width: 60, height: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Reason info box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 50, height: 10),
                  SizedBox(height: 4),
                  SkeletonBox(height: 13),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// @Deprecated('Use WorksheetSkeleton, AddMaterialSkeleton, etc. instead')
/// Kept for backward-compatibility. Delegates to [WorksheetSkeleton].
class FormScreenSkeleton extends StatelessWidget {
  const FormScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const WorksheetSkeleton();
}

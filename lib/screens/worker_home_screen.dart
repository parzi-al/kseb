import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'staff_management_screen.dart';
import 'bonus_management_screen.dart';
import 'bonus_history_screen.dart';
import 'material_management_screen.dart';
import 'portal_module_screen.dart';
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/app_spacing.dart';
import '../utils/app_decorations.dart';
import '../utils/app_toast.dart';
import '../utils/feature_flags.dart';
import '../utils/page_transitions.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../components/common/skeleton_loader.dart';

const bool kEnableStaffDashboardForManagersAndSupervisors =
    bool.fromEnvironment('ENABLE_STAFF_DASHBOARD_FOR_MANAGERS_SUPERVISORS');

class WorkerHomeScreen extends StatefulWidget {
  /// Optional [AuthService] for dependency injection (used in tests).
  final AuthService? authService;

  const WorkerHomeScreen({super.key, this.authService});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final UserService _userService = UserService();
  late final AuthService _authService;

  String workerName = 'Worker';
  String workerRole = '';
  DateTime? workerDob;
  int bonusPoints = 0;
  double bonusAmount = 0.0;
  int monthlyHours = 0;
  int workingDaysThisMonth = 0;
  bool isLoading = true;
  bool isBirthday = false;
  bool isSupervisor = false;
  bool isCooOrDirector = false;
  String? workerId;
  String? teamId;
  StreamSubscription<DocumentSnapshot>? _bonusSubscription;

  late AnimationController _birthdayController;
  late Animation<double> _confettiAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _fetchWorkerData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _birthdayController.dispose();
    _bonusSubscription?.cancel();
    super.dispose();
  }

  /// Validate session when app resumes from background (FR-020 force-logout).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Session validation disabled: users should stay logged in even after app
    // is closed and reopened (use Firebase auth state as source of truth).
    // Single-session enforcement is still active for concurrent login detection
    // via session tokens, but only at the service/API level, not at the UI level.
  }

  void _initializeAnimations() {
    _birthdayController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _birthdayController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _birthdayController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _fetchWorkerData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Fetch user info from new 'users' collection
      final userModel = await _userService.getUserByEmail(user.email!);

      if (userModel != null) {
        workerId = userModel.id;
        workerName = userModel.name;
        workerRole = userModel.role.displayName;
        teamId = userModel.teamId;

        // Check if user is supervisor or higher
        isSupervisor = userModel.isSupervisor;

        // Check if user is COO or Director
        isCooOrDirector = userModel.role == UserRole.coo ||
            userModel.role == UserRole.director;

        // Fetch bonus points and amount
        await _fetchBonusData(workerId!);

        // DEBUG: Print role and visibility info
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('DEBUG: Staff Management Visibility Check');
        debugPrint('User Email: ${user.email}');
        debugPrint('User ID: $workerId');
        debugPrint('User Name: $workerName');
        debugPrint('User Role (enum): ${userModel.role.name}');
        debugPrint('User Role (display): $workerRole');
        debugPrint('Team ID: $teamId');
        debugPrint('isSupervisor: $isSupervisor');
        debugPrint(
            'Should show Staff Management: ${isSupervisor && teamId != null}');
        debugPrint('═══════════════════════════════════════════════════════');

        if (userModel.dob != null) {
          workerDob = userModel.dob;
          _checkBirthday();
        }
      }

      // Fetch attendance data
      await _fetchAttendanceStats(user.email!);

      setState(() {
        isLoading = false;
      });

      if (isBirthday) {
        _birthdayController.forward();
      }
    } catch (e) {
      debugPrint('Error fetching worker data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _checkBirthday() {
    if (workerDob == null) return;

    final now = DateTime.now();
    isBirthday = now.month == workerDob!.month && now.day == workerDob!.day;
  }

  Future<void> _fetchBonusData(String userId) async {
    try {
      // Cancel existing subscription if any
      await _bonusSubscription?.cancel();

      // Set up real-time listener for bonus updates
      _bonusSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && mounted) {
          final data = snapshot.data() as Map<String, dynamic>;
          setState(() {
            bonusPoints = data['bonusPoints'] ?? 0;
            bonusAmount = (data['bonusAmount'] ?? 0).toDouble();
          });
        }
      });
    } catch (e) {
      debugPrint('Error fetching bonus data: $e');
      setState(() {
        bonusPoints = 0;
        bonusAmount = 0.0;
      });
    }
  }

  Future<void> _fetchAttendanceStats(String email) async {
    final now = DateTime.now();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Monthly hours
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 1);

    final monthlyAttendance = await FirebaseFirestore.instance
        .collection('workers')
        .doc(user.uid)
        .collection('attendance')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('timestamp', isLessThan: Timestamp.fromDate(monthEnd))
        .orderBy('timestamp', descending: false)
        .get();

    // Calculate monthly hours and working days using enhanced logic
    Map<String, List<Map<String, dynamic>>> dailyAttendanceMap = {};

    for (var doc in monthlyAttendance.docs) {
      final data = doc.data();
      final timestamp = (data['timestamp'] as Timestamp).toDate();
      final day =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

      dailyAttendanceMap[day] ??= [];
      dailyAttendanceMap[day]!.add({
        'timestamp': timestamp,
      });
    }

    double totalMonthlyHours = 0.0;
    int workingDays = 0;

    dailyAttendanceMap.forEach((day, records) {
      // Extract just timestamps for each day
      List<DateTime> dayTimestamps =
          records.map((record) => record['timestamp'] as DateTime).toList();

      // Sort timestamps
      dayTimestamps.sort();

      double dayHours = 0.0;

      // Calculate hours for completed sessions (pairs of timestamps)
      for (int i = 0; i < dayTimestamps.length - 1; i += 2) {
        if (i + 1 < dayTimestamps.length) {
          final checkIn = dayTimestamps[i];
          final checkOut = dayTimestamps[i + 1];
          final duration = checkOut.difference(checkIn);
          dayHours += duration.inMinutes / 60.0;
        }
      }

      // Handle case where user is still checked in today
      if (dayTimestamps.length % 2 == 1 &&
          day ==
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}') {
        final lastCheckIn = dayTimestamps.last;
        final currentSessionDuration = now.difference(lastCheckIn);
        dayHours += currentSessionDuration.inMinutes / 60.0;
      }

      // Add to totals if there was actual work done
      if (dayHours > 0) {
        totalMonthlyHours += dayHours;
        workingDays++;
      }
    });

    monthlyHours = totalMonthlyHours.round();
    workingDaysThisMonth = workingDays;
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'director':
        return Icons.account_balance_rounded;
      case 'coo':
        return Icons.business_center_rounded;
      case 'manager':
        return Icons.manage_accounts_rounded;
      case 'supervisor':
        return Icons.supervisor_account_rounded;
      case 'staff':
        return Icons.person_rounded;
      default:
        return Icons.badge_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    String greeting = '';

    if (isBirthday) {
      greeting = '🎉 Happy Birthday';
    } else {
      final currentHour = DateTime.now().hour;
      if (currentHour < 12) {
        greeting = 'Good Morning';
      } else if (currentHour < 17) {
        greeting = 'Good Afternoon';
      } else {
        greeting = 'Good Evening';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadowLight,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.surface,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryWithLowOpacity,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: AppColors.primary,
                size: _getResponsiveIconSize(context, baseSize: 20),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Text(
              'AumLux Portal',
              style: context.responsiveTextStyle(AppTypography.headingStyle),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.md),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
              onPressed: () => _showLogoutDialog(context),
              tooltip: 'Logout',
            ),
          ),
        ],
      ),
      body: isLoading
          ? const HomeScreenSkeleton()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern Welcome Section
                  Container(
                    width: double.infinity,
                    color: AppColors.surface,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          context.responsivePadding(AppSpacing.xl),
                          context.responsivePadding(AppSpacing.xl),
                          context.responsivePadding(AppSpacing.xl),
                          context.responsivePadding(AppSpacing.xxl)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _scaleAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: isBirthday
                                              ? _scaleAnimation.value
                                              : 1.0,
                                          child: Text(
                                            greeting,
                                            style: TextStyle(
                                              color: isBirthday
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                              fontSize: context
                                                  .responsiveFontSize(isBirthday
                                                      ? AppTypography.fontSizeLG
                                                      : AppTypography
                                                          .fontSizeBase),
                                              fontWeight: isBirthday
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(
                                        height: context
                                            .responsiveSpacing(AppSpacing.xs)),
                                    AnimatedBuilder(
                                      animation: _scaleAnimation,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: isBirthday
                                              ? _scaleAnimation.value
                                              : 1.0,
                                          child: Text(
                                            isLoading
                                                ? 'Loading...'
                                                : workerName,
                                            style: context
                                                .responsiveTextStyle(
                                                    AppTypography.displayStyle)
                                                .copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                    if (workerRole.isNotEmpty) ...[
                                      SizedBox(
                                          height: context.responsiveSpacing(
                                              AppSpacing.xs)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.base,
                                            vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusMd),
                                          border: Border.all(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getRoleIcon(workerRole),
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              workerRole,
                                              style: context
                                                  .responsiveTextStyle(
                                                      AppTypography
                                                          .captionStyle)
                                                  .copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (isBirthday) ...[
                                      SizedBox(
                                          height: context.responsiveSpacing(
                                              AppSpacing.sm)),
                                      AnimatedBuilder(
                                        animation: _confettiAnimation,
                                        builder: (context, child) {
                                          return Opacity(
                                            opacity: _confettiAnimation.value,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal:
                                                          AppSpacing.base,
                                                      vertical: AppSpacing.sm),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppSpacing.radiusLg),
                                                border: Border.all(
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.2),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '🎂',
                                                    style: TextStyle(
                                                        fontSize: AppTypography
                                                            .fontSizeLG),
                                                  ),
                                                  const SizedBox(
                                                      width: AppSpacing.sm),
                                                  Flexible(
                                                    child: Text(
                                                      'Have a wonderful day!',
                                                      style: context
                                                          .responsiveTextStyle(
                                                              AppTypography
                                                                  .bodyMediumStyle)
                                                          .copyWith(
                                                            color: AppColors
                                                                .primary,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width: AppSpacing.xs),
                                                  Text(
                                                    '🎉',
                                                    style: TextStyle(
                                                        fontSize: AppTypography
                                                            .fontSizeBase),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.success.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.xl),
                                  border: Border.all(
                                    color: AppColors.success
                                        .withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      'Active',
                                      style: context
                                          .responsiveTextStyle(
                                              AppTypography.bodyMediumStyle)
                                          .copyWith(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: context.responsiveSpacing(AppSpacing.xl)),

                  // Modern Quick Stats Section
                  // Bonus Points and Bonus Amount hidden from homepage (to be enabled later)
                  // Padding(
                  //   padding: EdgeInsets.symmetric(
                  //       horizontal: context.responsivePadding(AppSpacing.lg)),
                  //   child: Row(
                  //     children: [
                  //       Expanded(
                  //         child: _buildStatCard(
                  //           context,
                  //           'Bonus Points',
                  //           isLoading ? '--' : bonusPoints.toString(),
                  //           Icons.star_rounded,
                  //           AppColors.statColors[0],
                  //         ),
                  //       ),
                  //       SizedBox(
                  //           width: context.responsiveSpacing(AppSpacing.md)),
                  //       Expanded(
                  //         child: _buildStatCard(
                  //           context,
                  //           'Bonus Amount',
                  //           isLoading
                  //               ? '--'
                  //               : '₹${bonusAmount.toStringAsFixed(2)}',
                  //           Icons.currency_rupee_rounded,
                  //           AppColors.statColors[1],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),

                  // SizedBox(height: context.responsiveSpacing(AppSpacing.xl)),

                  // Modern Menu Section
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.responsivePadding(AppSpacing.lg)),
                    child: Text(
                      'Quick Actions',
                      style:
                          context.responsiveTextStyle(AppTypography.titleStyle),
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing(AppSpacing.lg)),

                  // Modern Dashboard Cards
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: context.responsivePadding(AppSpacing.lg)),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: _getGridColumnCount(context),
                      crossAxisSpacing:
                          context.responsiveSpacing(AppSpacing.md),
                      mainAxisSpacing: context.responsiveSpacing(AppSpacing.md),
                      childAspectRatio: MediaQuery.of(context).size.height < 700
                          ? 1.25
                          : (MediaQuery.of(context).size.height < 800
                              ? 1.15
                              : 1.0),
                      children: [
                        ..._buildPortalModuleCards(context),
                        _buildDashboardCard(
                          context,
                          icon: Icons.inventory_2_rounded,
                          label: 'Material Request',
                          color: AppColors.dashboardCardColors[2],
                          destination: const MaterialManagementScreen(),
                        ),
                        if (_canShowStaffDashboard())
                          _buildDashboardCard(
                            context,
                            icon: Icons.people_rounded,
                            label: 'Staff Management',
                            color: AppColors.dashboardCardColors[2],
                            destination: StaffManagementScreen(
                              teamId: teamId,
                              currentUserRole: UserRole.fromString(workerRole),
                            ),
                          ),
                        if (FeatureFlags.enableBonusModule && isCooOrDirector)
                          _buildDashboardCard(
                            context,
                            icon: Icons.card_giftcard_rounded,
                            label: 'Bonus Management',
                            color:
                                Colors.purple, // DS-EXCEPTION: decorative color
                            destination: const BonusManagementScreen(),
                          ),
                        if (FeatureFlags.enableBonusModule && !isCooOrDirector)
                          _buildDashboardCard(
                            context,
                            icon: Icons.history_rounded,
                            label: 'My Bonus History',
                            color: Colors
                                .deepPurple, // DS-EXCEPTION: decorative color
                            destination: const BonusHistoryScreen(),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing(AppSpacing.xxl)),
                ],
              ),
            ),
    );
  }

  bool _canShowStaffDashboard() {
    final role = UserRole.fromString(workerRole);
    final isManagerOrSupervisor =
        role == UserRole.manager || role == UserRole.supervisor;

    if (kEnableStaffDashboardForManagersAndSupervisors) {
      return isManagerOrSupervisor && teamId != null;
    }

    return isSupervisor && teamId != null;
  }

  List<Widget> _buildPortalModuleCards(BuildContext context) {
    final role = UserRole.fromString(workerRole);

    if (role == UserRole.manager) {
      return [
        _portalCard(
          context,
          icon: Icons.electrical_services_rounded,
          label: 'Polevar',
          sections: _polevarSections(),
        ),
        _portalCard(
          context,
          icon: Icons.devices_other_rounded,
          label: 'Asset Details',
          sections: _assetSections(),
        ),
      ];
    }

    if (role == UserRole.coo) {
      return [
        _portalCard(
          context,
          icon: Icons.electrical_services_rounded,
          label: 'Polevar',
          sections: _polevarSections(),
        ),
        _portalCard(
          context,
          icon: Icons.receipt_long_rounded,
          label: 'EMD / SD',
          sections: _depositSections(),
        ),
        _portalCard(
          context,
          icon: Icons.description_rounded,
          label: 'Work Orders',
          sections: _workOrderSections(),
        ),
        _portalCard(
          context,
          icon: Icons.request_quote_rounded,
          label: 'Bills / Invoices',
          sections: _billInvoiceSections(),
        ),
        _portalCard(
          context,
          icon: Icons.devices_other_rounded,
          label: 'Asset Details',
          sections: _assetSections(),
        ),
      ];
    }

    if (role == UserRole.director) {
      return [
        _portalCard(
          context,
          icon: Icons.electrical_services_rounded,
          label: 'Polevar',
          sections: _polevarSections(),
        ),
        _portalCard(
          context,
          icon: Icons.receipt_long_rounded,
          label: 'EMD / SD',
          sections: _depositSections(),
        ),
        _portalCard(
          context,
          icon: Icons.description_rounded,
          label: 'Work Orders',
          sections: _workOrderSections(),
        ),
        _portalCard(
          context,
          icon: Icons.request_quote_rounded,
          label: 'Bills / Invoices',
          sections: _billInvoiceSections(),
        ),
        _portalCard(
          context,
          icon: Icons.folder_copy_rounded,
          label: 'Dispatch / Letter',
          sections: _dispatchSections(),
        ),
        _portalCard(
          context,
          icon: Icons.devices_other_rounded,
          label: 'Asset Details',
          sections: _assetSections(),
        ),
        _portalCard(
          context,
          icon: Icons.account_balance_rounded,
          label: 'GST Details',
          sections: _gstSections(),
        ),
        _portalCard(
          context,
          icon: Icons.analytics_rounded,
          label: 'View Details',
          sections: _viewDetailsSections(),
        ),
      ];
    }

    return const [];
  }

  List<PortalModuleSection> _polevarSections() => const [
        PortalModuleSection(
          title: 'Polevar Details',
          fields: [
            PortalModuleField(
              label: 'Pole Number',
              icon: Icons.confirmation_number_outlined,
              required: true,
            ),
            PortalModuleField(
              label: 'Feeder Name',
              icon: Icons.electrical_services_rounded,
              required: true,
            ),
            PortalModuleField(
              label: 'Transformer / DP Reference',
              icon: Icons.settings_input_component_rounded,
            ),
            PortalModuleField(
              label: 'Section Office',
              icon: Icons.location_city_rounded,
              type: PortalFieldType.dropdown,
              options: [
                'Electrical Section A',
                'Electrical Section B',
                'Electrical Section C'
              ],
              required: true,
            ),
            PortalModuleField(
              label: 'Pole Type',
              icon: Icons.account_tree_rounded,
              type: PortalFieldType.dropdown,
              options: ['PSC', 'RCC', 'A Pole', 'H Pole', 'Steel Tubular'],
            ),
            PortalModuleField(
              label: 'Location / Landmark',
              icon: Icons.place_outlined,
              required: true,
            ),
            PortalModuleField(
              label: 'GPS Coordinates',
              icon: Icons.my_location_rounded,
            ),
            PortalModuleField(
              label: 'Remarks',
              icon: Icons.notes_rounded,
              type: PortalFieldType.multiline,
            ),
            PortalModuleField(
              label: 'Upload Pole Photo',
              icon: Icons.photo_camera_rounded,
              type: PortalFieldType.upload,
            ),
          ],
        ),
      ];

  List<PortalModuleSection> _assetSections() => const [
        PortalModuleSection(
          title: 'Asset Details',
          fields: [
            PortalModuleField(
                label: 'Asset ID', icon: Icons.qr_code_rounded, required: true),
            PortalModuleField(
                label: 'Asset Name',
                icon: Icons.inventory_2_outlined,
                required: true),
            PortalModuleField(
              label: 'Asset Category',
              icon: Icons.category_rounded,
              type: PortalFieldType.dropdown,
              options: [
                'Tools',
                'Vehicle',
                'Safety Equipment',
                'Electrical Material',
                'Office Equipment'
              ],
              required: true,
            ),
            PortalModuleField(
                label: 'Serial Number', icon: Icons.numbers_rounded),
            PortalModuleField(
                label: 'Assigned To', icon: Icons.person_outline_rounded),
            PortalModuleField(
                label: 'Purchase Date',
                icon: Icons.event_rounded,
                type: PortalFieldType.date),
            PortalModuleField(
                label: 'Condition',
                icon: Icons.verified_outlined,
                type: PortalFieldType.dropdown,
                options: ['New', 'Good', 'Needs Repair', 'Damaged']),
            PortalModuleField(
                label: 'Upload Asset Document',
                icon: Icons.attach_file_rounded,
                type: PortalFieldType.upload),
          ],
        ),
      ];

  List<PortalModuleSection> _depositSections() => const [
        PortalModuleSection(
          title: 'EMD / Security Deposit',
          fields: [
            PortalModuleField(
                label: 'Deposit Type',
                icon: Icons.receipt_long_rounded,
                type: PortalFieldType.dropdown,
                options: ['EMD', 'Security Deposit'],
                required: true),
            PortalModuleField(
                label: 'Tender / Work Reference',
                icon: Icons.description_outlined,
                required: true),
            PortalModuleField(
                label: 'Amount',
                icon: Icons.currency_rupee_rounded,
                type: PortalFieldType.number,
                required: true),
            PortalModuleField(
                label: 'Payment Mode',
                icon: Icons.payments_outlined,
                type: PortalFieldType.dropdown,
                options: ['DD', 'Bank Guarantee', 'Online Transfer', 'Cheque'],
                required: true),
            PortalModuleField(
                label: 'Instrument / UTR Number', icon: Icons.tag_rounded),
            PortalModuleField(
                label: 'Deposit Date',
                icon: Icons.event_rounded,
                type: PortalFieldType.date),
            PortalModuleField(
                label: 'Validity Date',
                icon: Icons.event_available_rounded,
                type: PortalFieldType.date),
            PortalModuleField(
                label: 'Upload Receipt',
                icon: Icons.upload_file_rounded,
                type: PortalFieldType.upload,
                required: true),
          ],
        ),
      ];

  List<PortalModuleSection> _workOrderSections() => const [
        PortalModuleSection(
          title: 'Work Order / Agreement',
          fields: [
            PortalModuleField(
                label: 'Work Order Number',
                icon: Icons.confirmation_number_outlined,
                required: true),
            PortalModuleField(
                label: 'Agreement Number', icon: Icons.handshake_outlined),
            PortalModuleField(
                label: 'Project / Work Name',
                icon: Icons.work_outline_rounded,
                required: true),
            PortalModuleField(
                label: 'Awarded Amount',
                icon: Icons.currency_rupee_rounded,
                type: PortalFieldType.number),
            PortalModuleField(
                label: 'Issue Date',
                icon: Icons.event_rounded,
                type: PortalFieldType.date),
            PortalModuleField(
                label: 'Completion Due Date',
                icon: Icons.event_available_rounded,
                type: PortalFieldType.date),
            PortalModuleField(
                label: 'Current Status',
                icon: Icons.fact_check_outlined,
                type: PortalFieldType.dropdown,
                options: [
                  'Draft',
                  'Active',
                  'Completed',
                  'On Hold',
                  'Cancelled'
                ]),
            PortalModuleField(
                label: 'Upload Work Order / Agreement',
                icon: Icons.upload_file_rounded,
                type: PortalFieldType.upload,
                required: true),
          ],
        ),
      ];

  List<PortalModuleSection> _billInvoiceSections() => const [
        PortalModuleSection(
          title: 'Bill / Invoice Submission',
          fields: [
            PortalModuleField(
                label: 'Invoice Number',
                icon: Icons.receipt_outlined,
                required: true),
            PortalModuleField(
                label: 'Bill Type',
                icon: Icons.request_quote_outlined,
                type: PortalFieldType.dropdown,
                options: [
                  'Running Account Bill',
                  'Final Bill',
                  'Material Bill',
                  'Service Invoice'
                ],
                required: true),
            PortalModuleField(
                label: 'Work Order Number', icon: Icons.description_outlined),
            PortalModuleField(
                label: 'Invoice Date',
                icon: Icons.event_rounded,
                type: PortalFieldType.date),
            PortalModuleField(
                label: 'Invoice Amount',
                icon: Icons.currency_rupee_rounded,
                type: PortalFieldType.number,
                required: true),
            PortalModuleField(
                label: 'Tax Amount',
                icon: Icons.percent_rounded,
                type: PortalFieldType.number),
            PortalModuleField(
                label: 'Upload Bill / Invoice',
                icon: Icons.upload_file_rounded,
                type: PortalFieldType.upload,
                required: true),
            PortalModuleField(
                label: 'Notes',
                icon: Icons.notes_rounded,
                type: PortalFieldType.multiline),
          ],
        ),
      ];

  List<PortalModuleSection> _dispatchSections() => const [
        PortalModuleSection(
          title: 'Dispatch / Letter',
          fields: [
            PortalModuleField(
                label: 'Reference Number',
                icon: Icons.numbers_rounded,
                required: true),
            PortalModuleField(
                label: 'Document Type',
                icon: Icons.folder_copy_rounded,
                type: PortalFieldType.dropdown,
                options: [
                  'Incoming Letter',
                  'Outgoing Letter',
                  'Dispatch Note',
                  'Circular'
                ],
                required: true),
            PortalModuleField(
                label: 'From / To',
                icon: Icons.account_box_outlined,
                required: true),
            PortalModuleField(
                label: 'Subject', icon: Icons.subject_rounded, required: true),
            PortalModuleField(
                label: 'Received / Sent Date',
                icon: Icons.event_rounded,
                type: PortalFieldType.date),
            PortalModuleField(
                label: 'Upload Letter',
                icon: Icons.upload_file_rounded,
                type: PortalFieldType.upload,
                required: true),
            PortalModuleField(
                label: 'Remarks',
                icon: Icons.notes_rounded,
                type: PortalFieldType.multiline),
          ],
        ),
      ];

  List<PortalModuleSection> _gstSections() => const [
        PortalModuleSection(
          title: 'GST Details',
          fields: [
            PortalModuleField(
                label: 'GSTIN', icon: Icons.badge_outlined, required: true),
            PortalModuleField(
                label: 'Legal Name',
                icon: Icons.business_rounded,
                required: true),
            PortalModuleField(
                label: 'Return Period',
                icon: Icons.date_range_rounded,
                required: true),
            PortalModuleField(
                label: 'Taxable Value',
                icon: Icons.currency_rupee_rounded,
                type: PortalFieldType.number),
            PortalModuleField(
                label: 'CGST',
                icon: Icons.percent_rounded,
                type: PortalFieldType.number),
            PortalModuleField(
                label: 'SGST',
                icon: Icons.percent_rounded,
                type: PortalFieldType.number),
            PortalModuleField(
                label: 'IGST',
                icon: Icons.percent_rounded,
                type: PortalFieldType.number),
            PortalModuleField(
                label: 'Upload GST Filing / Certificate',
                icon: Icons.upload_file_rounded,
                type: PortalFieldType.upload,
                required: true),
          ],
        ),
      ];

  List<PortalModuleSection> _viewDetailsSections() => const [
        PortalModuleSection(
          title: 'Search Records',
          fields: [
            PortalModuleField(
                label: 'Module',
                icon: Icons.dashboard_customize_rounded,
                type: PortalFieldType.dropdown,
                options: [
                  'Polevar',
                  'EMD / SD',
                  'Work Orders',
                  'Bills / Invoices',
                  'Dispatch / Letter',
                  'Asset Details',
                  'GST Details'
                ]),
            PortalModuleField(
                label: 'Reference Number', icon: Icons.search_rounded),
            PortalModuleField(
                label: 'Status',
                icon: Icons.fact_check_outlined,
                type: PortalFieldType.dropdown,
                options: ['All', 'Draft', 'Submitted', 'Approved', 'Rejected']),
            PortalModuleField(
                label: 'From Date',
                icon: Icons.event_rounded,
                type: PortalFieldType.date),
            PortalModuleField(
                label: 'To Date',
                icon: Icons.event_available_rounded,
                type: PortalFieldType.date),
          ],
        ),
      ];

  Widget _portalCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required List<PortalModuleSection> sections,
  }) {
    return _buildDashboardCard(
      context,
      icon: icon,
      label: label,
      color: _portalCardColor(label),
      destination: PortalModuleScreen(
        title: label,
        icon: icon,
        sections: sections,
      ),
    );
  }

  Color _portalCardColor(String label) {
    switch (label) {
      case 'Polevar':
        return AppColors.dashboardCardColors[0];
      case 'EMD / SD':
        return AppColors.dashboardCardColors[1];
      case 'Work Orders':
        return AppColors.dashboardCardColors[2];
      case 'Bills / Invoices':
        return AppColors.dashboardCardColors[3];
      case 'Dispatch / Letter':
        return AppColors.purple;
      case 'Asset Details':
        return AppColors.success;
      case 'GST Details':
        return AppColors.warning;
      case 'View Details':
        return AppColors.info;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Widget destination,
  }) {
    void navigate() {
      Navigator.of(context).push(
        AppRoute(
          builder: (_) => destination,
        ),
      );
    }

    return RepaintBoundary(
      child: Container(
        decoration: AppDecorations.modernCardDecorationWithColor(color),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: navigate,
            borderRadius: BorderRadius.circular(
                MediaQuery.of(context).size.height < 700
                    ? AppSpacing.radiusMd
                    : AppSpacing.radiusDefault),
            child: Padding(
              padding:
                  EdgeInsets.all(context.responsivePadding(AppSpacing.base)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(
                        context.responsivePadding(AppSpacing.sm)),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.height < 700
                              ? AppSpacing.radiusSm
                              : AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      icon,
                      size: _getResponsiveIconSize(context),
                      color: color,
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing(AppSpacing.sm)),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: context
                        .responsiveTextStyle(AppTypography.bodyMediumStyle)
                        .copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Get responsive icon size based on screen dimensions.
  /// Scales more aggressively on desktop (Windows) than on mobile.
  double _getResponsiveIconSize(BuildContext context, {double baseSize = 20}) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Desktop screens (Windows typically > 1000px width)
    if (screenWidth > 1000) {
      return baseSize * 1.5; // 50% larger on desktop
    }
    // Tablet screens
    else if (screenWidth > 600) {
      return baseSize * 1.2; // 20% larger on tablet
    }
    // Mobile screens
    else {
      return baseSize;
    }
  }

  /// Get responsive grid column count based on screen width.
  /// Windows/desktop: 3 columns, Tablet: 2 columns, Mobile: 2 columns
  int _getGridColumnCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return 3; // Desktop: 3 columns
    }
    return 2; // Tablet & mobile: 2 columns
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _authService.signOut(reason: 'user_initiated');
                  // AuthGate StreamBuilder handles navigation automatically
                } catch (e) {
                  if (context.mounted) {
                    AppErrorHandler.handleError(context, e,
                        customMessage: 'Logout failed');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}

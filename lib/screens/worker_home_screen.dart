import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'attendance_screen.dart';
import 'material_management_screen.dart';
import 'worksheet_screen.dart';
import 'staff_management_screen.dart';
import 'bonus_management_screen.dart';
import 'bonus_history_screen.dart';
import '../utils/app_colors.dart';
import '../utils/app_toast.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen>
    with TickerProviderStateMixin {
  final UserService _userService = UserService();

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
    _initializeAnimations();
    _fetchWorkerData();
  }

  @override
  void dispose() {
    _birthdayController.dispose();
    _bonusSubscription?.cancel();
    super.dispose();
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
        print('═══════════════════════════════════════════════════════');
        print('DEBUG: Staff Management Visibility Check');
        print('User Email: ${user.email}');
        print('User ID: $workerId');
        print('User Name: $workerName');
        print('User Role (enum): ${userModel.role.name}');
        print('User Role (display): $workerRole');
        print('Team ID: $teamId');
        print('isSupervisor: $isSupervisor');
        print(
            'Should show Staff Management: ${isSupervisor && teamId != null}');
        print('═══════════════════════════════════════════════════════');

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
      print('Error fetching worker data: $e');
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
      print('Error fetching bonus data: $e');
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

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0.5,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          shadowColor: AppColors.shadowLight,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryWithLowOpacity,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primary,
                  size: AppColors.getResponsiveHeight(context, 20),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'KSEB Portal',
                style: AppColors.getResponsiveTextStyle(
                    context, AppColors.headingStyle),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
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
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Welcome Section
              Container(
                width: double.infinity,
                color: AppColors.surface,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                      AppColors.getResponsivePadding(context, 24),
                      AppColors.getResponsivePadding(context, 24),
                      AppColors.getResponsivePadding(context, 24),
                      AppColors.getResponsivePadding(context, 32)),
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
                                          fontSize:
                                              AppColors.getResponsiveFontSize(
                                                  context,
                                                  isBirthday
                                                      ? AppColors.fontSizeLG
                                                      : AppColors.fontSizeBase),
                                          fontWeight: isBirthday
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                SizedBox(
                                    height: AppColors.getResponsiveSpacing(
                                        context, 4)),
                                AnimatedBuilder(
                                  animation: _scaleAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: isBirthday
                                          ? _scaleAnimation.value
                                          : 1.0,
                                      child: Text(
                                        isLoading ? 'Loading...' : workerName,
                                        style: AppColors.getResponsiveTextStyle(
                                                context, AppColors.displayStyle)
                                            .copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (workerRole.isNotEmpty) ...[
                                  SizedBox(
                                      height: AppColors.getResponsiveSpacing(
                                          context, 4)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
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
                                          style:
                                              AppColors.getResponsiveTextStyle(
                                                      context,
                                                      AppColors.captionStyle)
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
                                      height: AppColors.getResponsiveSpacing(
                                          context, 8)),
                                  AnimatedBuilder(
                                    animation: _confettiAnimation,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: _confettiAnimation.value,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
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
                                                    fontSize:
                                                        AppColors.fontSizeLG),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  'Have a wonderful day!',
                                                  style: AppColors
                                                          .getResponsiveTextStyle(
                                                              context,
                                                              AppColors
                                                                  .bodyMediumStyle)
                                                      .copyWith(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '🎉',
                                                style: TextStyle(
                                                    fontSize:
                                                        AppColors.fontSizeBase),
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
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.2),
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
                                const SizedBox(width: 8),
                                Text(
                                  'Active',
                                  style: AppColors.getResponsiveTextStyle(
                                          context, AppColors.bodyMediumStyle)
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

              SizedBox(height: AppColors.getResponsiveSpacing(context, 24)),

              // Modern Quick Stats Section
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppColors.getResponsivePadding(context, 20.0)),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Bonus Points',
                        isLoading ? '--' : bonusPoints.toString(),
                        Icons.star_rounded,
                        AppColors.statColors[0],
                      ),
                    ),
                    SizedBox(
                        width: AppColors.getResponsiveSpacing(context, 16)),
                    Expanded(
                      child: _buildStatCard(
                        'Bonus Amount',
                        isLoading ? '--' : '₹${bonusAmount.toStringAsFixed(2)}',
                        Icons.currency_rupee_rounded,
                        AppColors.statColors[1],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppColors.getResponsiveSpacing(context, 24)),

              // Modern Menu Section
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppColors.getResponsivePadding(context, 20.0)),
                child: Text(
                  'Quick Actions',
                  style: AppColors.getResponsiveTextStyle(
                      context, AppColors.titleStyle),
                ),
              ),
              SizedBox(height: AppColors.getResponsiveSpacing(context, 20)),

              // Modern Dashboard Cards
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppColors.getResponsivePadding(context, 20.0)),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppColors.getResponsiveSpacing(context, 16),
                  mainAxisSpacing: AppColors.getResponsiveSpacing(context, 16),
                  childAspectRatio: MediaQuery.of(context).size.height < 700
                      ? 1.25
                      : (MediaQuery.of(context).size.height < 800 ? 1.15 : 1.0),
                  children: [
                    if (isSupervisor && teamId != null)
                      _buildDashboardCard(
                        context,
                        icon: Icons.people_rounded,
                        label: 'Staff Management',
                        color: AppColors.dashboardCardColors[2],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => StaffManagementScreen(
                                teamId: teamId,
                                currentUserRole: UserRole.fromString(
                                    workerRole.toLowerCase()),
                              ),
                            ),
                          );
                        },
                      ),
                    if (isCooOrDirector)
                      _buildDashboardCard(
                        context,
                        icon: Icons.card_giftcard_rounded,
                        label: 'Bonus Management',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const BonusManagementScreen(),
                            ),
                          );
                        },
                      ),
                    if (!isCooOrDirector)
                      _buildDashboardCard(
                        context,
                        icon: Icons.history_rounded,
                        label: 'My Bonus History',
                        color: Colors.deepPurple,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const BonusHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    _buildDashboardCard(
                      context,
                      icon: Icons.fingerprint,
                      label: 'Attendance',
                      color: AppColors.dashboardCardColors[0],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AttendanceScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      icon: Icons.assignment_rounded,
                      label: 'Daily Worksheet',
                      color: AppColors.dashboardCardColors[1],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const WorksheetScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      context,
                      icon: Icons.inventory_2_rounded,
                      label: 'Material Request',
                      color: AppColors.dashboardCardColors[2],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const MaterialManagementScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppColors.getResponsiveSpacing(context, 32)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: AppColors.modernCardDecorationWithColor(color),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
              MediaQuery.of(context).size.height < 700 ? 12 : 16),
          child: Padding(
            padding:
                EdgeInsets.all(AppColors.getResponsivePadding(context, 12.0)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(
                      AppColors.getResponsivePadding(context, 8)),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.height < 700 ? 8 : 12),
                  ),
                  child: Icon(
                    icon,
                    size: AppColors.getResponsiveHeight(context, 20),
                    color: color,
                  ),
                ),
                SizedBox(height: AppColors.getResponsiveSpacing(context, 8)),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppColors.getResponsiveTextStyle(
                          context, AppColors.bodyMediumStyle)
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
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(AppColors.getResponsivePadding(context, 20)),
      decoration: AppColors.modernCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    EdgeInsets.all(AppColors.getResponsivePadding(context, 10)),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    color: color,
                    size: AppColors.getResponsiveHeight(context, 22)),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: AppColors.getResponsiveSpacing(context, 16)),
          value == '--'
              ? Container(
                  width: 40,
                  height: 28,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.grey200,
                    valueColor: AlwaysStoppedAnimation(color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              : Text(
                  value,
                  style: AppColors.getResponsiveTextStyle(
                          context, AppColors.displayStyle)
                      .copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
          SizedBox(height: AppColors.getResponsiveSpacing(context, 4)),
          Text(
            title,
            style: AppColors.getResponsiveTextStyle(
                    context, AppColors.captionStyle)
                .copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await FirebaseAuth.instance.signOut();
                  // The StreamBuilder in main.dart will automatically handle navigation
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
                  borderRadius: BorderRadius.circular(12),
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

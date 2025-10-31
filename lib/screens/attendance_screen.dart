import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/app_colors.dart';
import '../utils/app_toast.dart';
import '../services/attendance_service.dart';
import '../models/user_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Services
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AttendanceService _attendanceService = AttendanceService();

  // State variables
  String _userName = 'Loading...';
  UserRole? _userRole;
  int _daysPresent = 0;
  int _thisMonthPresent = 0;
  int _thisYearPresent = 0;
  final int _totalDaysInYear = 240; // Working days in a year
  bool _isLoading = true;
  bool _isMarkedToday = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchWorkerData();
  }

  /// Fetches user's data and attendance statistics from Firestore.
  Future<void> _fetchWorkerData() async {
    setState(() {
      _isLoading = true;
    });

    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      _userId = user.uid;
      try {
        // Fetch user profile from 'users' collection
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(_userId).get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;
          _userName = data?['name'] ?? user.email ?? 'No name found';
          _userRole = UserRole.fromString(data?['role'] ?? 'staff');
        } else {
          _userName = user.email ?? 'No name found';
          _userRole = UserRole.staff;
        }

        // Fetch attendance statistics using attendance service
        final stats = await _attendanceService.getUserAttendanceStats(_userId!);
        _daysPresent = stats['total'] ?? 0;
        _thisMonthPresent = stats['thisMonth'] ?? 0;
        _thisYearPresent = stats['thisYear'] ?? 0;
        _isMarkedToday = stats['isMarkedToday'] ?? false;
      } catch (e) {
        _userName = "Error loading data";
        _daysPresent = 0;
        _thisMonthPresent = 0;
        _thisYearPresent = 0;
        if (mounted) {
          AppToast.showError(context, 'Error fetching user data: $e');
        }
      }
    } else {
      _userName = "Not Logged In";
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Authenticates with biometrics and then records attendance.
  Future<void> _authenticateAndMarkAttendance() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to mark attendance',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // Use only biometrics (fingerprint, face ID)
        ),
      );
    } on PlatformException catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
            context, e.message ?? 'Biometric authentication error');
      }
      return;
    }

    if (!mounted) return;

    if (authenticated) {
      await _recordAttendance();
    } else {
      AppToast.showError(
          context, 'Fingerprint authentication failed. Please try again.');
    }
  }

  /// Records an attendance entry in Firestore for the current day.
  Future<void> _recordAttendance() async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _attendanceService.markAttendance(userId: _userId!);
      
      if (mounted) {
        AppToast.showSuccess(context, 'Attendance marked successfully! 🎉');
        // Refresh the data on screen after marking attendance
        await _fetchWorkerData();
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('already marked')) {
          AppToast.showWarning(context, 'Attendance already marked for today.');
        } else {
          AppToast.showError(context, 'Error marking attendance: $e');
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double attendancePercentage =
        _totalDaysInYear > 0 ? (_thisYearPresent / _totalDaysInYear) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mark Attendance',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadowLight,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : Column(
              children: [
                // Modern Header Section
                Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primaryWithLowOpacity,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _userName,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryWithLowOpacity,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _userRole?.displayName ?? 'KSEB Staff',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Scrollable Content Section
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // Statistics Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'This Month',
                                '$_thisMonthPresent days',
                                Icons.calendar_month_rounded,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'This Year',
                                '$_thisYearPresent days',
                                Icons.calendar_today_rounded,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Total',
                                '$_daysPresent days',
                                Icons.check_circle_rounded,
                                Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Status',
                                _isMarkedToday ? 'Marked' : 'Not Marked',
                                Icons.today_rounded,
                                _isMarkedToday ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Progress Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cardShadow,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Yearly Progress',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              CircularPercentIndicator(
                                radius: 80.0,
                                lineWidth: 10.0,
                                percent: attendancePercentage,
                                center: Text(
                                  "${(attendancePercentage * 100).toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.0,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                circularStrokeCap: CircularStrokeCap.round,
                                progressColor: AppColors.primary,
                                backgroundColor:
                                    AppColors.primaryWithLowOpacity,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "$_thisYearPresent / $_totalDaysInYear Working Days",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Fingerprint Button
                        Opacity(
                          opacity: _isMarkedToday ? 0.5 : 1.0,
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isMarkedToday
                                    ? [Colors.grey, Colors.grey.shade600]
                                    : [
                                        AppColors.primary,
                                        AppColors.primaryLight
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _isMarkedToday
                                      ? Colors.grey.withValues(alpha: 0.3)
                                      : AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isMarkedToday
                                    ? null
                                    : _authenticateAndMarkAttendance,
                                borderRadius: BorderRadius.circular(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isMarkedToday
                                          ? Icons.check_circle_rounded
                                          : Icons.fingerprint_rounded,
                                      color: AppColors.textOnDark,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isMarkedToday
                                          ? 'Already Marked Today'
                                          : 'Mark Attendance',
                                      style: TextStyle(
                                        color: AppColors.textOnDark,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Test Button for Development (bypasses biometric auth)
                        if (!_isMarkedToday)
                          Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: AppColors.warning, width: 2),
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.warning.withValues(alpha: 0.1),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _recordAttendance,
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bug_report_rounded,
                                    color: AppColors.warning,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Test Mode - Mark Without Biometric',
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Build a statistics card widget
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

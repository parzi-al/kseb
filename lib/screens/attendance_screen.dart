import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/app_colors.dart';
import '../utils/app_toast.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Firebase and Local Auth instances
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  String _workerName = 'Loading...';
  int _daysPresent = 0;
  final int _totalDays = 240; // Can be fetched from a config document if needed
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchWorkerData();
  }

  /// Fetches worker's name and attendance count from Firestore.
  Future<void> _fetchWorkerData() async {
    setState(() {
      _isLoading = true;
    });

    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      _userId = user.uid;
      try {
        // Fetch worker profile document
        DocumentSnapshot workerDoc =
            await _firestore.collection('workers').doc(_userId).get();

        if (workerDoc.exists) {
          final data = workerDoc.data() as Map<String, dynamic>?;
          _workerName = data?['name'] ?? user.email ?? 'No name found';
        } else {
          _workerName = user.email ?? 'No name found';
        }

        // Fetch attendance records
        QuerySnapshot attendanceSnapshot = await _firestore
            .collection('workers')
            .doc(_userId)
            .collection('attendance')
            .get();

        _daysPresent = attendanceSnapshot.docs.length;
      } catch (e) {
        _workerName = "Error loading data";
        _daysPresent = 0;
        if (mounted) {
          AppErrorHandler.handleError(context, e,
              customMessage: 'Error fetching worker data');
        }
      }
    } else {
      _workerName = "Not Logged In";
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final attendanceCollection =
        _firestore.collection('workers').doc(_userId).collection('attendance');

    // Check if attendance was already marked today to prevent duplicates
    final querySnapshot = await attendanceCollection
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where(
          'timestamp',
          isLessThan: Timestamp.fromDate(today.add(const Duration(days: 1))),
        )
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      AppToast.showWarning(context, 'Attendance already marked for today.');
    } else {
      // Add a new attendance record with a server timestamp
      await attendanceCollection.add({
        'timestamp': FieldValue.serverTimestamp(),
      });
      AppToast.showSuccess(context, 'Attendance marked successfully! 🎉');
      // Refresh the data on screen after marking attendance
      await _fetchWorkerData();
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
        _totalDays > 0 ? (_daysPresent / _totalDays) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mark Attendance',
          style: AppColors.getResponsiveTextStyle(context, AppColors.headingStyle),
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
                    padding: EdgeInsets.fromLTRB(
                      AppColors.getResponsivePadding(context, 12), 
                      AppColors.getResponsivePadding(context, 12), 
                      AppColors.getResponsivePadding(context, 12), 
                      AppColors.getResponsivePadding(context, 16)
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(AppColors.getResponsivePadding(context, 8)),
                          decoration: BoxDecoration(
                            color: AppColors.primaryWithLowOpacity,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: AppColors.getResponsiveHeight(context, 32),
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: AppColors.getResponsiveSpacing(context, 16)),
                        Text(
                          _workerName,
                          style: AppColors.getResponsiveTextStyle(context, AppColors.displayStyle).copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: AppColors.getResponsiveSpacing(context, 8)),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppColors.getResponsivePadding(context, 8), 
                              vertical: AppColors.getResponsiveSpacing(context, 4)),
                          decoration: BoxDecoration(
                            color: AppColors.primaryWithLowOpacity,
                            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height < 700 ? 12 : 20),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'KSEB Worker',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: AppColors.getResponsiveFontSize(context, AppColors.fontSizeSM),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content Section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(AppColors.getResponsivePadding(context, 12.0)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Progress Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(AppColors.getResponsivePadding(context, 12)),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height < 700 ? 16 : 20),
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
                                'Attendance Progress',
                                style: AppColors.getResponsiveTextStyle(context, AppColors.titleStyle).copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: AppColors.getResponsiveSpacing(context, 18)),
                              CircularPercentIndicator(
                                radius: AppColors.getResponsiveHeight(context, 50),
                                lineWidth: AppColors.getResponsiveHeight(context, 6),
                                percent: attendancePercentage,
                                center: Text(
                                  "${(attendancePercentage * 100).toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppColors.getResponsiveFontSize(context, AppColors.fontSizeLG),
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                circularStrokeCap: CircularStrokeCap.round,
                                progressColor: AppColors.primary,
                                backgroundColor:
                                    AppColors.primaryWithLowOpacity,
                              ),
                              SizedBox(height: AppColors.getResponsiveSpacing(context, 14)),
                              Text(
                                "$_daysPresent / $_totalDays Days Present",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppColors.getResponsiveFontSize(context, AppColors.fontSizeBase),
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action Buttons Section
                        Column(
                          children: [
                            // Fingerprint Button
                            Container(
                              width: double.infinity,
                              height: AppColors.getResponsiveHeight(context, 44),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryLight
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height < 700 ? 12 : 16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _authenticateAndMarkAttendance,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.fingerprint_rounded,
                                        color: AppColors.textOnDark,
                                        size: AppColors.getResponsiveHeight(context, 20),
                                      ),
                                      SizedBox(width: AppColors.getResponsiveSpacing(context, 12)),
                                      Text(
                                        'Mark Attendance',
                                        style: TextStyle(
                                          color: AppColors.textOnDark,
                                          fontSize: AppColors.getResponsiveFontSize(context, AppColors.fontSizeLG),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: AppColors.getResponsiveSpacing(context, 16)),
                            // Test Button for Development (bypasses biometric auth)
                            Container(
                              width: double.infinity,
                              height: AppColors.getResponsiveHeight(context, 36),
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
                                        size: AppColors.getResponsiveHeight(context, 14),
                                      ),
                                      SizedBox(width: AppColors.getResponsiveSpacing(context, 8)),
                                      Text(
                                        'Test Mode - Mark Without Biometric',
                                        style: TextStyle(
                                          color: AppColors.warning,
                                          fontSize: AppColors.getResponsiveFontSize(context, AppColors.fontSizeSM),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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

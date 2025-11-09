import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
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
  List<AttendanceRecord> _attendanceRecords = [];
  bool _showHistory = false; // Toggle between main view and history

  // Calendar view variables
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, bool> _attendanceMap = {}; // Date -> attended or not
  final Set<DateTime> _publicHolidays = {};

  @override
  void initState() {
    super.initState();
    _initializePublicHolidays();
    _fetchWorkerData();
  }

  /// Initialize Indian public holidays for 2025
  void _initializePublicHolidays() {
    final year = DateTime.now().year;

    // Major Indian Public Holidays
    _publicHolidays.addAll([
      // Republic Day
      DateTime(year, 1, 26),
      // Holi (approximate - varies by lunar calendar)
      DateTime(year, 3, 14),
      // Good Friday
      DateTime(year, 4, 18),
      // Eid al-Fitr (approximate - varies by lunar calendar)
      DateTime(year, 4, 1),
      // May Day
      DateTime(year, 5, 1),
      // Independence Day
      DateTime(year, 8, 15),
      // Janmashtami (approximate)
      DateTime(year, 8, 26),
      // Gandhi Jayanti
      DateTime(year, 10, 2),
      // Dussehra (approximate)
      DateTime(year, 10, 13),
      // Diwali (approximate)
      DateTime(year, 11, 1),
      // Guru Nanak Jayanti (approximate)
      DateTime(year, 11, 15),
      // Christmas
      DateTime(year, 12, 25),
    ]);
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

        // Fetch attendance history
        await _fetchAttendanceHistory();
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

  /// Fetches attendance history records
  Future<void> _fetchAttendanceHistory() async {
    if (_userId == null) {
      return;
    }

    try {
      // Fetch attendance records from the flat 'attendance' collection
      // Filter by userId only (to avoid needing a composite index)
      QuerySnapshot attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: _userId)
          .get();

      // Filter for present status and convert to records
      _attendanceRecords = attendanceSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['status'] == 'present';
      }).map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AttendanceRecord(
          id: doc.id,
          timestamp:
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      // Sort by timestamp descending (newest first)
      _attendanceRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Build attendance map for calendar view
      _attendanceMap.clear();
      for (var record in _attendanceRecords) {
        // Convert to local date and normalize to midnight
        final localDate = record.timestamp.toLocal();
        final dateOnly = DateTime(
          localDate.year,
          localDate.month,
          localDate.day,
        );
        _attendanceMap[dateOnly] = true;
      }
    } catch (e) {
      _attendanceRecords = [];
      _attendanceMap = {};
    }
  }

  /// Authenticates with biometrics and then records attendance.
  Future<void> _authenticateAndMarkAttendance() async {
    // Check if current time is within valid attendance hours (00:00 - 23:59)
    final now = DateTime.now();
    if (!_isWithinAttendanceHours(now)) {
      if (mounted) {
        AppToast.showError(
            context, 'Attendance can only be marked between 00:00 and 23:59.');
      }
      return;
    }

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

    // Check if current time is within valid attendance hours
    final now = DateTime.now();
    if (!_isWithinAttendanceHours(now)) {
      if (mounted) {
        AppToast.showError(
            context, 'Attendance can only be marked between 00:00 and 23:59.');
      }
      return;
    }

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

  /// Check if current time is within valid attendance hours (00:00 - 23:59)
  bool _isWithinAttendanceHours(DateTime dateTime) {
    // Attendance is valid for the entire day (00:00:00 to 23:59:59)
    // The attendance service already checks if it's the current day
    // So this validation is redundant for now, but kept for future customization

    // If you want to restrict to specific hours, uncomment and modify:
    // final hour = dateTime.hour;
    // return hour >= 0 && hour <= 23; // 00:00 to 23:59

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Attendance',
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
        actions: [
          if (_attendanceRecords.isNotEmpty)
            IconButton(
              icon: Icon(
                _showHistory ? Icons.dashboard : Icons.history_rounded,
                color: AppColors.primary,
              ),
              onPressed: () {
                setState(() {
                  _showHistory = !_showHistory;
                });
              },
              tooltip: _showHistory ? 'Show Dashboard' : 'Show History',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _showHistory
              ? _buildHistoryView()
              : _buildMainView(),
    );
  }

  /// Build the main attendance view
  Widget _buildMainView() {
    final double attendancePercentage =
        _totalDaysInYear > 0 ? (_thisYearPresent / _totalDaysInYear) : 0.0;

    return Column(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                // Calendar View Section
                _buildCalendarSection(),
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
                        backgroundColor: AppColors.primaryWithLowOpacity,
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
                            : [AppColors.primary, AppColors.primaryLight],
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
                      border: Border.all(color: AppColors.warning, width: 2),
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
    );
  }

  /// Build the calendar section showing attendance history
  Widget _buildCalendarSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Attendance History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TableCalendar(
            firstDay: DateTime(DateTime.now().year, 1, 1),
            lastDay: DateTime(DateTime.now().year, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            calendarStyle: CalendarStyle(
              // Today's date
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              // Selected date
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.bold,
              ),
              // Weekend dates
              weekendTextStyle: TextStyle(
                color: AppColors.error.withValues(alpha: 0.7),
              ),
              // Outside dates
              outsideDaysVisible: false,
              // Default text style
              defaultTextStyle: TextStyle(
                color: AppColors.textPrimary,
              ),
              // Marked days (attendance)
              markerDecoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: AppColors.primary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: AppColors.primary,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: AppColors.error.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                return _buildCalendarDay(day, false, false);
              },
              todayBuilder: (context, day, focusedDay) {
                return _buildCalendarDay(day, true, false);
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildCalendarDay(day, false, true);
              },
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  /// Build individual calendar day cell
  Widget _buildCalendarDay(DateTime day, bool isToday, bool isSelected) {
    // Normalize the day to midnight local time for comparison
    final dateOnly = DateTime(day.year, day.month, day.day);
    final hasAttendance = _attendanceMap[dateOnly] == true;
    final isHoliday = _publicHolidays.contains(dateOnly);
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    Color? backgroundColor;
    Color? borderColor;
    Color textColor = AppColors.textPrimary;

    if (isSelected) {
      backgroundColor = AppColors.primary;
      textColor = AppColors.textOnDark;
      if (hasAttendance) {
        // Show green border for selected day with attendance
        borderColor = AppColors.success;
      }
    } else if (hasAttendance) {
      // Green background with border for days with attendance (including today if marked)
      backgroundColor = AppColors.success.withValues(alpha: 0.25);
      borderColor = AppColors.success;
      textColor = AppColors.success;
    } else if (isToday) {
      // Orange/primary color for today only if attendance not marked
      backgroundColor = AppColors.primary.withValues(alpha: 0.2);
      borderColor = AppColors.primary;
    } else if (isHoliday) {
      backgroundColor = AppColors.warning.withValues(alpha: 0.15);
      textColor = AppColors.warning;
    } else if (isWeekend) {
      textColor = AppColors.error.withValues(alpha: 0.6);
    }

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2)
            : null,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: isToday || isSelected || hasAttendance
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            // Add a larger green dot indicator at the bottom for attendance
            if (hasAttendance && !isSelected)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.5),
                        blurRadius: 2,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build legend for calendar
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                color: AppColors.success,
                label: 'Present',
              ),
              _buildLegendItem(
                color: AppColors.warning,
                label: 'Holiday',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(
                color: AppColors.primary,
                label: 'Today',
              ),
              _buildLegendItem(
                color: AppColors.textSecondary,
                label: 'Absent',
                isAbsent: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool isAbsent = false,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isAbsent ? Colors.transparent : color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: isAbsent ? color : color,
              width: 2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Build the attendance history view
  Widget _buildHistoryView() {
    return Column(
      children: [
        // Header Section
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
                    Icons.history_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Attendance History',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWithLowOpacity,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_attendanceRecords.length} total records',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Content Section
        Expanded(
          child: _attendanceRecords.isEmpty
              ? _buildEmptyState()
              : _buildAttendanceList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryWithLowOpacity,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Attendance Records',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start marking your attendance to see your history here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    return RefreshIndicator(
      onRefresh: _fetchWorkerData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _attendanceRecords.length,
        itemBuilder: (context, index) {
          final record = _attendanceRecords[index];
          final isToday = _isToday(record.timestamp);
          final isThisWeek = _isThisWeek(record.timestamp);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: isToday
                    ? Border.all(color: AppColors.success, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cardShadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.success.withValues(alpha: 0.1)
                        : isThisWeek
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.grey300.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isToday
                        ? Icons.today_rounded
                        : Icons.check_circle_outline_rounded,
                    color: isToday
                        ? AppColors.success
                        : isThisWeek
                            ? AppColors.primary
                            : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                title: Text(
                  DateFormat('EEEE, MMMM d, y').format(record.timestamp),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('h:mm a').format(record.timestamp),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Today',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Text(
                  _getRelativeTime(record.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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

class AttendanceRecord {
  final String id;
  final DateTime timestamp;

  AttendanceRecord({
    required this.id,
    required this.timestamp,
  });
}

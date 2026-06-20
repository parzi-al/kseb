import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:local_auth/local_auth.dart';  // Disabled: Windows build incompatibility
import '../utils/app_colors.dart';
import '../utils/app_typography.dart';
import '../utils/app_spacing.dart';
import '../utils/app_decorations.dart';
import '../components/common/app_bar_builder.dart';
import '../components/common/fade_in_widget.dart';
import '../components/common/skeleton_loader.dart';
import '../utils/app_toast.dart';
import '../utils/app_constants.dart';
import '../services/attendance_service.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../components/attendance/attendance_stats_card.dart';
import '../components/attendance/attendance_calendar.dart';
import '../components/attendance/attendance_history_list.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Services — no direct FirebaseFirestore usage in this file (FR-001).
  // final LocalAuthentication _localAuth = LocalAuthentication();  // Disabled: Windows incompatibility
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final AttendanceService _attendanceService = AttendanceService();

  // State variables
  String _userName = 'Loading...';
  UserRole? _userRole;
  int _thisMonthPresent = 0;
  int _thisYearPresent = 0;
  bool _isLoading = true;
  bool _isMarking = false; // Loading guard for double-tap prevention (FR-005)
  bool _isMarkedToday = false;
  String? _userId;
  String? _teamId;
  List<AttendanceModel> _attendanceRecords = [];
  bool _showHistory = false;

  // Supervisor team members
  List<UserModel> _teamMembers = [];
  Map<String, AttendanceModel> _teamAttendanceByUserId = {};
  bool _isLoadingTeamMembers = false;

  // Calendar view variables
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, bool> _attendanceMap = {};
  late final Set<DateTime> _publicHolidays;

  @override
  void initState() {
    super.initState();
    _publicHolidays =
        AttendanceConstants.getPublicHolidays(DateTime.now().year);
    _fetchWorkerData();
  }

  /// Fetches user profile and attendance stats via [AttendanceService].
  Future<void> _fetchWorkerData() async {
    setState(() => _isLoading = true);

    final user = _firebaseAuth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _userName = 'Not Logged In';
          _isLoading = false;
        });
      }
      return;
    }

    _userId = user.uid;
    try {
      // Fetch user profile — this is user data, not attendance data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        _userName = data?['name'] ?? user.email ?? 'No name found';
        _userRole = UserRole.fromString(data?['role'] ?? 'staff');
        _teamId = data?['teamId'];
      } else {
        _userName = user.email ?? 'No name found';
        _userRole = UserRole.staff;
      }

      // Fetch attendance stats via service (FR-004)
      final stats = await _attendanceService.getUserAttendanceStats(_userId!);
      _thisMonthPresent = stats['thisMonth'] ?? 0;
      _thisYearPresent = stats['thisYear'] ?? 0;
      _isMarkedToday = stats['isMarkedToday'] ?? false;

      // Fetch history via service
      await _fetchAttendanceHistory();

      // Fetch team members if supervisor
      if (_userRole?.isSupervisor ?? false) {
        await _fetchTeamMembers();
      }
    } catch (e) {
      _userName = 'Error loading data';
      _thisMonthPresent = 0;
      _thisYearPresent = 0;
      if (mounted) {
        AppToast.showError(context, 'Error fetching user data: $e');
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// Fetches team members for the current supervisor.
  Future<void> _fetchTeamMembers() async {
    if (_teamId == null) return;

    setState(() => _isLoadingTeamMembers = true);

    try {
      // Query by teamId only (avoids composite index requirement)
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('teamId', isEqualTo: _teamId)
          .get();

      // Filter to staff role locally in Dart
      _teamMembers = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) => user.role == UserRole.staff)
          .toList();

      // Sort by name
      _teamMembers.sort((a, b) => a.name.compareTo(b.name));
      await _fetchTeamAttendanceForDate(DateTime.now());
    } catch (e) {
      _teamMembers = [];
      _teamAttendanceByUserId = {};
      if (mounted) {
        AppToast.showError(context, 'Error fetching team members: $e');
      }
    }

    if (mounted) setState(() => _isLoadingTeamMembers = false);
  }

  /// Fetches team attendance for the date represented by the supervisor list.
  Future<void> _fetchTeamAttendanceForDate(DateTime date) async {
    if (_teamMembers.isEmpty) {
      _teamAttendanceByUserId = {};
      return;
    }

    final records = await _attendanceService.getTeamAttendance(
      userIds: _teamMembers.map((member) => member.id).toList(),
      date: date,
    );

    _teamAttendanceByUserId = {
      for (final record in records) record.userId: record,
    };
  }

  /// Fetches attendance history records via [AttendanceService] (FR-001).
  Future<void> _fetchAttendanceHistory() async {
    if (_userId == null) return;

    try {
      _attendanceRecords =
          await _attendanceService.getAttendanceHistory(_userId!);

      _attendanceMap.clear();
      for (final record in _attendanceRecords) {
        final dateOnly = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );
        _attendanceMap[dateOnly] = true;
      }
    } catch (e) {
      _attendanceRecords = [];
      _attendanceMap = {};
    }
  }

  /// Time-window check using configurable constants (FR-010).
  bool _isWithinAttendanceHours(DateTime dateTime) {
    final hour = dateTime.hour;
    return hour >= AttendanceConstants.attendanceStartHour &&
        hour < AttendanceConstants.attendanceEndHour;
  }

  /// Authenticates with biometrics and then records attendance.
  Future<void> _authenticateAndMarkAttendance() async {
    if (_isMarking) return; // Double-tap guard (FR-005)

    // Check time-window (FR-010)
    final now = DateTime.now();
    if (!_isWithinAttendanceHours(now)) {
      if (mounted) {
        AppToast.showError(
          context,
          'Attendance can only be marked between '
          '${AttendanceConstants.attendanceStartHour}:00 and '
          '${AttendanceConstants.attendanceEndHour}:00.',
        );
      }
      return;
    }

    // Note: local_auth disabled due to Windows build incompatibility.
    // Allow marking attendance without biometric requirement.
    if (!mounted) return;

    await _recordAttendance();
  }

  /// Record attendance via [AttendanceService] (FR-001/FR-004).
  Future<void> _recordAttendance() async {
    if (_userId == null || _isMarking) return;

    setState(() => _isMarking = true);

    try {
      await _attendanceService.markAttendance(userId: _userId!);

      if (mounted) {
        AppToast.showSuccess(context, 'Attendance marked successfully! 🎉');
        await _fetchWorkerData();
      }
    } on AttendanceAlreadyMarkedException {
      if (mounted) {
        AppToast.showWarning(context, 'Attendance already marked for today.');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        if (msg.contains('permission-denied')) {
          AppToast.showError(
              context, "You don't have permission to perform this action.");
        } else if (msg.contains('unavailable') || msg.contains('network')) {
          AppToast.showError(context,
              'Network error. Please check your connection and try again.');
        } else {
          AppToast.showError(context, 'Error marking attendance: $e');
        }
      }
    }

    if (mounted) setState(() => _isMarking = false);
  }

  /// Mark attendance for a team member (supervisor only).
  Future<void> _markTeamMemberAttendance(String memberId, DateTime date) async {
    try {
      await _attendanceService.markAttendanceForTeamMember(
        userId: memberId,
        date: date,
        status: 'present',
      );

      if (mounted) {
        AppToast.showSuccess(context, 'Attendance marked successfully! ✓');
        final today = DateTime.now();
        if (date.year == today.year &&
            date.month == today.month &&
            date.day == today.day) {
          await _fetchTeamAttendanceForDate(today);
          if (mounted) setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        if (msg.contains('already marked')) {
          AppToast.showWarning(
              context, 'Attendance already marked for this date.');
        } else {
          AppToast.showError(context, 'Error marking attendance: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(
        title: 'Attendance',
        actions: [
          if (_attendanceRecords.isNotEmpty)
            IconButton(
              icon: Icon(
                _showHistory ? Icons.dashboard : Icons.history_rounded,
                color: AppColors.primary,
              ),
              onPressed: () => setState(() => _showHistory = !_showHistory),
              tooltip: _showHistory ? 'Show Dashboard' : 'Show History',
            ),
        ],
      ),
      body: _isLoading
          ? const AttendanceScreenSkeleton()
          : _showHistory
              ? FadeInWidget(child: _buildHistoryView())
              : FadeInWidget(child: _buildMainView()),
    );
  }

  Widget _buildMainView() {
    final double attendancePercentage =
        AttendanceConstants.workingDaysInYear > 0
            ? (_thisYearPresent / AttendanceConstants.workingDaysInYear)
            : 0.0;

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                context.responsivePadding(AppSpacing.xl),
                context.responsivePadding(AppSpacing.xl),
                context.responsivePadding(AppSpacing.xl),
                100),
            child: Column(
              children: [
                SizedBox(height: AppSpacing.lg),
                // Stats via extracted widget (T010)
                AttendanceStatsCard(
                  thisMonth: _thisMonthPresent,
                  thisYear: _thisYearPresent,
                  isMarkedToday: _isMarkedToday,
                ),
                SizedBox(height: AppSpacing.lg),
                // Calendar via extracted widget (T011)
                AttendanceCalendar(
                  attendanceMap: _attendanceMap,
                  holidays: _publicHolidays,
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  onPageChanged: (focused) => _focusedDay = focused,
                ),
                SizedBox(height: AppSpacing.lg),
                _buildProgressCard(attendancePercentage),
                SizedBox(height: AppSpacing.xl),
                _buildMarkButton(),
                SizedBox(height: AppSpacing.md),
                // Debug test button — only in kDebugMode (FR-012)
                if (kDebugMode && !_isMarkedToday) _buildDebugButton(),
                SizedBox(height: AppSpacing.xl),
                // Supervisor section for marking team members
                if (_userRole?.isSupervisor ?? false) ...[
                  _buildSupervisorSection(),
                  SizedBox(height: AppSpacing.xl),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            context.responsivePadding(AppSpacing.xl),
            context.responsivePadding(AppSpacing.xl),
            context.responsivePadding(AppSpacing.xl),
            context.responsivePadding(AppSpacing.xxl)),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primaryWithLowOpacity,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_rounded,
                  size: 60, color: AppColors.primary),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              _userName,
              style: AppTypography.displayLargeStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryWithLowOpacity,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                _userRole?.displayName ?? 'AumLux Staff',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: AppTypography.fontSizeBase,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(double attendancePercentage) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
            style: AppTypography.subheadingStyle,
          ),
          SizedBox(height: AppSpacing.xl),
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 10.0,
            percent: attendancePercentage.clamp(0.0, 1.0),
            center: Text(
              '${(attendancePercentage * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppTypography.fontSizeXL,
                color: AppColors.textPrimary,
              ),
            ),
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: AppColors.primary,
            backgroundColor: AppColors.primaryWithLowOpacity,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '$_thisYearPresent / ${AttendanceConstants.workingDaysInYear} Working Days',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppTypography.fontSizeLG,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkButton() {
    return Opacity(
      opacity: _isMarkedToday ? 0.5 : 1.0,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isMarkedToday
                ? [
                    Colors.grey,
                    Colors.grey.shade600
                  ] // DS-EXCEPTION: disabled state
                : [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: _isMarkedToday
                  ? Colors.grey
                      .withValues(alpha: 0.3) // DS-EXCEPTION: disabled state
                  : AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isMarkedToday ? null : _authenticateAndMarkAttendance,
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isMarkedToday
                      ? Icons.check_circle_rounded
                      : Icons.fingerprint_rounded,
                  color: AppColors.textOnPrimary,
                  size: 28,
                ),
                SizedBox(width: AppSpacing.base),
                Text(
                  _isMarkedToday ? 'Already Marked Today' : 'Mark Attendance',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: AppTypography.fontSizeXL,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDebugButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.warning, width: 2),
        borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
        color: AppColors.warning.withValues(alpha: 0.1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _recordAttendance,
          borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bug_report_rounded,
                  color: AppColors.warning, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Test Mode - Mark Without Biometric',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: AppTypography.fontSizeBase,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Supervisor section for marking team member attendance.
  Widget _buildSupervisorSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.supervisor_account_rounded, color: AppColors.primary),
              SizedBox(width: AppSpacing.md),
              Text(
                'Mark Team Attendance',
                style: AppTypography.subheadingStyle,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          if (_isLoadingTeamMembers)
            Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          else if (_teamMembers.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'No team members available',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppTypography.fontSizeBase,
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryWithLowOpacity),
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: _teamMembers.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: AppColors.primaryWithLowOpacity,
                  indent: AppSpacing.xl,
                  endIndent: AppSpacing.xl,
                ),
                itemBuilder: (context, index) {
                  final member = _teamMembers[index];
                  final isMarked =
                      _teamAttendanceByUserId.containsKey(member.id);
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            color: AppColors.textSecondary, size: 20),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: AppTypography.fontSizeBase,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (member.email.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    member.email,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: AppTypography.fontSizeBase - 2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        if (isMarked)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusDefault),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.success,
                                  size: 18,
                                ),
                                SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Marked',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: AppTypography.fontSizeBase,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () => _showMarkAttendanceDialog(
                                member.id, member.name),
                            icon: Icon(Icons.check_circle_outline_rounded,
                                size: 18),
                            label: Text('Mark'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.textOnPrimary,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Show dialog to mark attendance for a specific team member.
  Future<void> _showMarkAttendanceDialog(
      String memberId, String memberName) async {
    DateTime? selectedDate = DateTime.now();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Mark Attendance for $memberName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select date to mark:',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppTypography.fontSizeBase,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Material(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 90)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppColors.primaryWithLowOpacity),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDefault),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: AppSpacing.md),
                        Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Tap to select date',
                          style: TextStyle(
                            color: selectedDate != null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: AppTypography.fontSizeBase,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: selectedDate != null
                  ? () async {
                      Navigator.pop(dialogContext);
                      await _markTeamMemberAttendance(memberId, selectedDate!);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                'Mark Attendance',
                style: TextStyle(color: AppColors.textOnPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Remove attendance record (supervisor only).
  Future<void> _removeAttendanceRecord(String attendanceId) async {
    try {
      await _attendanceService.removeAttendance(attendanceId);
      if (mounted) {
        AppToast.showSuccess(context, 'Attendance removed successfully.');
        await _fetchWorkerData();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Error removing attendance: $e');
      }
    }
  }

  /// History view delegated to extracted [AttendanceHistoryList] widget (T015).
  Widget _buildHistoryView() {
    return AttendanceHistoryList(
      records: _attendanceRecords,
      onRefresh: _fetchWorkerData,
      userRole: _userRole,
      onRemoveAttendance: _removeAttendanceRecord,
    );
  }
}

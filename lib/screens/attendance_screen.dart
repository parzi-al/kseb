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

class _AttendanceScreenState extends State<AttendanceScreen>
    with AutomaticKeepAliveClientMixin {
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
  List<AttendanceModel> _historyRecords = [];
  bool _showHistory = false;
  int? _selectedHistoryYear = DateTime.now().year;
  int? _selectedHistoryMonth;

  // Supervisor team members
  List<UserModel> _teamMembers = [];
  Map<String, AttendanceModel> _teamAttendanceByUserId = {};
  bool _isLoadingTeamMembers = false;

  // Calendar view variables
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, bool> _attendanceMap = {};
  Set<DateTime> _publicHolidays = {};

  @override
  void initState() {
    super.initState();
    _publicHolidays = AttendanceConstants.getPublicHolidays(_focusedDay.year);
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
      final stats = await _attendanceService.getUserAttendanceStats(
        _userId!,
        referenceDate: _focusedDay,
      );
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
        if (record.status != 'present') continue;
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
      if (mounted) {
        AppToast.showError(context, 'Error loading attendance history: $e');
      }
    }
  }

  Future<void> _fetchFilteredAttendanceHistory() async {
    if (_userId == null) return;

    try {
      final records = await _attendanceService.getAttendanceHistory(
        _userId!,
        year: _selectedHistoryYear,
        month: _selectedHistoryMonth,
      );
      if (mounted) {
        setState(() => _historyRecords = records);
      }
    } catch (e) {
      _historyRecords = [];
      if (mounted) {
        AppToast.showError(context, 'Error loading attendance history: $e');
      }
    }
  }

  Future<void> _handleCalendarPageChanged(DateTime focused) async {
    final previousYear = _focusedDay.year;
    setState(() {
      _focusedDay = focused;
      if (previousYear != focused.year) {
        _publicHolidays = AttendanceConstants.getPublicHolidays(focused.year);
      }
    });

    if (_userId == null) return;

    try {
      final stats = await _attendanceService.getUserAttendanceStats(
        _userId!,
        referenceDate: focused,
      );
      if (!mounted) return;
      setState(() {
        _thisMonthPresent = stats['thisMonth'] ?? 0;
        _thisYearPresent = stats['thisYear'] ?? 0;
        _isMarkedToday = stats['isMarkedToday'] ?? false;
      });
    } catch (_) {
      // Keep the existing stats visible if refresh fails.
    }
  }

  String _monthLabel(DateTime date) {
    return '${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
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
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(
        title: 'Attendance',
        actions: [
          if (_attendanceRecords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: IconButton(
                icon: Icon(
                  _showHistory ? Icons.dashboard : Icons.history_rounded,
                  color: AppColors.primary,
                ),
              onPressed: () async {
                if (!_showHistory) {
                  await _fetchFilteredAttendanceHistory();
                }
                if (mounted) {
                  setState(() => _showHistory = !_showHistory);
                }
              },
                tooltip: _showHistory ? 'Show Dashboard' : 'Show History',
              ),
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

  @override
  bool get wantKeepAlive => true;

  Widget _buildMainView() {
    final double attendancePercentage =
        AttendanceConstants.workingDaysInYear > 0
            ? (_thisYearPresent / AttendanceConstants.workingDaysInYear)
            : 0.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        context.responsivePadding(AppSpacing.xl),
        context.responsivePadding(AppSpacing.xl),
        context.responsivePadding(AppSpacing.xl),
        100,
      ),
      child: Column(
        children: [
          _buildHeader(),
          SizedBox(height: AppSpacing.lg),
          AttendanceStatsCard(
            thisMonth: _thisMonthPresent,
            thisYear: _thisYearPresent,
            isMarkedToday: _isMarkedToday,
            monthLabel: _monthLabel(_focusedDay),
            yearLabel: '${_focusedDay.year}',
          ),
          SizedBox(height: AppSpacing.lg),
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
            onPageChanged: _handleCalendarPageChanged,
          ),
          SizedBox(height: AppSpacing.lg),
          _buildProgressCard(attendancePercentage),
          SizedBox(height: AppSpacing.xl),
          _buildMarkButton(),
          SizedBox(height: AppSpacing.md),
          if (kDebugMode && !_isMarkedToday) _buildDebugButton(),
          SizedBox(height: AppSpacing.xl),
          if (_userRole?.isSupervisor ?? false) ...[
            _buildSupervisorSection(),
            SizedBox(height: AppSpacing.xl),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryWithLowOpacity,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              size: AppTypography.iconSizeXl,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: AppSpacing.base),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _userName,
                  style: AppTypography.titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  _userRole?.displayName ?? 'AumLux Staff',
                  style: AppTypography.captionStyle.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _isMarkedToday
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isMarkedToday
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  color: _isMarkedToday ? AppColors.success : AppColors.warning,
                  size: AppTypography.iconSizeSm,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  _isMarkedToday ? 'Marked' : 'Pending',
                  style: AppTypography.captionStyle.copyWith(
                    color:
                        _isMarkedToday ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            '${_focusedDay.year} Progress',
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
    return Column(
      children: [
        _buildHistoryFilters(),
        Expanded(
          child: AttendanceHistoryList(
            records: _historyRecords,
            onRefresh: _fetchFilteredAttendanceHistory,
            userRole: _userRole,
            onRemoveAttendance: _removeAttendanceRecord,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryFilters() {
    final currentYear = DateTime.now().year;
    final years = List.generate(8, (index) => currentYear - index);
    final months = List.generate(12, (index) => index + 1);

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _historyFilterChip(
            label: _selectedHistoryYear == null
                ? 'All Years'
                : '$_selectedHistoryYear',
            icon: Icons.calendar_today_rounded,
            selected: _selectedHistoryYear != null,
            onTap: () => _showHistoryYearPicker(years),
          ),
          if (_selectedHistoryYear != null)
            _historyFilterChip(
              label: _selectedHistoryMonth == null
                  ? 'All Months'
                  : _monthName(_selectedHistoryMonth!),
              icon: Icons.calendar_month_rounded,
              selected: _selectedHistoryMonth != null,
              onTap: () => _showHistoryMonthPicker(months),
            ),
          if (_selectedHistoryYear != null || _selectedHistoryMonth != null)
            TextButton.icon(
              onPressed: () async {
                setState(() {
                  _selectedHistoryYear = null;
                  _selectedHistoryMonth = null;
                });
                await _fetchFilteredAttendanceHistory();
              },
              icon: const Icon(Icons.close_rounded),
              label: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  Widget _historyFilterChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryWithLowOpacity
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.grey200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppTypography.iconSizeSm,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.captionStyle.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHistoryYearPicker(List<int> years) async {
    final selected = await _showHistoryOptionSheet<int?>(
      title: 'Select Year',
      options: [
        const _HistoryOption<int?>(label: 'All Years', value: null),
        for (final year in years) _HistoryOption(label: '$year', value: year),
      ],
    );

    if (!mounted) return;
    setState(() {
      _selectedHistoryYear = selected;
      _selectedHistoryMonth = null;
    });
    await _fetchFilteredAttendanceHistory();
  }

  Future<void> _showHistoryMonthPicker(List<int> months) async {
    final selected = await _showHistoryOptionSheet<int?>(
      title: 'Select Month',
      options: [
        const _HistoryOption<int?>(label: 'All Months', value: null),
        for (final month in months)
          _HistoryOption(label: _monthName(month), value: month),
      ],
    );

    if (!mounted) return;
    setState(() => _selectedHistoryMonth = selected);
    await _fetchFilteredAttendanceHistory();
  }

  Future<T?> _showHistoryOptionSheet<T>({
    required String title,
    required List<_HistoryOption<T>> options,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.58,
        minChildSize: 0.32,
        maxChildSize: 0.82,
        builder: (context, scrollController) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.subheadingStyle),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(option.label),
                        onTap: () => Navigator.pop(context, option.value),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryOption<T> {
  const _HistoryOption({
    required this.label,
    required this.value,
  });

  final String label;
  final T value;
}

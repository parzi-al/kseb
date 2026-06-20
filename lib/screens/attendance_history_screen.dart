import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import '../utils/app_toast.dart';
import '../utils/app_spacing.dart';
import '../utils/app_typography.dart';
import '../models/attendance_model.dart';
import '../models/user_model.dart';
import '../services/attendance_service.dart';
import '../components/common/app_bar_builder.dart';
import '../components/common/skeleton_loader.dart';
import '../components/attendance/attendance_history_list.dart';

/// Standalone attendance history screen.
///
/// All data is fetched via [AttendanceService] — no direct Firestore access
/// (FR-001 / FR-002). Uses the flat top-level `attendance` collection.
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final AttendanceService _attendanceService = AttendanceService();

  List<AttendanceModel> _attendanceRecords = [];
  bool _isLoading = true;
  String? _userId;
  UserRole? _userRole;
  int? _selectedYear = DateTime.now().year;
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceHistory();
  }

  /// Fetches attendance history via [AttendanceService] (FR-002).
  Future<void> _fetchAttendanceHistory() async {
    setState(() => _isLoading = true);

    final user = _firebaseAuth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _userId = user.uid;
    try {
      // Fetch user role
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        _userRole = UserRole.fromString(data?['role'] ?? 'staff');
      } else {
        _userRole = UserRole.staff;
      }

      _attendanceRecords = await _attendanceService.getAttendanceHistory(
        _userId!,
        year: _selectedYear,
        month: _selectedMonth,
      );
    } catch (e) {
      _attendanceRecords = [];
      if (mounted) {
        AppToast.showError(context, 'Error fetching attendance history: $e');
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  /// Remove attendance record (supervisor only).
  Future<void> _removeAttendanceRecord(String attendanceId) async {
    try {
      await _attendanceService.removeAttendance(attendanceId);
      if (mounted) {
        AppToast.showSuccess(context, 'Attendance removed successfully.');
        await _fetchAttendanceHistory();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Error removing attendance: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: buildAppBar(title: 'Attendance History'),
      body: _isLoading
          ? const ListScreenSkeleton()
          : Column(
              children: [
                _buildFilters(),
                Expanded(
                  child: AttendanceHistoryList(
                    records: _attendanceRecords,
                    onRefresh: _fetchAttendanceHistory,
                    userRole: _userRole,
                    onRemoveAttendance: _removeAttendanceRecord,
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Mark Attendance'),
      ),
    );
  }

  List<int> get _availableYears {
    final currentYear = DateTime.now().year;
    return List.generate(8, (index) => currentYear - index);
  }

  Widget _buildFilters() {
    final years = _availableYears;
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
          _filterChip(
            label: _selectedYear == null ? 'All Years' : '$_selectedYear',
            icon: Icons.calendar_today_rounded,
            selected: _selectedYear != null,
            onTap: () => _showYearPicker(years),
          ),
          if (_selectedYear != null)
            _filterChip(
              label: _selectedMonth == null
                  ? 'All Months'
                  : _monthName(_selectedMonth!),
              icon: Icons.calendar_month_rounded,
              selected: _selectedMonth != null,
              onTap: () => _showMonthPicker(months),
            ),
          if (_selectedYear != null || _selectedMonth != null)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedYear = null;
                  _selectedMonth = null;
                });
                _fetchAttendanceHistory();
              },
              icon: const Icon(Icons.close_rounded),
              label: const Text('Clear'),
            ),
        ],
      ),
    );
  }

  Widget _filterChip({
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

  Future<void> _showYearPicker(List<int> years) async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) => _OptionSheet<int?>(
        title: 'Select Year',
        options: [
          const _SheetOption<int?>(label: 'All Years', value: null),
          for (final year in years)
            _SheetOption<int?>(label: '$year', value: year),
        ],
      ),
    );

    if (!mounted) return;
    setState(() {
      _selectedYear = selected;
      _selectedMonth = null;
    });
    await _fetchAttendanceHistory();
  }

  Future<void> _showMonthPicker(List<int> months) async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) => _OptionSheet<int?>(
        title: 'Select Month',
        options: [
          const _SheetOption<int?>(label: 'All Months', value: null),
          for (final month in months)
            _SheetOption<int?>(label: _monthName(month), value: month),
        ],
      ),
    );

    if (!mounted) return;
    setState(() => _selectedMonth = selected);
    await _fetchAttendanceHistory();
  }

  static String _monthName(int month) {
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
}

class _SheetOption<T> {
  const _SheetOption({
    required this.label,
    required this.value,
  });

  final String label;
  final T value;
}

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
  });

  final String title;
  final List<_SheetOption<T>> options;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.subheadingStyle),
            const SizedBox(height: AppSpacing.md),
            for (final option in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option.label),
                onTap: () => Navigator.pop(context, option.value),
              ),
          ],
        ),
      ),
    );
  }
}

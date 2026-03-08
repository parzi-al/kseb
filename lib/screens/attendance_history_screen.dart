import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import '../utils/app_toast.dart';
import '../models/attendance_model.dart';
import '../services/attendance_service.dart';
import 'components/attendance_history_list.dart';

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
      _attendanceRecords =
          await _attendanceService.getAttendanceHistory(_userId!);
    } catch (e) {
      _attendanceRecords = [];
      if (mounted) {
        AppToast.showError(context, 'Error fetching attendance history: $e');
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Attendance History',
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
          : AttendanceHistoryList(
              records: _attendanceRecords,
              onRefresh: _fetchAttendanceHistory,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Mark Attendance'),
      ),
    );
  }
}

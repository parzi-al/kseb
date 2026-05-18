import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_colors.dart';
import '../utils/app_toast.dart';
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
          : AttendanceHistoryList(
              records: _attendanceRecords,
              onRefresh: _fetchAttendanceHistory,
              userRole: _userRole,
              onRemoveAttendance: _removeAttendanceRecord,
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
}

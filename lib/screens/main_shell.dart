import 'package:flutter/material.dart';

import '../components/common/floating_bottom_nav.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/approval_service.dart';
import '../utils/app_colors.dart';
import '../utils/feature_flags.dart';
import 'attendance_screen.dart';
import 'bonus_history_screen.dart';
import 'bonus_management_screen.dart';
import 'material_management_screen.dart';
import 'staff_management_screen.dart';
import 'worker_home_screen.dart';
import 'worksheet_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.authService});

  final AuthService? authService;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final ApprovalService _approvalService = ApprovalService();
  int _selectedIndex = 0;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _approvalService.getCurrentUser();
      if (mounted) {
        setState(() => _currentUser = user);
      }
    } catch (_) {
      // Keep the shell usable; role-specific destinations are optional.
    }
  }

  bool get _showStaffDestination {
    final user = _currentUser;
    return user != null && user.isSupervisor && user.teamId != null;
  }

  Widget? _buildOptionalScreen() {
    final user = _currentUser;
    if (_showStaffDestination) {
      return StaffManagementScreen(
        teamId: user!.teamId,
        currentUserRole: user.role,
      );
    }

    if (!FeatureFlags.enableBonusModule || user == null) return null;

    if (user.role == UserRole.coo || user.role == UserRole.director) {
      return const BonusManagementScreen();
    }

    return const BonusHistoryScreen();
  }

  FloatingBottomNavDestination? _buildOptionalDestination() {
    final user = _currentUser;

    if (_showStaffDestination) {
      return const FloatingBottomNavDestination(
        icon: Icons.people_rounded,
        label: 'Staff',
      );
    }

    if (!FeatureFlags.enableBonusModule || user == null) return null;

    if (user.role == UserRole.coo || user.role == UserRole.director) {
      return const FloatingBottomNavDestination(
        icon: Icons.card_giftcard_rounded,
        label: 'Bonus',
      );
    }

    return const FloatingBottomNavDestination(
      icon: Icons.card_giftcard_rounded,
      label: 'Bonus',
    );
  }

  @override
  Widget build(BuildContext context) {
    final optionalScreen = _buildOptionalScreen();
    final optionalDestination = _buildOptionalDestination();
    final pages = [
      WorkerHomeScreen(authService: widget.authService),
      const AttendanceScreen(),
      const WorksheetScreen(),
      const MaterialManagementScreen(),
      if (optionalScreen != null) optionalScreen,
    ];
    final destinations = [
      const FloatingBottomNavDestination(
        icon: Icons.home_rounded,
        label: 'Home',
      ),
      const FloatingBottomNavDestination(
        icon: Icons.fingerprint_rounded,
        label: 'Attendance',
      ),
      const FloatingBottomNavDestination(
        icon: Icons.assignment_rounded,
        label: 'Worksheet',
      ),
      const FloatingBottomNavDestination(
        icon: Icons.inventory_2_rounded,
        label: 'Materials',
      ),
      if (optionalDestination != null) optionalDestination,
    ];
    final selectedIndex = _selectedIndex.clamp(0, pages.length - 1);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: FloatingBottomNav(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: destinations,
      ),
    );
  }
}

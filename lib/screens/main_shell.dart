import 'package:flutter/material.dart';

import '../components/common/floating_bottom_nav.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'attendance_screen.dart';
import 'worker_home_screen.dart';
import 'worksheet_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.authService});

  final AuthService? authService;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectPage(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      WorkerHomeScreen(authService: widget.authService),
      const AttendanceScreen(),
      const WorksheetScreen(),
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
    ];
    final selectedIndex = _selectedIndex.clamp(0, pages.length - 1);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: pages,
      ),
      bottomNavigationBar: FloatingBottomNav(
        selectedIndex: selectedIndex,
        onDestinationSelected: _selectPage,
        destinations: destinations,
      ),
    );
  }
}

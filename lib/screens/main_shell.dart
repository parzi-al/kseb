import 'package:flutter/material.dart';

import '../components/common/floating_bottom_nav.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'attendance_screen.dart';
import 'worker_home_screen.dart';
import 'worksheet_screen.dart';

class MainShell extends StatefulWidget {
  MainShell({Key? key, this.authService, this.initialIndex = 0})
      : super(key: key ?? shellKey);

  static final shellKey = GlobalKey<_MainShellState>();

  final AuthService? authService;
  final int initialIndex;

  static void openTab(BuildContext context, int index) {
    final shellState = shellKey.currentState;
    if (shellState == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainShell(initialIndex: index)),
        (route) => false,
      );
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
    shellState.selectPage(index);
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _selectedIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 2);
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void selectPage(int index) {
    if (_selectedIndex == index) return;
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
        onDestinationSelected: selectPage,
        destinations: destinations,
      ),
    );
  }
}

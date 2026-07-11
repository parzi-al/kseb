import 'package:flutter/material.dart';

import '../../screens/main_shell.dart';
import 'floating_bottom_nav.dart';

class ShellBottomNav extends StatelessWidget {
  const ShellBottomNav({
    super.key,
    this.selectedIndex = -1,
  });

  final int selectedIndex;

  static const destinations = [
    FloatingBottomNavDestination(
      icon: Icons.home_rounded,
      label: 'Home',
    ),
    FloatingBottomNavDestination(
      icon: Icons.fingerprint_rounded,
      label: 'Attendance',
    ),
    FloatingBottomNavDestination(
      icon: Icons.assignment_rounded,
      label: 'Worksheet',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return FloatingBottomNav(
      selectedIndex: selectedIndex,
      destinations: destinations,
      onDestinationSelected: (index) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainShell(initialIndex: index),
          ),
          (route) => false,
        );
      },
    );
  }
}

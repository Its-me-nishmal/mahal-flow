import 'package:flutter/material.dart';

import '../../../core/widgets/app_bottom_nav_bar.dart';

class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNavBar({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/admin/members');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/admin/reports');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/admin/audit-logs');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomNavBar(
      currentIndex: currentIndex.clamp(0, 3),
      onTap: (index) => _onTap(context, index),
      items: const [
        AppNavItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: 'Dashboard',
        ),
        AppNavItem(
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          label: 'Members',
        ),
        AppNavItem(
          icon: Icons.assessment_outlined,
          activeIcon: Icons.assessment_rounded,
          label: 'Reports',
        ),
        AppNavItem(
          icon: Icons.history_rounded,
          activeIcon: Icons.history_rounded,
          label: 'Logs',
        ),
      ],
    );
  }
}

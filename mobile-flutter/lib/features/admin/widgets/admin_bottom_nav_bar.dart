import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';

class AdminBottomNavBar extends StatelessWidget {
  /// Index into [AppRoutes.adminTabs]; pass -1 on a screen that is not a tab
  /// (e.g. gateways) so no tab is highlighted and every tab is tappable.
  final int currentIndex;

  const AdminBottomNavBar({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;
    // Dashboard stays the stack root, so Back from any tab returns to it.
    AppNav.switchAdminTab(context, AppRoutes.adminTabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomNavBar(
      currentIndex: currentIndex,
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

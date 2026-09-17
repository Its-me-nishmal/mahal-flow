import 'package:flutter/material.dart';

import '../network/api_service.dart';
import 'app_bottom_nav_bar.dart';

class MemberBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const MemberBottomNavBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/member/dashboard',
          (route) => false,
        );
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/member/monthly-payment');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/member/receipts');
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed('/member/alerts');
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed('/member/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ApiService.unreadAlertsCount,
      builder: (context, unreadCount, _) {
        return AppBottomNavBar(
          currentIndex: currentIndex,
          onTap: (index) => _onItemTapped(context, index),
          items: [
            const AppNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
            ),
            const AppNavItem(
              icon: Icons.payments_outlined,
              activeIcon: Icons.payments_rounded,
              label: 'Pay',
            ),
            const AppNavItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: 'Receipts',
            ),
            AppNavItem(
              icon: Icons.campaign_outlined,
              activeIcon: Icons.campaign_rounded,
              label: 'Notices',
              showBadge: unreadCount > 0,
            ),
            const AppNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../network/api_service.dart';
import 'app_bottom_nav_bar.dart';
import '../../l10n/l10n.dart';

/// Member tabs. Navigation goes through [AppNav.switchMemberTab], so Back from
/// any tab returns to Home instead of leaving the app.
class MemberBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const MemberBottomNavBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;
    AppNav.switchMemberTab(context, AppRoutes.memberTabs[index]);
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
            AppNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: context.l10n.navHome,
            ),
            AppNavItem(
              icon: Icons.payments_outlined,
              activeIcon: Icons.payments_rounded,
              label: context.l10n.navPay,
            ),
            AppNavItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: context.l10n.navReceipts,
            ),
            AppNavItem(
              icon: Icons.campaign_outlined,
              activeIcon: Icons.campaign_rounded,
              label: context.l10n.navNotices,
              badgeCount: unreadCount,
            ),
            AppNavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: context.l10n.navProfile,
            ),
          ],
        );
      },
    );
  }
}

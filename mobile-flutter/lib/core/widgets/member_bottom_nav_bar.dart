import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MemberBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const MemberBottomNavBar({
    super.key,
    required this.currentIndex,
  });

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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: currentIndex == 0 ? Icons.home : Icons.home_outlined,
                label: "Home",
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: currentIndex == 1 ? Icons.payments : Icons.payments_outlined,
                label: "Payments",
              ),
              _buildNavItem(
                context,
                index: 2,
                icon: currentIndex == 2 ? Icons.receipt_long : Icons.receipt_long_outlined,
                label: "Receipts",
              ),
              _buildNavItem(
                context,
                index: 3,
                icon: currentIndex == 3 ? Icons.notifications : Icons.notifications_none_outlined,
                label: "Alerts",
                showBadge: true,
              ),
              _buildNavItem(
                context,
                index: 4,
                icon: currentIndex == 4 ? Icons.person : Icons.person_outline,
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    bool showBadge = false,
  }) {
    final isSelected = index == currentIndex;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: () => _onItemTapped(context, index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
                if (showBadge)
                  Positioned(
                    top: -1,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

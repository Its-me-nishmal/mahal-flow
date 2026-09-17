import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// One bottom bar implementation for both the member and committee apps, so
/// the two never drift apart in height, weight or colour.
class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool showBadge;

  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.showBadge = false,
  });
}

class AppBottomNavBar extends StatelessWidget {
  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(child: _item(context, i, items[i])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index, AppNavItem item) {
    final isSelected = index == currentIndex;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: isSelected,
      label: item.label,
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 23,
                  color: color,
                ),
                if (item.showBadge)
                  Positioned(
                    top: -1,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: AppTextStyles.small.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

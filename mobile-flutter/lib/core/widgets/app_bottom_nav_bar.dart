import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../../l10n/l10n.dart';

/// One bottom bar implementation for both the member and committee apps, so
/// the two never drift apart in height, weight or colour.
class AppNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Shows a dot without a number. Prefer [badgeCount], which is also
  /// announced to screen readers.
  final bool showBadge;

  /// Unread count; > 0 shows the dot and is read out as "N unread".
  final int badgeCount;

  const AppNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.showBadge = false,
    this.badgeCount = 0,
  });

  bool get hasBadge => showBadge || badgeCount > 0;
}

class AppBottomNavBar extends StatelessWidget {
  final List<AppNavItem> items;

  /// Selected tab; -1 (or any out-of-range value) selects none.
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  static const double _minHeight = 62;

  @override
  Widget build(BuildContext context) {
    // Labels grow with the system font size but stop before five tabs stop
    // fitting side by side; the bar itself grows instead of clipping.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border(top: BorderSide(color: context.colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _minHeight),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(child: _item(context, i, items[i])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, int index, AppNavItem item) {
    final isSelected = index == currentIndex;
    final color = isSelected ? context.colors.primary : context.colors.textSecondary;

    final String semanticLabel;
    if (item.badgeCount > 0) {
      semanticLabel =
          context.l10n.commonUnreadCount(item.label, item.badgeCount);
    } else if (item.showBadge) {
      semanticLabel = context.l10n.commonNewBadge(item.label);
    } else {
      semanticLabel = item.label;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs / 2,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  if (item.hasBadge)
                    Positioned(
                      top: -1,
                      right: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: context.colors.error,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: context.colors.surface, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.text.label.copyWith(
                  letterSpacing: 0,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

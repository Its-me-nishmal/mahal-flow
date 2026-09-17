import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// -------------------------------------------------------------------------
/// Card family. One surface, one border, one hairline shadow — the same
/// container the member home uses, so every screen reads as the same product.
/// -------------------------------------------------------------------------
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final List<BoxShadow>? shadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md + 2),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadius.card,
    this.shadow,
  });

  /// Elevated variant for the card that floats over the gradient header.
  const AppCard.floating({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg - 2),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadius.hero,
  }) : shadow = AppShadows.floating;

  @override
  Widget build(BuildContext context) {
    final decorated = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? AppColors.border),
        boxShadow: shadow ?? AppShadows.card,
      ),
      child: child,
    );

    if (onTap == null) return decorated;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: decorated,
      ),
    );
  }
}

/// All-caps label that opens a card or a section. Never bold body text.
class AppSectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const AppSectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final label = Text(text.toUpperCase(), style: AppTextStyles.label);
    if (trailing == null) return label;
    return Row(
      children: [
        Expanded(child: label),
        const SizedBox(width: AppSpacing.sm),
        trailing!,
      ],
    );
  }
}

/// Title above a group of cards, with an optional text action on the right.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.ms),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: AppTextStyles.button.copyWith(
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Status pill — always carries text, never signals by colour alone.
class StatusPill extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  /// Maps a backend status string onto the semantic palette.
  factory StatusPill.forStatus(String status, {IconData? icon}) {
    final normalized = status.trim().toUpperCase();
    Color fg = AppColors.textSecondary;
    Color bg = AppColors.neutralBg;
    IconData? glyph = icon;

    if (['SUCCESS', 'PAID', 'ACTIVE', 'COMPLETED', 'APPROVED', 'VERIFIED']
        .contains(normalized)) {
      fg = AppColors.success;
      bg = AppColors.successBg;
      glyph ??= Icons.check_circle_rounded;
    } else if (['PENDING', 'PROCESSING', 'INITIATED', 'PARTIAL', 'DUE']
        .contains(normalized)) {
      fg = AppColors.warning;
      bg = AppColors.warningBg;
      glyph ??= Icons.schedule_rounded;
    } else if (['FAILED', 'OVERDUE', 'INACTIVE', 'CANCELLED', 'REJECTED']
        .contains(normalized)) {
      fg = AppColors.error;
      bg = AppColors.errorBg;
      glyph ??= Icons.error_outline_rounded;
    } else if (['INFO', 'DRAFT', 'SCHEDULED'].contains(normalized)) {
      fg = AppColors.info;
      bg = AppColors.infoBg;
    }

    final pretty = normalized.isEmpty
        ? '—'
        : normalized[0] + normalized.substring(1).toLowerCase();

    return StatusPill(
      label: pretty,
      foreground: fg,
      background: bg,
      icon: glyph,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: $label',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.ms,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: foreground),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: AppTextStyles.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded-square icon chip. The single icon treatment across the app.
class AppIconChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  const AppIconChip({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Icon + title + caption + trailing, inside a card. The app's list row.
class AppListRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? caption;
  final Widget? trailing;
  final String? trailingText;
  final String? trailingCaption;
  final VoidCallback? onTap;
  final bool showChevron;

  const AppListRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    this.caption,
    this.trailing,
    this.trailingText,
    this.trailingCaption,
    this.onTap,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md - 2),
      child: Row(
        children: [
          AppIconChip(
            icon: icon,
            color: iconColor,
            background: iconBackground,
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small,
                  ),
                ],
              ],
            ),
          ),
          if (trailingText != null || trailingCaption != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (trailingText != null)
                  Text(
                    trailingText!,
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                  ),
                if (trailingCaption != null) ...[
                  const SizedBox(height: 2),
                  Text(trailingCaption!, style: AppTextStyles.small),
                ],
              ],
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
          if (showChevron) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ],
      ),
    );
  }
}

/// Label / value pair used in detail cards and receipts.
class AppDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? valueWidget;
  final bool emphasize;
  final bool copyable;
  final VoidCallback? onCopy;

  const AppDetailRow({
    super.key,
    required this.label,
    this.value = '',
    this.valueWidget,
    this.emphasize = false,
    this.copyable = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              flex: 5,
              child: valueWidget ??
                  Text(
                    value,
                    textAlign: TextAlign.right,
                    style: emphasize
                        ? AppTextStyles.cardTitle.copyWith(fontSize: 15)
                        : AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                  ),
            ),
            if (copyable && onCopy != null)
              InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.xs + 2),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Hairline rule used inside cards.
class AppCardDivider extends StatelessWidget {
  final double spacing;

  const AppCardDivider({super.key, this.spacing = AppSpacing.ms});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing),
      child: const Divider(height: 1, color: AppColors.border),
    );
  }
}

/// Compact metric tile for dashboards — two or three per row.
class AppStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;
  final String? caption;
  final VoidCallback? onTap;

  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    this.caption,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIconChip(
                icon: icon,
                color: color,
                background: background,
                size: 34,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.sectionTitle.copyWith(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(fontSize: 11.5),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.small.copyWith(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Square action tile — the 2x2 grid on the member home.
class AppActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String caption;
  final VoidCallback onTap;
  final int badgeCount;

  const AppActionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.caption,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppIconChip(
                icon: icon,
                color: iconColor,
                background: iconBackground,
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -3,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      style: AppTextStyles.label.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          Text(label, style: AppTextStyles.cardTitle.copyWith(fontSize: 15)),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

/// Tinted advisory strip — "AutoPay is off", "Import will overwrite", etc.
class AppNoticeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Color background;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppNoticeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = AppColors.primary,
    this.background = AppColors.primaryLight,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md - 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(message, style: AppTextStyles.small),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
                minimumSize: const Size(0, 44),
              ),
              child: Text(
                actionLabel!,
                style: AppTextStyles.button.copyWith(fontSize: 14, color: color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Numbered progress across a short flow (import wizard, multi-step forms).
class AppStepIndicator extends StatelessWidget {
  final List<String> steps;

  /// Zero-based index of the step the person is on.
  final int currentIndex;

  const AppStepIndicator({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Container(
                  height: 2,
                  color: i <= currentIndex
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
            ),
          _step(i),
        ],
      ],
    );
  }

  Widget _step(int index) {
    final isDone = index < currentIndex;
    final isCurrent = index == currentIndex;
    final filled = isDone || isCurrent;

    return SizedBox(
      width: 66,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled ? AppColors.primary : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: filled ? AppColors.primary : AppColors.border,
              ),
            ),
            child: isDone
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: AppTextStyles.small.copyWith(
                      fontWeight: FontWeight.w700,
                      color: filled ? Colors.white : AppColors.textMuted,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm - 2),
          Text(
            steps[index],
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.small.copyWith(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
              color: filled ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../../l10n/l10n.dart';

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
  final bool _floating;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md + 2),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadius.card,
    this.shadow,
  }) : _floating = false;

  /// Elevated variant for the card that floats over the gradient header.
  const AppCard.floating({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg - 2),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = AppRadius.hero,
  })  : shadow = null,
        _floating = true;

  @override
  Widget build(BuildContext context) {
    final decorated = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.colors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? context.colors.border),
        boxShadow: shadow ??
            (_floating
                ? context.colors.floatingShadow
                : context.colors.cardShadow),
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
    final label = Text(text.toUpperCase(), style: context.text.label);
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
                style: context.text.cardTitle,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: context.colors.primary,
                minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: Text(
                actionLabel!,
                style: context.text.buttonSmall.copyWith(
                  color: context.colors.primary,
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
  factory StatusPill.forStatus(BuildContext context, String status,
      {IconData? icon}) {
    final normalized = status.trim().toUpperCase();
    Color fg = context.colors.textSecondary;
    Color bg = context.colors.neutralBg;
    IconData? glyph = icon;

    if (['SUCCESS', 'PAID', 'ACTIVE', 'COMPLETED', 'APPROVED', 'VERIFIED']
        .contains(normalized)) {
      fg = context.colors.success;
      bg = context.colors.successBg;
      glyph ??= Icons.check_circle_rounded;
    } else if (['PENDING', 'PROCESSING', 'INITIATED', 'PARTIAL', 'DUE']
        .contains(normalized)) {
      fg = context.colors.warning;
      bg = context.colors.warningBg;
      glyph ??= Icons.schedule_rounded;
    } else if (['FAILED', 'OVERDUE', 'INACTIVE', 'CANCELLED', 'REJECTED']
        .contains(normalized)) {
      fg = context.colors.error;
      bg = context.colors.errorBg;
      glyph ??= Icons.error_outline_rounded;
    } else if (normalized == 'REFUNDED') {
      fg = context.colors.info;
      bg = context.colors.infoBg;
      glyph ??= Icons.undo_rounded;
    } else if (['INFO', 'DRAFT', 'SCHEDULED'].contains(normalized)) {
      fg = context.colors.info;
      bg = context.colors.infoBg;
    }

    final pretty = normalized.isEmpty
        ? '—'
        : statusLabel(context, normalized) ??
            normalized[0] + normalized.substring(1).toLowerCase();

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
      label: context.l10n.commonStatusLabel(label),
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
              // Loose flex: ellipsizes when the parent bounds the pill,
              // sizes to the label when it does not.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
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
                  style: context.text.listTitle,
                ),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.small,
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
                    style: context.text.listTitle,
                  ),
                if (trailingCaption != null) ...[
                  const SizedBox(height: 2),
                  Text(trailingCaption!, style: context.text.small),
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
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: context.colors.textMuted,
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
    final showCopy = copyable && onCopy != null;
    return Padding(
      padding: EdgeInsets.symmetric(
        // The 48dp copy button supplies its own vertical room.
        vertical: showCopy ? 0 : AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment:
            showCopy ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Expanded(
            child: MergeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      label,
                      style: context.text.body.copyWith(
                        color: context.colors.textSecondary,
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
                              ? context.text.listTitle
                              : context.text.body.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (showCopy)
            IconButton(
              onPressed: onCopy,
              tooltip: context.l10n.commonCopyLabel(label),
              icon: Icon(
                Icons.copy_rounded,
                size: 16,
                color: context.colors.textMuted,
              ),
            ),
        ],
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
      child: Divider(height: 1, color: context.colors.border),
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
              style: context.text.statValue,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.caption,
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.small.copyWith(
                fontSize: 11,
                color: context.colors.textMuted,
              ),
            ),
          ],
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
  final Color? color;
  final Color? background;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppNoticeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color,
    this.background,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colors.primary;
    final background = this.background ?? context.colors.primaryLight;
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
              color: context.colors.surface,
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
                  style: context.text.listTitle,
                ),
                const SizedBox(height: 2),
                Text(message, style: context.text.small),
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
                style: context.text.buttonMedium.copyWith(color: color),
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
                      ? context.colors.primary
                      : context.colors.border,
                ),
              ),
            ),
          _step(context, i),
        ],
      ],
    );
  }

  Widget _step(BuildContext context, int index) {
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
              color: filled ? context.colors.primary : context.colors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: filled ? context.colors.primary : context.colors.border,
              ),
            ),
            child: isDone
                ? Icon(Icons.check_rounded,
                    size: 16, color: context.colors.onPrimary)
                : Text(
                    '${index + 1}',
                    style: context.text.small.copyWith(
                      fontWeight: FontWeight.w700,
                      color: filled
                          ? context.colors.onPrimary
                          : context.colors.textMuted,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm - 2),
          Text(
            steps[index],
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.small.copyWith(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
              color: filled ? context.colors.primary : context.colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Localized label for a backend status string (upper-cased), or null when
/// the status is not one the app knows.
String? statusLabel(BuildContext context, String normalized) {
  final l = context.l10n;
  return switch (normalized) {
    'PAID' => l.statusPaid,
    'ACTIVE' => l.statusActive,
    'COMPLETED' => l.statusCompleted,
    'APPROVED' => l.statusApproved,
    'VERIFIED' => l.statusVerified,
    'SUCCESS' => l.statusSuccess,
    'PENDING' => l.statusPending,
    'PROCESSING' => l.statusProcessing,
    'INITIATED' => l.statusInitiated,
    'PARTIAL' => l.statusPartial,
    'DUE' => l.statusDue,
    'FAILED' => l.statusFailed,
    'OVERDUE' => l.statusOverdue,
    'INACTIVE' => l.statusInactive,
    'CANCELLED' => l.statusCancelled,
    'REJECTED' => l.statusRejected,
    'INFO' => l.statusInfo,
    'DRAFT' => l.statusDraft,
    'SCHEDULED' => l.statusScheduled,
    'UNKNOWN' => l.statusUnknown,
    'REFUNDED' => l.receiptStatusRefunded,
    'NOT_CONFIGURED' => l.statusNotConfigured,
    _ => null,
  };
}

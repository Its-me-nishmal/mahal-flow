import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/dues_period.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../l10n/l10n.dart';

/// -------------------------------------------------------------------------
/// Hero header content. The gradient itself is painted by the screen so it
/// can extend behind both the status bar and the balance card.
/// -------------------------------------------------------------------------
class DashboardHero extends StatelessWidget {
  final String firstName;
  final String mahalName;
  final VoidCallback onAvatarTap;
  final VoidCallback onHelpTap;

  const DashboardHero({
    super.key,
    required this.firstName,
    required this.mahalName,
    required this.onAvatarTap,
    required this.onHelpTap,
  });

  @override
  Widget build(BuildContext context) {
    const onHero = AppBrand.onBrand;
    final onHeroMuted = AppBrand.onBrand.withValues(alpha: 0.72);
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'M';

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenH,
        right: AppSpacing.screenH,
        top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
        bottom: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                button: true,
                label: context.l10n.homeOpenProfile,
                child: InkWell(
                  onTap: onAvatarTap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppBrand.onBrand.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppBrand.onBrand.withValues(alpha: 0.28),
                      ),
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        initial,
                        style: context.text.cardTitle.copyWith(color: onHero),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  context.l10n.appName,
                  textAlign: TextAlign.center,
                  style: context.text.sectionTitle.copyWith(
                    color: onHero,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onHelpTap,
                tooltip: context.l10n.homeHelp,
                icon: Icon(Icons.help_outline_rounded, color: onHeroMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.homeGreeting,
            style: context.text.small.copyWith(
              color: onHeroMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Semantics(
            header: true,
            child: Text(
              firstName,
              style: context.text.display.copyWith(color: onHero),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.mosque_outlined, size: 15, color: onHeroMuted),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  mahalName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.small.copyWith(color: onHeroMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// -------------------------------------------------------------------------
/// Balance card — the one thing a member opens this screen for.
/// Floats over the lower edge of the hero gradient.
/// -------------------------------------------------------------------------
class BalanceCard extends StatelessWidget {
  final double outstanding;
  final double advanceCredit;
  final String? pendingSummary;
  final List<DueMonth> months;
  final String? paidUpToLabel;
  final VoidCallback onPayDues;
  final VoidCallback onContribute;

  const BalanceCard({
    super.key,
    required this.outstanding,
    required this.advanceCredit,
    required this.pendingSummary,
    required this.months,
    required this.paidUpToLabel,
    required this.onPayDues,
    required this.onContribute,
  });

  bool get _isUpToDate => outstanding <= 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg - 2),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: context.colors.border),
        boxShadow: context.colors.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isUpToDate
                      ? context.l10n.homeMonthlyDuesLabel
                      : context.l10n.homeOutstandingDuesLabel,
                  style: context.text.label,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Longer translations shrink the pill instead of overflowing.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: _isUpToDate
                      ? StatusPill(
                          label: context.l10n.homeUpToDate,
                          foreground: context.colors.success,
                          background: context.colors.successBg,
                          icon: Icons.check_circle_rounded,
                        )
                      : StatusPill(
                          label: context.l10n.homeActionRequired,
                          foreground: context.colors.warning,
                          background: context.colors.warningBg,
                          icon: Icons.error_outline_rounded,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Inr.format(_isUpToDate ? 0 : outstanding),
                    semanticsLabel: _isUpToDate
                        ? context.l10n.homeNoOutstandingSemantics
                        : context.l10n
                            .homeOutstandingSemantics(Inr.spoken(outstanding)),
                    style: context.text.amount.copyWith(
                      color: _isUpToDate ? context.colors.success : context.colors.error,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _subtitle(context),
                  style: context.text.body.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (months.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.ms),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [for (final m in months) _monthChip(context, m)],
            ),
          ],
          if (advanceCredit > 0) ...[
            const SizedBox(height: AppSpacing.ms),
            StatusPill(
              label: context.l10n.homeAdvanceCredit(Inr.format(advanceCredit)),
              foreground: context.colors.info,
              background: context.colors.infoBg,
              icon: Icons.savings_outlined,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _isUpToDate ? _secondaryCta(context) : _primaryCta(context),
        ],
      ),
    );
  }

  String _subtitle(BuildContext context) {
    final l10n = context.l10n;
    if (_isUpToDate) {
      return paidUpToLabel == null
          ? l10n.homeAllDuesPaid
          : l10n.homeAllDuesPaidUpTo(paidUpToLabel!);
    }
    return pendingSummary ?? l10n.homePendingDues;
  }

  Widget _monthChip(BuildContext context, DueMonth month) {
    final isOverdue = month.status == DueMonthStatus.overdue;
    final foreground = isOverdue ? context.colors.error : context.colors.warning;
    final background = isOverdue ? context.colors.errorBg : context.colors.warningBg;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.ms,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        month.shortLabel,
        semanticsLabel: isOverdue
            ? context.l10n.homeMonthOverdueSemantics(month.longLabel)
            : context.l10n.homeMonthDueNowSemantics(month.longLabel),
        style: context.text.small.copyWith(
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Widget _primaryCta(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPayDues,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.primary,
          foregroundColor: context.colors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        // Scale down rather than ellipsize: a truncated amount is worse than
        // a slightly smaller one. Large balances (lakhs) need this at 360dp.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.homePayAmount(Inr.format(outstanding)),
                maxLines: 1,
                style: context.text.button
                    .copyWith(color: context.colors.onPrimary),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.arrow_forward_rounded, size: 19),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secondaryCta(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onContribute,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.colors.primary,
          backgroundColor: context.colors.surface,
          side: BorderSide(color: context.colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.l10n.homeMakeContribution,
            maxLines: 1,
            style: context.text.button.copyWith(color: context.colors.primary),
          ),
        ),
      ),
    );
  }
}

/// -------------------------------------------------------------------------
/// Quick action tile — 2x2 grid replaces the old stack of list rows.
/// -------------------------------------------------------------------------
class QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String caption;
  final VoidCallback onTap;
  final int badgeCount;

  const QuickActionTile({
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
    final l10n = context.l10n;
    final head =
        badgeCount > 0 ? l10n.commonUnreadCount(label, badgeCount) : label;
    // One node per tile: "Notices, 3 unread. From the committee".
    return Semantics(
      button: true,
      label: l10n.homeTileSemantics(head, caption),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: context.colors.border),
              boxShadow: context.colors.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: Icon(icon, size: 21, color: iconColor),
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
                            color: context.colors.error,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border:
                                Border.all(color: context.colors.surface, width: 2),
                          ),
                          child: Text(
                            badgeCount > 9 ? '9+' : '$badgeCount',
                            style: context.text.label.copyWith(
                              color: context.colors.onPrimary,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.ms),
                Text(label, style: context.text.listTitle),
                const SizedBox(height: 2),
                Text(
                  caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// -------------------------------------------------------------------------
/// Latest payment. Renders an in-card empty state when there is nothing to
/// show (docs/design.md section 15) instead of vanishing.
/// -------------------------------------------------------------------------
class LatestPaymentCard extends StatelessWidget {
  final Map<String, dynamic>? receipt;
  final bool isUpToDate;
  final VoidCallback onViewReceipt;
  final VoidCallback onPrimaryAction;

  const LatestPaymentCard({
    super.key,
    required this.receipt,
    required this.isUpToDate,
    required this.onViewReceipt,
    required this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg - 2),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.colors.border),
        boxShadow: context.colors.cardShadow,
      ),
      child: receipt == null ? _empty(context) : _content(context),
    );
  }

  Widget _empty(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.homeLatestPayment, style: context.text.label),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.neutralBg,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 20,
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.homeNoPaymentsYet,
                    style: context.text.listTitle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.homeNoPaymentsBody,
                    style: context.text.small,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: onPrimaryAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.primary,
              side: BorderSide(color: context.colors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isUpToDate
                    ? context.l10n.homeMakeContribution
                    : context.l10n.homePayDuesNow,
                maxLines: 1,
                style: context.text.buttonMedium.copyWith(
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content(BuildContext context) {
    final data = receipt!;
    final rawAmount = data['amount'];
    final amount =
        rawAmount is num ? rawAmount : num.tryParse('${rawAmount ?? ''}');
    // Receipts are only issued for committed payments, so the API sends no
    // status; one it does send (e.g. REFUNDED) wins.
    final status = (data['status']?.toString() ?? 'SUCCESS').toUpperCase();
    final isPaid = status == 'SUCCESS' || status == 'PAID';
    final isDues = data['payment_type']?.toString() == 'MONTHLY_DUES';
    final paidMonths =
        (data['paid_months'] as List?)?.map((m) => m.toString()).toList() ??
            <String>[];

    // Invariant 3 (AGENTS.md): never label a dues receipt a contribution.
    final monthsLabel = DuesPeriod.paidMonthsLabel(paidMonths);
    final l10n = context.l10n;
    final description = isDues
        ? (monthsLabel.isEmpty
            ? l10n.receiptMonthlyDues
            : l10n.homeMonthsDues(monthsLabel))
        : l10n.receiptMahalContribution;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.homeLatestPayment, style: context.text.label),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: isPaid
                    ? StatusPill(
                        label: l10n.statusPaid,
                        foreground: context.colors.success,
                        background: context.colors.successBg,
                        icon: Icons.check_circle_rounded,
                      )
                    : StatusPill.forStatus(context, status),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.ms),
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Inr.formatAny(amount),
                  semanticsLabel: amount == null
                      ? l10n.homeLastPaymentUnavailable
                      : l10n.homeLastPaymentSemantics(Inr.spoken(amount)),
                  style: context.text.statValue,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: context.text.body.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(height: 1, color: context.colors.border),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _paidOnLabel(context, data['created_at'], isPaid: isPaid),
                  style: context.text.small.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
              ),
              InkWell(
                onTap: onViewReceipt,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.ms,
                  ),
                  child: Row(
                    children: [
                      Text(
                        l10n.receiptTitle,
                        style: context.text.buttonMedium.copyWith(
                          color: context.colors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs + 2),
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 16,
                        color: context.colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _paidOnLabel(BuildContext context, dynamic raw,
      {bool isPaid = true}) {
    final date = AppDate.formatDate(raw, fallback: '');
    if (date.isEmpty) return isPaid ? context.l10n.statusPaid : '—';
    return isPaid ? context.l10n.homePaidOn(date) : date;
  }
}

/// -------------------------------------------------------------------------
/// AutoPay nudge. Shown only when the server says no mandate exists.
/// -------------------------------------------------------------------------
class AutoPayNudgeCard extends StatelessWidget {
  final VoidCallback onSetUp;

  const AutoPayNudgeCard({super.key, required this.onSetUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: context.colors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.colors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(
              Icons.sync_rounded,
              size: 21,
              color: context.colors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.homeAutoPayOff,
                  style: context.text.listTitle,
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.homeAutoPayBody,
                  style: context.text.small,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onSetUp,
            style: TextButton.styleFrom(
              foregroundColor: context.colors.primary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
              minimumSize: const Size(0, 44),
            ),
            child: Text(
              context.l10n.homeAutoPaySetUp,
              style: context.text.buttonMedium.copyWith(
                color: context.colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// -------------------------------------------------------------------------
/// Skeleton mirroring the loaded layout so nothing jumps on swap
/// (docs/design.md section 14).
/// -------------------------------------------------------------------------
class MemberDashboardSkeleton extends StatelessWidget {
  const MemberDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _block(context, 196),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _block(context, 132)),
              const SizedBox(width: AppSpacing.ms),
              Expanded(child: _block(context, 132)),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          Row(
            children: [
              Expanded(child: _block(context, 132)),
              const SizedBox(width: AppSpacing.ms),
              Expanded(child: _block(context, 132)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _block(context, 156),
        ],
      ),
    );
  }

  Widget _block(BuildContext context, double height) => Container(
        height: height,
        decoration: BoxDecoration(
          color: context.colors.border.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      );
}

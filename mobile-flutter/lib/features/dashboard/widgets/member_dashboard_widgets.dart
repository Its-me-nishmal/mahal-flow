import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/dues_period.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/shimmer_loading.dart';

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
    const onHero = Colors.white;
    final onHeroMuted = Colors.white.withValues(alpha: 0.72);
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
                label: 'Open your profile',
                child: InkWell(
                  onTap: onAvatarTap,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      initial,
                      style: AppTextStyles.cardTitle.copyWith(color: onHero),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'MahalFlow',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageTitle.copyWith(
                    color: onHero,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: onHelpTap,
                tooltip: 'Help',
                icon: Icon(Icons.help_outline_rounded, color: onHeroMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Assalamu Alaikum',
            style: AppTextStyles.small.copyWith(
              color: onHeroMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Semantics(
            header: true,
            child: Text(
              firstName,
              style: AppTextStyles.display.copyWith(color: onHero),
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
                  style: AppTextStyles.small.copyWith(color: onHeroMuted),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.hero),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.floating,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isUpToDate ? 'MONTHLY DUES' : 'OUTSTANDING DUES',
                  style: AppTextStyles.label,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _isUpToDate
                  ? const StatusPill(
                      label: 'Up to Date',
                      foreground: AppColors.success,
                      background: AppColors.successBg,
                      icon: Icons.check_circle_rounded,
                    )
                  : const StatusPill(
                      label: 'Action Required',
                      foreground: AppColors.warning,
                      background: AppColors.warningBg,
                      icon: Icons.error_outline_rounded,
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
                        ? 'No outstanding dues'
                        : 'Outstanding dues ${Inr.spoken(outstanding)}',
                    style: AppTextStyles.amount.copyWith(
                      color: _isUpToDate ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _subtitle,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
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
              children: months.map(_monthChip).toList(),
            ),
          ],
          if (advanceCredit > 0) ...[
            const SizedBox(height: AppSpacing.ms),
            StatusPill(
              label: 'Advance credit ${Inr.format(advanceCredit)}',
              foreground: AppColors.info,
              background: AppColors.infoBg,
              icon: Icons.savings_outlined,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _isUpToDate ? _secondaryCta() : _primaryCta(),
        ],
      ),
    );
  }

  String get _subtitle {
    if (_isUpToDate) {
      return paidUpToLabel == null
          ? 'All monthly dues paid in full.'
          : 'All dues paid up to $paidUpToLabel.';
    }
    return pendingSummary ?? 'Pending monthly dues.';
  }

  Widget _monthChip(DueMonth month) {
    final isOverdue = month.status == DueMonthStatus.overdue;
    final foreground = isOverdue ? AppColors.error : AppColors.warning;
    final background = isOverdue ? AppColors.errorBg : AppColors.warningBg;

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
        semanticsLabel:
            '${month.longLabel}, ${isOverdue ? 'overdue' : 'due now'}',
        style: AppTextStyles.small.copyWith(
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Widget _primaryCta() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPayDues,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
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
                'Pay ${Inr.format(outstanding)}',
                maxLines: 1,
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.arrow_forward_rounded, size: 19),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secondaryCta() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onContribute,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
        child: Text(
          'Make a Contribution',
          style: AppTextStyles.button.copyWith(color: AppColors.primary),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: receipt == null ? _empty() : _content(),
    );
  }

  Widget _empty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('LATEST PAYMENT', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.neutralBg,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 20,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No payments yet',
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your receipts will appear here once you pay.',
                    style: AppTextStyles.small,
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
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              isUpToDate ? 'Make a Contribution' : 'Pay Dues Now',
              style: AppTextStyles.button.copyWith(
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content() {
    final data = receipt!;
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final isDues = data['payment_type']?.toString() == 'MONTHLY_DUES';
    final paidMonths = (data['paid_months'] as List?)
            ?.map((m) => m.toString())
            .toList() ??
        const <String>[];

    // Invariant 3 (AGENTS.md): never label a dues receipt a contribution.
    final monthsLabel = DuesPeriod.paidMonthsLabel(paidMonths);
    final description = isDues
        ? (monthsLabel.isEmpty ? 'Monthly Dues' : '$monthsLabel Dues')
        : 'Mahal Contribution';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('LATEST PAYMENT', style: AppTextStyles.label)),
            const StatusPill(
              label: 'Paid',
              foreground: AppColors.success,
              background: AppColors.successBg,
              icon: Icons.check_circle_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.ms),
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Inr.format(amount),
                semanticsLabel: 'Last payment ${Inr.spoken(amount)}',
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _paidOnLabel(data['created_at']?.toString()),
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textMuted,
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
                        'Receipt',
                        style: AppTextStyles.button.copyWith(
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs + 2),
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 16,
                        color: AppColors.primary,
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

  static String _paidOnLabel(String? raw) {
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    if (parsed == null) return 'Recently paid';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return 'Paid on ${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }
}

/// -------------------------------------------------------------------------
/// AutoPay nudge. Shown only while the local flag says setup is incomplete.
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
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: const Icon(
              Icons.sync_rounded,
              size: 21,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AutoPay is off',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Never miss a month. Pay dues automatically.',
                  style: AppTextStyles.small,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onSetUp,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
              minimumSize: const Size(0, 44),
            ),
            child: Text(
              'Set up',
              style: AppTextStyles.button.copyWith(
                fontSize: 14,
                color: AppColors.primary,
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
          _block(196),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _block(132)),
              const SizedBox(width: AppSpacing.ms),
              Expanded(child: _block(132)),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          Row(
            children: [
              Expanded(child: _block(132)),
              const SizedBox(width: AppSpacing.ms),
              Expanded(child: _block(132)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _block(156),
        ],
      ),
    );
  }

  Widget _block(double height) => Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      );
}

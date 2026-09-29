import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../l10n/l10n.dart';
import '../utils/admin_format.dart';

/// Numbers from GET /admin/dashboard.
class AdminDashboardStats {
  /// Completed payments this calendar month (`total_collected_mtd`,
  /// month-to-date in the server's timezone, Asia/Kolkata).
  final double totalCollected;

  /// All-time sum (`total_collected_all_time`); null on older servers.
  final double? totalCollectedAllTime;
  final double pendingDues;
  final int paidMembers;
  final int pendingMembers;
  final int totalMembers;
  final String subscriptionStatus;

  const AdminDashboardStats({
    required this.totalCollected,
    this.totalCollectedAllTime,
    required this.pendingDues,
    required this.paidMembers,
    required this.pendingMembers,
    required this.totalMembers,
    required this.subscriptionStatus,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> d) {
    double dbl(String k) => (d[k] as num?)?.toDouble() ?? 0;
    int i(String k) => (d[k] as num?)?.toInt() ?? 0;
    return AdminDashboardStats(
      totalCollected: dbl('total_collected_mtd'),
      totalCollectedAllTime:
          (d['total_collected_all_time'] as num?)?.toDouble(),
      pendingDues: dbl('total_pending_dues'),
      paidMembers: i('paid_members'),
      pendingMembers: i('pending_members'),
      totalMembers: i('total_members'),
      subscriptionStatus: d['subscription_status']?.toString() ?? '',
    );
  }

  double get collectionRate =>
      totalMembers > 0 ? (paidMembers / totalMembers) : 0.0;
}

/// Floating card: collected amount, outstanding, collection rate.
class CollectionCard extends StatelessWidget {
  final AdminDashboardStats? stats;
  const CollectionCard({super.key, required this.stats});

  static String subscriptionLabel(String raw) {
    final l = L10n.current;
    switch (raw.toUpperCase()) {
      case 'ACTIVE':
        return l.adminDashSubscriptionActive;
      case '':
        return l.adminDashSubscriptionUnknown;
      default:
        return l.adminDashSubscriptionStatus(AdminFormat.humanize(raw));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = stats;
    if (s == null) {
      return AppCard.floating(
        child: ShimmerLoading(
          semanticsLabel: context.l10n.adminDashLoadingCollection,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerSkeletonBox(width: 140, height: 12),
              SizedBox(height: AppSpacing.ms),
              ShimmerSkeletonBox(width: 200, height: 34),
              SizedBox(height: AppSpacing.md),
              ShimmerSkeletonBox(width: double.infinity, height: 8),
            ],
          ),
        ),
      );
    }

    final pct = (s.collectionRate * 100).round();
    final healthy = s.collectionRate >= 0.7;
    final subActive = s.subscriptionStatus.toUpperCase() == 'ACTIVE';
    final l10n = context.l10n;

    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.adminDashCollectedMonthCaps,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.label,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: StatusPill(
                    label: subscriptionLabel(s.subscriptionStatus),
                    foreground:
                        subActive ? context.colors.success : context.colors.warning,
                    background: subActive
                        ? context.colors.successBg
                        : context.colors.warningBg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Inr.format(s.totalCollected),
              semanticsLabel:
                  l10n.adminDashCollectedMonthSpoken(Inr.spoken(s.totalCollected)),
              style: context.text.amount.copyWith(color: context.colors.success),
            ),
          ),
          if (s.totalCollectedAllTime != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.adminDashAllTime(Inr.format(s.totalCollectedAllTime!)),
              style: context.text.small,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.adminDashOutstandingAcrossMahal(
                Inr.format(s.pendingDues < 0 ? 0 : s.pendingDues)),
            style: context.text.body.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(l10n.adminDashCollectionRate,
                    style: context.text.small),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.adminDashPaidOfTotal(
                      s.paidMembers, s.totalMembers, pct),
                  textAlign: TextAlign.end,
                  style: context.text.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        healthy ? context.colors.success : context.colors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: s.collectionRate.clamp(0.0, 1.0),
              semanticsLabel: l10n.adminDashCollectionRate,
              semanticsValue: l10n.adminDashPercentValue(pct),
              backgroundColor: context.colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                healthy ? context.colors.success : context.colors.warning,
              ),
              minHeight: AppSpacing.sm,
            ),
          ),
        ],
      ),
    );
  }
}

/// 2×2 stat tiles.
class DashboardStatGrid extends StatelessWidget {
  final AdminDashboardStats? stats;
  final VoidCallback onReports;
  final VoidCallback onMembers;

  const DashboardStatGrid({
    super.key,
    required this.stats,
    required this.onReports,
    required this.onMembers,
  });

  @override
  Widget build(BuildContext context) {
    final s = stats;
    if (s == null) return _skeleton(context);
    final l10n = context.l10n;

    Widget row(Widget a, Widget b) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: a),
              const SizedBox(width: AppSpacing.ms),
              Expanded(child: b),
            ],
          ),
        );

    return Column(
      children: [
        row(
          AppStatTile(
            label: l10n.adminDashCollectedMonth,
            value: Inr.format(s.totalCollected),
            icon: Icons.trending_up_rounded,
            color: context.colors.success,
            background: context.colors.successBg,
            onTap: onReports,
          ),
          AppStatTile(
            label: l10n.adminDashPendingDues,
            value: Inr.format(s.pendingDues < 0 ? 0 : s.pendingDues),
            icon: Icons.schedule_rounded,
            color: context.colors.warning,
            background: context.colors.warningBg,
            onTap: onReports,
          ),
        ),
        const SizedBox(height: AppSpacing.ms),
        row(
          AppStatTile(
            label: l10n.adminDashMembersPaid,
            value: '${s.paidMembers}',
            caption: l10n.adminDashOfHouseholds(s.totalMembers),
            icon: Icons.check_circle_outline_rounded,
            color: context.colors.info,
            background: context.colors.infoBg,
            onTap: onMembers,
          ),
          AppStatTile(
            label: l10n.adminDashMembersPending,
            value: '${s.pendingMembers}',
            caption: l10n.adminDashNeedReminder,
            icon: Icons.pending_outlined,
            color: context.colors.error,
            background: context.colors.errorBg,
            onTap: onMembers,
          ),
        ),
      ],
    );
  }

  Widget _skeleton(BuildContext context) {
    return ShimmerLoading(
      semanticsLabel: context.l10n.adminDashLoadingOverview,
      child: const Column(
        children: [
          Row(
            children: [
              Expanded(child: ShimmerCardSkeleton(height: 116)),
              SizedBox(width: AppSpacing.ms),
              Expanded(child: ShimmerCardSkeleton(height: 116)),
            ],
          ),
          Row(
            children: [
              Expanded(child: ShimmerCardSkeleton(height: 116)),
              SizedBox(width: AppSpacing.ms),
              Expanded(child: ShimmerCardSkeleton(height: 116)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Latest Mahal-wide transactions from GET /admin/payments.
class RecentTransactionsCard extends StatelessWidget {
  /// Null while loading.
  final List<Map<String, dynamic>>? payments;
  final ApiException? error;
  final Map<String, String> memberNames;
  final VoidCallback onRetry;
  final ValueChanged<String> onOpenReceipt;

  const RecentTransactionsCard({
    super.key,
    required this.payments,
    required this.error,
    required this.memberNames,
    required this.onRetry,
    required this.onOpenReceipt,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return AppNoticeCard(
        icon: Icons.cloud_off_rounded,
        title: context.l10n.adminDashTransactionsError,
        message: error!.userMessage,
        color: context.colors.error,
        background: context.colors.errorBg,
        actionLabel: context.l10n.adminTryAgain,
        onAction: onRetry,
      );
    }
    final list = payments;
    if (list == null) {
      return ShimmerLoading(
        semanticsLabel: context.l10n.adminDashLoadingTransactions,
        child: const Column(
          children: [
            ShimmerCardSkeleton(height: 64),
            ShimmerCardSkeleton(height: 64),
            ShimmerCardSkeleton(height: 64),
          ],
        ),
      );
    }
    if (list.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            AppIconChip(
              icon: Icons.receipt_long_outlined,
              color: context.colors.textMuted,
              background: context.colors.neutralBg,
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.adminDashNoTransactions,
                      style: context.text.listTitle),
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    context.l10n.adminDashNoTransactionsBody,
                    style: context.text.small,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < list.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.colors.border),
            _row(context, list[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, Map<String, dynamic> t) {
    final memberId = t['member_id']?.toString() ?? '';
    final name = memberNames[memberId];
    final display = (name == null || name.isEmpty)
        ? (memberId.isEmpty ? context.l10n.commonMember : memberId)
        : name;
    final receipt = t['receipt_id']?.toString() ?? '';
    final status = t['status']?.toString() ?? '';
    final when = AppDate.relative(t['completed_at'] ?? t['created_at']);

    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.ms,
      ),
      child: Row(
        children: [
          AppAvatar(name: name, size: 40, excludeFromSemantics: true),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.listTitle),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  '${AdminFormat.paymentType(t['type']?.toString())} · $when',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.small,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(Inr.formatAny(t['amount']),
                      style: context.text.listTitle),
                ),
                const SizedBox(height: AppSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: StatusPill.forStatus(context, status),
                ),
              ],
            ),
          ),
          if (receipt.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: context.colors.textMuted),
          ],
        ],
      ),
    );

    if (receipt.isEmpty) return content;
    return InkWell(onTap: () => onOpenReceipt(receipt), child: content);
  }
}

/// Hero-coloured call to action for the broadcast composer.
class BroadcastCard extends StatelessWidget {
  final VoidCallback onCompose;
  const BroadcastCard({super.key, required this.onCompose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: context.colors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_rounded,
                  color: AdminHeroColors.text, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.adminBroadcastNotice,
                  style: context.text.cardTitle
                      .copyWith(color: AdminHeroColors.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.adminDashBroadcastBody,
            style: context.text.small.copyWith(color: AdminHeroColors.muted),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            label: context.l10n.adminDashComposeNotice,
            icon: Icons.edit_outlined,
            height: AppSizes.buttonHeightCompact,
            onPressed: onCompose,
          ),
        ],
      ),
    );
  }
}

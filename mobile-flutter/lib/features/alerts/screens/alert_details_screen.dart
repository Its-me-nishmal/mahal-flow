import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';

/// Kind of notice. Only [overdue] asks the member to pay.
///
/// * [overdue]   — dues reminder / overdue notice (shows "Pay Dues Now").
/// * [payment]   — about a payment (e.g. failed attempt), no pay prompt.
/// * [success]   — payment received / receipt issued.
/// * [important] — urgent committee notice (WARNING / CRITICAL).
/// * [system]    — announcement.
enum AlertType { payment, overdue, success, system, default_, important }

/// Classifies an alert from the API's structured fields — never from words
/// in its title ("Payment received" must not become a pay prompt).
///
/// Uses `type` / `category` / `kind` when the server sends one (DUES_REMINDER,
/// OVERDUE, PAYMENT_FAILED, RECEIPT, …), then `audience` (OVERDUE_ONLY is by
/// definition a dues reminder), then `severity`.
AlertType alertTypeFromApi(Map<String, dynamic> alert) {
  final kind = (alert['type'] ?? alert['category'] ?? alert['kind'])
          ?.toString()
          .toUpperCase() ??
      '';
  switch (kind) {
    case 'DUES_REMINDER':
    case 'DUES_OVERDUE':
    case 'OVERDUE':
    case 'PAYMENT_DUE':
      return AlertType.overdue;
    case 'RECEIPT':
    case 'PAYMENT_RECEIVED':
    case 'PAYMENT_SUCCESS':
    case 'AUTOPAY_SUCCESS':
      return AlertType.success;
    case 'PAYMENT':
    case 'PAYMENT_FAILED':
    case 'AUTOPAY':
    case 'AUTOPAY_FAILED':
      return AlertType.payment;
  }
  if (alert['audience']?.toString().toUpperCase() == 'OVERDUE_ONLY') {
    return AlertType.overdue;
  }
  switch (alert['severity']?.toString().toUpperCase()) {
    case 'SUCCESS':
      return AlertType.success;
    case 'CRITICAL':
    case 'WARNING':
    case 'ERROR':
      return AlertType.important;
  }
  return AlertType.system;
}

/// Icon, colour and label for an [AlertType]; shared by the list and detail.
class AlertVisual {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const AlertVisual(this.label, this.icon, this.color, this.background);

  static AlertVisual of(BuildContext context, AlertType type) {
    switch (type) {
      case AlertType.payment:
        return AlertVisual('Payment', Icons.payments_outlined,
            context.colors.info, context.colors.infoBg);
      case AlertType.overdue:
        return AlertVisual('Dues reminder', Icons.error_outline_rounded,
            context.colors.error, context.colors.errorBg);
      case AlertType.success:
        return AlertVisual(
            'Confirmed',
            Icons.check_circle_outline_rounded,
            context.colors.success,
            context.colors.successBg);
      case AlertType.important:
        return AlertVisual('Important', Icons.priority_high_rounded,
            context.colors.warning, context.colors.warningBg);
      case AlertType.system:
        return AlertVisual('Announcement', Icons.campaign_outlined,
            context.colors.primary, context.colors.primaryLight);
      case AlertType.default_:
        return AlertVisual('Notice', Icons.info_outline_rounded,
            context.colors.textSecondary, context.colors.neutralBg);
    }
  }
}

class AlertDetailsScreen extends StatelessWidget {
  final String title;
  final String body;

  /// Already-formatted time; hidden when empty.
  final String time;
  final AlertType type;

  const AlertDetailsScreen({
    super.key,
    this.title = "Notice",
    this.body = "",
    this.time = "",
    this.type = AlertType.system,
  });

  bool get _needsPayment => type == AlertType.overdue;

  @override
  Widget build(BuildContext context) {
    final visual = AlertVisual.of(context, type);

    return AppPageScaffold(
      title: 'Notice',
      eyebrow: visual.label,
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          AppNav.switchMemberTab(context, AppRoutes.memberAlerts);
        }
      },
      floatingChild: AppCard.floating(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconChip(
                  icon: visual.icon,
                  color: visual.color,
                  background: visual.background,
                ),
                const SizedBox(width: AppSpacing.ms),
                StatusPill(
                  label: visual.label,
                  foreground: visual.color,
                  background: visual.background,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Semantics(
              header: true,
              child: Text(title, style: context.text.sectionTitle),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                time,
                style: context.text.small.copyWith(color: context.colors.textMuted),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: context.colors.border),
            const SizedBox(height: AppSpacing.md),
            Text(
              body.isEmpty ? 'No further details were provided.' : body,
              style: context.text.body.copyWith(
                color: context.colors.textSecondary,
                height: 22 / 14,
              ),
            ),
          ],
        ),
      ),
      content: [
        const SizedBox(height: AppSpacing.md),
        if (_needsPayment)
          AppNoticeCard(
            icon: Icons.info_outline_rounded,
            title: 'Why you got this',
            message: 'Your account shows dues that are not yet cleared.',
            color: context.colors.info,
            background: context.colors.infoBg,
          ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          if (_needsPayment)
            AppPrimaryButton(
              label: 'Pay Dues Now',
              icon: Icons.arrow_forward_rounded,
              onPressed: () =>
                  AppNav.switchMemberTab(context, AppRoutes.memberPay),
            )
          else
            AppSecondaryButton(
              label: 'Close',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
        ],
      ),
    );
  }
}

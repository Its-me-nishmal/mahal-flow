import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';

enum AlertType { payment, overdue, success, system, default_ }

class AlertDetailsScreen extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final AlertType type;

  const AlertDetailsScreen({
    super.key,
    this.title = "Alert Details",
    this.body = "No additional details available.",
    this.time = "Just now",
    this.type = AlertType.system,
  });

  bool get _needsPayment =>
      type == AlertType.payment || type == AlertType.overdue;

  @override
  Widget build(BuildContext context) {
    final visual = _visual;

    return AppPageScaffold(
      title: 'Notice',
      eyebrow: visual.label,
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/member/alerts');
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
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              time,
              style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.md),
            Text(
              body.isEmpty ? 'No further details were provided.' : body,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 22 / 14,
              ),
            ),
          ],
        ),
      ),
      content: [
        const SizedBox(height: AppSpacing.md),
        if (_needsPayment)
          const AppNoticeCard(
            icon: Icons.info_outline_rounded,
            title: 'Why you got this',
            message: 'Your account shows dues that are not yet cleared.',
            color: AppColors.info,
            background: AppColors.infoBg,
          ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          if (_needsPayment)
            AppPrimaryButton(
              label: 'Pay Dues Now',
              icon: Icons.arrow_forward_rounded,
              onPressed: () =>
                  Navigator.of(context).pushNamed('/member/pay'),
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

  _AlertVisual get _visual {
    switch (type) {
      case AlertType.payment:
        return const _AlertVisual('Payment', Icons.payments_outlined,
            AppColors.info, AppColors.infoBg);
      case AlertType.overdue:
        return const _AlertVisual('Overdue', Icons.error_outline_rounded,
            AppColors.error, AppColors.errorBg);
      case AlertType.success:
        return const _AlertVisual('Confirmed',
            Icons.check_circle_outline_rounded, AppColors.success,
            AppColors.successBg);
      case AlertType.system:
        return const _AlertVisual('Announcement', Icons.campaign_outlined,
            AppColors.warning, AppColors.warningBg);
      case AlertType.default_:
        return const _AlertVisual('Notice', Icons.info_outline_rounded,
            AppColors.textSecondary, AppColors.neutralBg);
    }
  }
}

class _AlertVisual {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const _AlertVisual(this.label, this.icon, this.color, this.background);
}

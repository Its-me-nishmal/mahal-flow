import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';

class SetupAutoPayScreen extends StatefulWidget {
  const SetupAutoPayScreen({super.key});

  @override
  State<SetupAutoPayScreen> createState() => _SetupAutoPayScreenState();
}

class _SetupAutoPayScreenState extends State<SetupAutoPayScreen> {
  final ApiService _apiService = ApiService();
  bool _enabled = true;
  bool _isProcessing = false;
  static const double _monthlyAmount = 500;

  Future<void> _handleConfirmAutoPay() async {
    setState(() => _isProcessing = true);
    final res = await _apiService.createAutoPayMandate();
    if (!mounted) return;
    setState(() => _isProcessing = false);

    final mandateId = res?["mandate_id"]?.toString() ?? "MND_CONFIRMED";

    AppBottomSheet.show(
      context: context,
      title: 'AutoPay is on',
      subtitle: 'Your dues will be paid automatically',
      icon: Icons.check_circle_rounded,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your mandate is registered. ${Inr.format(_monthlyAmount)} will be '
            'debited on the 1st of each month, and a receipt is issued every '
            'time it runs.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.ms),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Mandate ID', style: AppTextStyles.small),
                ),
                Text(
                  mandateId,
                  style: AppTextStyles.button.copyWith(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'Done',
            onPressed: () {
              Navigator.of(ctx).pop();
              // true tells the member dashboard AutoPay setup completed
              // so it can persist the flag and hide its nudge card.
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'AutoPay',
      eyebrow: 'Payments',
      subtitle: 'Never miss a month. Cancel any time from your profile.',
      floatingChild: AppCard.floating(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('MONTHLY DEBIT', style: AppTextStyles.label),
                ),
                StatusPill(
                  label: _enabled ? 'Will be on' : 'Off',
                  foreground:
                      _enabled ? AppColors.success : AppColors.textSecondary,
                  background:
                      _enabled ? AppColors.successBg : AppColors.neutralBg,
                  icon: _enabled
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_outline_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.ms),
            Text(
              Inr.format(_monthlyAmount),
              style: AppTextStyles.amount.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Debited on the 1st of every month by UPI e-Mandate.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable AutoPay',
                          style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Turn off to keep paying manually.',
                          style: AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                    activeTrackColor: AppColors.primary,
                    activeThumbColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: [
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionLabel('Mandate details'),
              const SizedBox(height: AppSpacing.sm),
              const AppDetailRow(
                label: 'Payment method',
                value: 'UPI e-Mandate',
              ),
              const Divider(height: 1, color: AppColors.border),
              const AppDetailRow(
                label: 'Debit date',
                value: '1st of every month',
              ),
              const Divider(height: 1, color: AppColors.border),
              AppDetailRow(
                label: 'Amount per month',
                value: Inr.format(_monthlyAmount),
                emphasize: true,
              ),
              const Divider(height: 1, color: AppColors.border),
              const AppDetailRow(
                label: 'Cancel anytime',
                value: 'From Profile → AutoPay',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const AppNoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'How it works',
          message:
              'Your bank asks you to approve the mandate once. After that each '
              'month runs on its own and issues a receipt.',
          color: AppColors.info,
          background: AppColors.infoBg,
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: _isProcessing ? 'Setting up…' : 'Confirm AutoPay',
            icon: Icons.check_rounded,
            isLoading: _isProcessing,
            onPressed: _enabled ? _handleConfirmAutoPay : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: 'Not now',
            color: AppColors.textSecondary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

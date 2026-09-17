import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../widgets/payment_result_view.dart';

class PaymentFailedScreen extends StatelessWidget {
  final String amount;
  final String reason;
  final String date;

  const PaymentFailedScreen({
    super.key,
    this.amount = '₹1,500',
    this.reason = 'The bank declined the transaction',
    this.date = 'Aug 15, 2026',
  });

  @override
  Widget build(BuildContext context) {
    return PaymentResultView(
      headline: 'Payment failed',
      // Say plainly that no money moved — that is the first thing a member
      // wants to know after a failure.
      message: 'No money was taken. You can try again with another method.',
      amount: amount,
      icon: Icons.close_rounded,
      color: AppColors.error,
      background: AppColors.errorBg,
      statusLabel: 'Failed',
      primaryLabel: 'Try Again',
      primaryIcon: Icons.refresh_rounded,
      onPrimary: () => Navigator.of(context).pushNamedAndRemoveUntil(
        '/member/pay',
        (route) => false,
      ),
      secondaryLabel: 'Back to Home',
      onSecondary: () => Navigator.of(context).pushNamedAndRemoveUntil(
        '/member/dashboard',
        (route) => false,
      ),
      details: [
        AppDetailRow(label: 'Reason', value: reason),
        const Divider(height: 1, color: AppColors.border),
        AppDetailRow(label: 'Attempted', value: date),
        const Divider(height: 1, color: AppColors.border),
        const AppDetailRow(label: 'Amount debited', value: 'None'),
      ],
    );
  }
}

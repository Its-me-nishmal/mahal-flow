import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../widgets/payment_result_view.dart';

class PaymentPendingScreen extends StatelessWidget {
  final String amount;
  final String coverage;
  final String date;

  const PaymentPendingScreen({
    super.key,
    this.amount = '₹1,500',
    this.coverage = 'Jun–Aug 2026',
    this.date = 'Aug 15, 2026',
  });

  @override
  Widget build(BuildContext context) {
    return PaymentResultView(
      headline: 'Payment pending',
      // Telling the member not to retry is the whole point of this screen:
      // a second attempt while the first settles creates a double charge.
      message: 'Your bank is still confirming this. Do not pay again — we will '
          'update your dues as soon as it clears.',
      amount: amount,
      icon: Icons.schedule_rounded,
      color: AppColors.warning,
      background: AppColors.warningBg,
      statusLabel: 'Pending',
      primaryLabel: 'Back to Home',
      primaryIcon: Icons.home_rounded,
      onPrimary: () => Navigator.of(context).pushNamedAndRemoveUntil(
        '/member/dashboard',
        (route) => false,
      ),
      secondaryLabel: 'View Receipts',
      onSecondary: () => Navigator.of(context).pushNamedAndRemoveUntil(
        '/member/receipts',
        (route) => false,
      ),
      details: [
        AppDetailRow(label: 'Covers', value: coverage),
        const Divider(height: 1, color: AppColors.border),
        AppDetailRow(label: 'Started', value: date),
        const Divider(height: 1, color: AppColors.border),
        const AppDetailRow(
          label: 'Usually clears in',
          value: 'A few minutes',
        ),
      ],
    );
  }
}

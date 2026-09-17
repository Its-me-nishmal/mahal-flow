import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../widgets/payment_result_view.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String amount;
  final String coverage;
  final String date;
  final String receiptNumber;

  const PaymentSuccessScreen({
    super.key,
    this.amount = '₹1,500',
    this.coverage = 'Jun–Aug 2026',
    this.date = 'Aug 15, 2026',
    this.receiptNumber = 'GV1MH00120260803R00002',
  });

  @override
  Widget build(BuildContext context) {
    return PaymentResultView(
      headline: 'Payment successful',
      message: 'Your dues are cleared. A receipt has been issued in your name.',
      amount: amount,
      icon: Icons.check_rounded,
      color: AppColors.success,
      background: AppColors.successBg,
      statusLabel: 'Paid',
      primaryLabel: 'View Receipt',
      primaryIcon: Icons.receipt_long_rounded,
      onPrimary: () => Navigator.of(context).pushNamedAndRemoveUntil(
        '/member/receipts',
        (route) => false,
      ),
      secondaryLabel: 'Back to Home',
      onSecondary: () => Navigator.of(context).pushNamedAndRemoveUntil(
        '/member/dashboard',
        (route) => false,
      ),
      details: [
        AppDetailRow(label: 'Covers', value: coverage),
        const Divider(height: 1, color: AppColors.border),
        AppDetailRow(label: 'Paid on', value: date),
        const Divider(height: 1, color: AppColors.border),
        AppDetailRow(
          label: 'Receipt number',
          value: receiptNumber,
          emphasize: true,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../receipts/screens/receipt_details_screen.dart';
import '../payment_result_args.dart';
import '../widgets/payment_result_view.dart';

/// Shown only after the server confirmed the payment and issued a receipt.
class PaymentSuccessScreen extends StatelessWidget {
  final PaymentResultArgs args;

  const PaymentSuccessScreen({super.key, required this.args});

  bool get _isDues => args.kind == PaymentKind.dues;

  void _viewReceipt(BuildContext context) {
    final receipt = args.receipt;
    if (receipt == null) {
      AppNav.switchMemberTab(context, AppRoutes.memberReceipts);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReceiptDetailsScreen.fromJson(receipt)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back from a finished payment goes home, never to the pay form.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) AppNav.memberHome(context);
      },
      child: PaymentResultView(
        headline: _isDues ? 'Payment successful' : 'Thank you',
        message: _isDues
            ? 'Your dues are cleared. A receipt has been issued in your name.'
            : 'Your contribution was received. A receipt has been issued in '
                'your name.',
        amount: Inr.formatAny(args.amount),
        icon: Icons.check_rounded,
        color: context.colors.success,
        background: context.colors.successBg,
        statusLabel: 'Paid',
        primaryLabel: 'View Receipt',
        primaryIcon: Icons.receipt_long_rounded,
        onPrimary: () => _viewReceipt(context),
        secondaryLabel: 'Back to Home',
        onSecondary: () => AppNav.memberHome(context),
        details: [
          AppDetailRow(
            label: _isDues ? 'Covers' : 'Fund',
            value: args.coverage ?? '—',
          ),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
              label: 'Paid on', value: AppDate.formatDateTime(args.at)),
          if (args.receiptNumber != null) ...[
            Divider(height: 1, color: context.colors.border),
            AppDetailRow(
              label: 'Receipt number',
              value: args.receiptNumber!,
              emphasize: true,
            ),
          ],
        ],
      ),
    );
  }
}

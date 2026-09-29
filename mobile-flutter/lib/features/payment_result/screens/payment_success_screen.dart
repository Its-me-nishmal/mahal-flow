import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/l10n.dart';
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
    final l10n = context.l10n;
    return PopScope(
      // Back from a finished payment goes home, never to the pay form.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) AppNav.memberHome(context);
      },
      child: PaymentResultView(
        headline:
            _isDues ? l10n.payResultSuccessTitle : l10n.payResultThankYou,
        message: _isDues
            ? l10n.payResultDuesClearedMessage
            : l10n.payResultContributionReceivedMessage,
        amount: Inr.formatAny(args.amount),
        icon: Icons.check_rounded,
        color: context.colors.success,
        background: context.colors.successBg,
        statusLabel: l10n.statusPaid,
        primaryLabel: l10n.payResultViewReceipt,
        primaryIcon: Icons.receipt_long_rounded,
        onPrimary: () => _viewReceipt(context),
        secondaryLabel: l10n.payResultBackHome,
        onSecondary: () => AppNav.memberHome(context),
        details: [
          AppDetailRow(
            label: _isDues ? l10n.payResultCovers : l10n.payResultFund,
            value: args.coverage ?? '—',
          ),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
              label: l10n.payResultPaidOn,
              value: AppDate.formatDateTime(args.at)),
          if (args.receiptNumber != null) ...[
            Divider(height: 1, color: context.colors.border),
            AppDetailRow(
              label: l10n.payResultReceiptNumber,
              value: args.receiptNumber!,
              emphasize: true,
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_card.dart';
import '../payment_result_args.dart';
import '../widgets/payment_result_view.dart';

/// The gateway reported a failure, or the member cancelled checkout.
class PaymentFailedScreen extends StatelessWidget {
  final PaymentResultArgs args;

  const PaymentFailedScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final cancelled = args.cancelled;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) AppNav.memberHome(context);
      },
      child: PaymentResultView(
        headline: cancelled ? 'Payment cancelled' : 'Payment failed',
        // Say plainly what happened to the money — that is the first thing a
        // member wants to know. Only a cancel is certain to have moved none.
        message: cancelled
            ? 'You left the payment screen before paying. No money was taken.'
            : 'The payment did not go through. If your bank shows a debit, it '
                'is reversed automatically. You can try again.',
        amount: Inr.formatAny(args.amount),
        icon: cancelled
            ? Icons.remove_circle_outline_rounded
            : Icons.close_rounded,
        color: cancelled ? context.colors.textSecondary : context.colors.error,
        background: cancelled ? context.colors.neutralBg : context.colors.errorBg,
        statusLabel: cancelled ? 'Cancelled' : 'Failed',
        primaryLabel: 'Try Again',
        primaryIcon: Icons.refresh_rounded,
        onPrimary: () =>
            Navigator.of(context).pushReplacementNamed(args.retryRoute),
        secondaryLabel: 'Back to Home',
        onSecondary: () => AppNav.memberHome(context),
        details: [
          if (!cancelled) ...[
            AppDetailRow(
              label: 'Reason',
              value: args.reason ?? 'The payment could not be completed.',
            ),
            Divider(height: 1, color: context.colors.border),
          ],
          if (args.coverage != null) ...[
            AppDetailRow(
              label: args.kind == PaymentKind.dues ? 'For' : 'Fund',
              value: args.coverage!,
            ),
            Divider(height: 1, color: context.colors.border),
          ],
          AppDetailRow(
              label: 'Attempted', value: AppDate.formatDateTime(args.at)),
          if (cancelled) ...[
            Divider(height: 1, color: context.colors.border),
            const AppDetailRow(label: 'Amount debited', value: 'None'),
          ],
        ],
      ),
    );
  }
}

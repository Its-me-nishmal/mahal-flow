import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../l10n/l10n.dart';
import '../payment_result_args.dart';
import '../widgets/payment_result_view.dart';

/// The gateway reported a failure, or the member cancelled checkout.
class PaymentFailedScreen extends StatelessWidget {
  final PaymentResultArgs args;

  const PaymentFailedScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cancelled = args.cancelled;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) AppNav.memberHome(context);
      },
      child: PaymentResultView(
        headline: cancelled
            ? l10n.payResultCancelledTitle
            : l10n.payResultFailedTitle,
        // Say plainly what happened to the money — that is the first thing a
        // member wants to know. Only a cancel is certain to have moved none.
        message: cancelled
            ? l10n.payResultCancelledMessage
            : l10n.payResultFailedMessage,
        amount: Inr.formatAny(args.amount),
        icon: cancelled
            ? Icons.remove_circle_outline_rounded
            : Icons.close_rounded,
        color: cancelled ? context.colors.textSecondary : context.colors.error,
        background: cancelled ? context.colors.neutralBg : context.colors.errorBg,
        statusLabel: cancelled ? l10n.statusCancelled : l10n.statusFailed,
        primaryLabel: l10n.commonTryAgain,
        primaryIcon: Icons.refresh_rounded,
        onPrimary: () =>
            Navigator.of(context).pushReplacementNamed(args.retryRoute),
        secondaryLabel: l10n.payResultBackHome,
        onSecondary: () => AppNav.memberHome(context),
        details: [
          if (!cancelled) ...[
            AppDetailRow(
              label: l10n.payResultReason,
              value: args.reason ?? l10n.payuCouldNotComplete,
            ),
            Divider(height: 1, color: context.colors.border),
          ],
          if (args.coverage != null) ...[
            AppDetailRow(
              label: args.kind == PaymentKind.dues
                  ? l10n.payResultFor
                  : l10n.payResultFund,
              value: args.coverage!,
            ),
            Divider(height: 1, color: context.colors.border),
          ],
          AppDetailRow(
              label: l10n.payResultAttempted,
              value: AppDate.formatDateTime(args.at)),
          if (cancelled) ...[
            Divider(height: 1, color: context.colors.border),
            AppDetailRow(
              label: l10n.payResultAmountDebited,
              value: l10n.payResultNone,
            ),
          ],
        ],
      ),
    );
  }
}

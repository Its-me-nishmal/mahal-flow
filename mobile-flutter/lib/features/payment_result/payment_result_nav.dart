import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import 'payment_result_args.dart';

/// Moves from a payment form to its outcome. The form is replaced so Back
/// from the result never returns to a stale checkout.
class PaymentResultNav {
  PaymentResultNav._();

  static void success(BuildContext context, PaymentResultArgs args) =>
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.memberPaymentSuccess,
        arguments: args,
      );

  static void failed(BuildContext context, PaymentResultArgs args) =>
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.memberPaymentFailed,
        arguments: args,
      );

  static void pending(BuildContext context, PaymentResultArgs args) =>
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.memberPaymentPending,
        arguments: args,
      );
}

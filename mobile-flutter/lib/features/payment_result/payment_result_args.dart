import '../../core/navigation/app_routes.dart';
import '../../core/utils/dues_period.dart';

/// What was being paid. Decides the copy on the result screens and where
/// "Try Again" goes — dues and contributions are never mixed (AGENTS.md
/// invariant 3).
enum PaymentKind { dues, contribution }

/// Everything a payment result screen shows. Built by the payment flow from
/// the gateway callback and the server's confirmation — never from defaults,
/// so a result screen can only describe a payment that actually happened.
class PaymentResultArgs {
  final PaymentKind kind;

  /// Amount charged (success: from the server receipt) or attempted.
  final num? amount;

  /// "Jun–Aug 2026" for dues, the fund name for a contribution.
  final String? coverage;

  /// When the attempt started / the payment was confirmed.
  final DateTime at;

  /// Server transaction id (needed by the pending screen to poll).
  final String? transactionId;

  /// True when the PayU SDK reported success, so the pending screen may retry
  /// the server confirmation (with [gatewayPaymentId] when PayU sent one).
  final bool gatewayReportedSuccess;

  /// PayU `mihpayid` from the SDK success payload, if it carried one.
  final String? gatewayPaymentId;

  /// The receipt the server issued (success only).
  final Map<String, dynamic>? receipt;

  /// Why the payment failed, in words a member understands.
  final String? reason;

  /// True when the member backed out of the gateway (failed screen then says
  /// "cancelled", not "failed").
  final bool cancelled;

  const PaymentResultArgs({
    required this.kind,
    required this.at,
    this.amount,
    this.coverage,
    this.transactionId,
    this.gatewayReportedSuccess = false,
    this.gatewayPaymentId,
    this.receipt,
    this.reason,
    this.cancelled = false,
  });

  /// Success args from a server receipt. Amount and months come from the
  /// receipt — what the server actually recorded — not from the selection.
  factory PaymentResultArgs.fromReceipt({
    required PaymentKind kind,
    required Map<String, dynamic> receipt,
    num? fallbackAmount,
    String? fallbackCoverage,
    String? transactionId,
  }) {
    final paidMonths =
        (receipt['paid_months'] as List?)?.map((m) => m.toString()).toList() ??
            const <String>[];
    final monthsLabel = DuesPeriod.paidMonthsLabel(paidMonths);
    final amount = receipt['amount'];
    return PaymentResultArgs(
      kind: kind,
      at: DateTime.tryParse(receipt['created_at']?.toString() ?? '')
              ?.toLocal() ??
          DateTime.now(),
      amount: amount is num
          ? amount
          : num.tryParse('${amount ?? ''}') ?? fallbackAmount,
      coverage: monthsLabel.isNotEmpty ? monthsLabel : fallbackCoverage,
      transactionId: transactionId ?? receipt['transaction_id']?.toString(),
      receipt: receipt,
    );
  }

  String? get receiptNumber {
    final n = receipt?['receipt_number']?.toString();
    return (n == null || n.isEmpty) ? null : n;
  }

  /// The screen that starts this kind of payment again.
  String get retryRoute => kind == PaymentKind.dues
      ? AppRoutes.memberPay
      : AppRoutes.memberContribution;

  PaymentResultArgs copyWith({
    Map<String, dynamic>? receipt,
    num? amount,
    String? coverage,
    DateTime? at,
  }) =>
      PaymentResultArgs(
        kind: kind,
        at: at ?? this.at,
        amount: amount ?? this.amount,
        coverage: coverage ?? this.coverage,
        transactionId: transactionId,
        gatewayReportedSuccess: gatewayReportedSuccess,
        gatewayPaymentId: gatewayPaymentId,
        receipt: receipt ?? this.receipt,
        reason: reason,
        cancelled: cancelled,
      );
}

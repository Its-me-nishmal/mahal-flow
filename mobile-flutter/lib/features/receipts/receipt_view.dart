import '../../core/network/api_service.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/dues_period.dart';

/// One receipt as the member screens show it, built from the API's receipt
/// JSON (`domain.Receipt`). Missing fields render as "—"; nothing is filled
/// in with a sample value.
class ReceiptView {
  final String receiptNumber;
  final String memberName;
  final num? amount;
  final String paymentType;
  final List<String> paidMonths;
  final String status;
  final DateTime? createdAt;
  final String? gateway;
  final String? fund;

  const ReceiptView({
    required this.receiptNumber,
    required this.memberName,
    required this.amount,
    required this.paymentType,
    required this.paidMonths,
    required this.status,
    required this.createdAt,
    this.gateway,
    this.fund,
  });

  factory ReceiptView.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    final rawAmount = json['amount'];
    final cachedName = ApiService.cachedMemberName.trim();
    return ReceiptView(
      receiptNumber: str(json['receipt_number']) ?? '—',
      memberName: str(json['member_name']) ??
          (cachedName.isNotEmpty ? cachedName : '—'),
      amount: rawAmount is num ? rawAmount : num.tryParse('${rawAmount ?? ''}'),
      paymentType: str(json['payment_type']) ?? '',
      paidMonths:
          (json['paid_months'] as List?)?.map((m) => m.toString()).toList() ??
              const [],
      // A receipt is only issued once the server has committed the payment
      // (CommitSuccessfulPayment), so the API's receipt has no status field.
      // A status sent by the server (e.g. REFUNDED) always wins.
      status: (str(json['status']) ?? 'SUCCESS').toUpperCase(),
      createdAt: AppDate.tryParse(json['created_at']),
      gateway: str(json['gateway']) ??
          str(json['payment_method']) ??
          str(json['method']),
      fund: str(json['fund']) ?? str(json['fund_name']) ?? str(json['purpose']),
    );
  }

  bool get isDues => paymentType == 'MONTHLY_DUES';
  bool get isSuccess => status == 'SUCCESS' || status == 'PAID';

  String get title => isDues ? 'Monthly Dues' : 'Mahal Contribution';

  /// "Jun–Aug 2026" for dues, the fund for a contribution.
  String get subtitle {
    if (isDues) {
      final label = DuesPeriod.paidMonthsLabel(paidMonths);
      return label.isEmpty ? 'Monthly dues' : label;
    }
    return fund ?? 'Contribution';
  }

  String get amountLabel => Inr.formatAny(amount);
  String get dateLabel => AppDate.formatDate(createdAt);
  String get dateTimeLabel => AppDate.formatDateTime(createdAt);

  /// Human label for how it was paid.
  String get methodLabel {
    switch (gateway?.toUpperCase()) {
      case null:
        return '—';
      case 'PAYU':
        return 'Online (PayU)';
      case 'RAZORPAY':
        return 'Online (Razorpay)';
      case 'CASH':
        return 'Cash';
      case 'UPI':
        return 'UPI';
      case 'AUTOPAY':
        return 'AutoPay';
      default:
        return gateway!;
    }
  }

  /// Label for the status caption ("Paid", "Pending", "Refunded"…).
  String get statusLabel {
    switch (status) {
      case 'SUCCESS':
      case 'PAID':
        return 'Paid';
      case 'PENDING':
      case 'PROCESSING':
        return 'Pending';
      case 'FAILED':
        return 'Failed';
      case 'REFUNDED':
        return 'Refunded';
      default:
        return status.isEmpty
            ? '—'
            : status[0] + status.substring(1).toLowerCase();
    }
  }
}

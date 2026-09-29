import '../../core/network/api_service.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/currency_format.dart';
import '../../core/utils/dues_period.dart';
import '../../l10n/l10n.dart';

/// One receipt as the member screens show it, built from the API's receipt
/// JSON (`domain.Receipt`). Missing fields render as "—"; nothing is filled
/// in with a sample value. `status`, `gateway`, `payment_method`, `fund`,
/// `note` and `refunded_at` are absent on receipts issued before the server
/// stored them, so every one of them has a fallback.
class ReceiptView {
  final String receiptNumber;
  final String memberName;
  final num? amount;
  final String paymentType;
  final List<String> paidMonths;
  final String status;
  final DateTime? createdAt;
  final String? gateway;
  final String? paymentMethod;
  final String? fund;
  final String? note;
  final DateTime? refundedAt;

  const ReceiptView({
    required this.receiptNumber,
    required this.memberName,
    required this.amount,
    required this.paymentType,
    required this.paidMonths,
    required this.status,
    required this.createdAt,
    this.gateway,
    this.paymentMethod,
    this.fund,
    this.note,
    this.refundedAt,
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
      // SUCCESS | REFUNDED. Older receipts carry no status; a receipt is
      // only issued once the server has committed the payment, so those
      // default to SUCCESS.
      status: (str(json['status']) ?? 'SUCCESS').toUpperCase(),
      createdAt: AppDate.tryParse(json['created_at']),
      gateway: str(json['gateway'])?.toUpperCase(),
      paymentMethod:
          (str(json['payment_method']) ?? str(json['method']))?.toUpperCase(),
      fund: str(json['fund']) ?? str(json['fund_name']) ?? str(json['purpose']),
      note: str(json['note']),
      refundedAt: AppDate.tryParse(json['refunded_at']),
    );
  }

  bool get isDues => paymentType == 'MONTHLY_DUES';
  bool get isSuccess => status == 'SUCCESS' || status == 'PAID';
  bool get isRefunded => status == 'REFUNDED';
  String get refundedAtLabel => AppDate.formatDate(refundedAt);

  String get title => isDues
      ? L10n.current.receiptMonthlyDues
      : L10n.current.receiptMahalContribution;

  /// "Jun–Aug 2026" for dues, the fund for a contribution.
  String get subtitle {
    if (isDues) {
      final label = DuesPeriod.paidMonthsLabel(paidMonths);
      return label.isEmpty ? L10n.current.receiptMonthlyDuesLower : label;
    }
    return fund ?? L10n.current.receiptContribution;
  }

  String get amountLabel => Inr.formatAny(amount);
  String get dateLabel => AppDate.formatDate(createdAt);
  String get dateTimeLabel => AppDate.formatDateTime(createdAt);

  /// Human label for a PayU payment mode (UPI | CARD | NETBANKING | WALLET |
  /// CASH); unknown codes are shown as sent.
  static String methodName(String code) {
    final l = L10n.current;
    switch (code.toUpperCase()) {
      case 'UPI':
        return l.paymentMethodUpi;
      case 'CARD':
      case 'CC':
      case 'DC':
        return l.paymentMethodCard;
      case 'NETBANKING':
      case 'NB':
        return l.paymentMethodNetbanking;
      case 'WALLET':
        return l.paymentMethodWallet;
      case 'CASH':
        return l.receiptMethodCash;
      default:
        return code;
    }
  }

  /// Human label for how it was paid: gateway (PAYU | PAYU_SI | CASH) plus
  /// the PayU mode when the receipt records one.
  String get methodLabel {
    final l = L10n.current;
    final method = paymentMethod;
    final hasMethod = method != null && method.isNotEmpty && method != 'CASH';
    switch (gateway) {
      case 'CASH':
        return l.receiptMethodCash;
      case 'PAYU':
        return l.receiptMethodOnline(hasMethod ? methodName(method) : 'PayU');
      case 'PAYU_SI':
      case 'AUTOPAY':
        return hasMethod
            ? l.receiptMethodAutoPayVia(methodName(method))
            : l.receiptMethodAutoPay;
      case null:
        // Older receipts: the method alone, when there is one.
        return method == null ? '—' : methodName(method);
      default:
        return gateway!;
    }
  }

  /// Label for the status caption ("Paid", "Pending", "Refunded"…).
  String get statusLabel {
    switch (status) {
      case 'SUCCESS':
      case 'PAID':
        return L10n.current.statusPaid;
      case 'PENDING':
      case 'PROCESSING':
        return L10n.current.statusPending;
      case 'FAILED':
        return L10n.current.statusFailed;
      case 'REFUNDED':
        return L10n.current.receiptStatusRefunded;
      default:
        return status.isEmpty
            ? '—'
            : status[0] + status.substring(1).toLowerCase();
    }
  }
}

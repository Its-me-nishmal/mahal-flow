import 'package:intl/intl.dart';

/// Indian Rupee formatting. Uses en_IN so grouping is lakh-based
/// (1,50,000) which is what members expect on receipts.
class Inr {
  Inr._();

  static final NumberFormat _whole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _plain = NumberFormat.decimalPattern('en_IN');

  /// "₹1,500"
  static String format(num amount) => _whole.format(amount);

  /// Screen-reader form: "1,500 rupees". The ₹ glyph alone reads poorly.
  static String spoken(num amount) => '${_plain.format(amount)} rupees';
}

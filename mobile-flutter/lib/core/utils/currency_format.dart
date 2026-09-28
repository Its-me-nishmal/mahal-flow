import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';

/// Indian Rupee formatting. Uses en_IN so grouping is lakh-based
/// (1,50,000) which is what members expect on receipts.
class Inr {
  Inr._();

  static final NumberFormat _whole = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _withPaise = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _plainWhole = NumberFormat.decimalPattern('en_IN');

  static final NumberFormat _plainPaise = NumberFormat('#,##,##0.00', 'en_IN');

  static bool _hasPaise(num amount) => ((amount * 100).round() % 100) != 0;

  /// "₹1,500" for whole rupees, "₹1,500.50" when there are paise — never
  /// rounds paise away. Pass [alwaysShowPaise] for receipts/ledgers where
  /// every row should read "₹1,500.00".
  static String format(num amount, {bool alwaysShowPaise = false}) {
    if (alwaysShowPaise || _hasPaise(amount)) {
      return _withPaise.format(amount);
    }
    return _whole.format(amount);
  }

  /// Same as [format] for a nullable / JSON value; [fallback] when missing.
  static String formatAny(dynamic amount, {String fallback = '—'}) {
    final value = amount is num ? amount : num.tryParse('${amount ?? ''}');
    return value == null ? fallback : format(value);
  }

  /// Integer paise (the backend's MoneyPaise) → "₹1,500.50".
  static String fromPaise(int paise) => format(paise / 100);

  /// Screen-reader form: "1,500 rupees", "1,500 rupees 50 paise" (localized). The ₹
  /// glyph alone reads poorly.
  static String spoken(num amount) {
    if (!_hasPaise(amount)) {
      return L10n.current.inrSpokenRupees(_plainWhole.format(amount.round()));
    }
    final totalPaise = (amount * 100).round();
    final rupees = totalPaise ~/ 100;
    final paise = (totalPaise % 100).abs();
    return L10n.current
        .inrSpokenRupeesPaise(_plainWhole.format(rupees), paise);
  }

  /// "1,500.50" without the symbol (tables, CSV previews).
  static String plain(num amount) => _hasPaise(amount)
      ? _plainPaise.format(amount)
      : _plainWhole.format(amount);
}

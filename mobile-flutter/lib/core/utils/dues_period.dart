import 'package:intl/intl.dart';

/// Status of a single unpaid monthly obligation.
enum DueMonthStatus { overdue, dueNow, upcoming }

/// One unpaid month derived from `last_paid_month`.
class DueMonth {
  final DateTime date;
  final DueMonthStatus status;

  const DueMonth(this.date, this.status);

  /// "2026-08"
  String get key => DuesPeriod.monthKeyOf(date);

  /// "Aug"
  String get shortLabel => DateFormat('MMM').format(date);

  /// "August 2026"
  String get longLabel => DateFormat('MMMM y').format(date);
}

/// Derives unpaid monthly-dues periods from `last_paid_month`.
///
/// The API returns `last_paid_month` ("YYYY-MM") and `outstanding_balance`,
/// but not the list of pending months. The amount always comes from
/// `outstanding_balance`; this helper only labels the period.
class DuesPeriod {
  DuesPeriod._();

  /// Safety cap so a years-stale `last_paid_month` cannot render a huge list.
  static const int _maxMonths = 24;

  /// Parses "YYYY-MM". Returns null on missing or malformed input so callers
  /// can fall back to a neutral label instead of inventing a period.
  static DateTime? parseMonthKey(String? key) {
    if (key == null || key.isEmpty) return null;
    final parts = key.split('-');
    if (parts.length < 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) return null;
    return DateTime(year, month, 1);
  }

  static String monthKeyOf(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  /// Months strictly after [lastPaidMonth] up to and including the current
  /// month. Empty when the member is up to date or paid in advance.
  static List<DueMonth> unpaidMonths(String? lastPaidMonth, {DateTime? now}) {
    final anchor = parseMonthKey(lastPaidMonth);
    if (anchor == null) return const [];

    final today = now ?? DateTime.now();
    final thisMonth = DateTime(today.year, today.month, 1);

    final months = <DueMonth>[];
    var cursor = DateTime(anchor.year, anchor.month + 1, 1);
    while (!cursor.isAfter(thisMonth) && months.length < _maxMonths) {
      months.add(DueMonth(cursor, _statusOf(cursor, thisMonth)));
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return months;
  }

  static DueMonthStatus _statusOf(DateTime month, DateTime thisMonth) {
    if (month.isBefore(thisMonth)) return DueMonthStatus.overdue;
    if (month.isAtSameMomentAs(thisMonth)) return DueMonthStatus.dueNow;
    return DueMonthStatus.upcoming;
  }

  /// Period summary for the balance card.
  /// 0 months  -> null (caller renders the up-to-date variant)
  /// 1 month   -> "1 pending month"
  /// n months  -> "3 pending months"
  static String? pendingSummary(String? lastPaidMonth, {DateTime? now}) {
    final count = unpaidMonths(lastPaidMonth, now: now).length;
    if (count == 0) return null;
    return count == 1 ? '1 pending month' : '$count pending months';
  }

  /// Label for months credited on a receipt: "August 2026" or "Jun–Aug 2026".
  static String paidMonthsLabel(List<String> monthKeys) {
    final dates = monthKeys
        .map(parseMonthKey)
        .whereType<DateTime>()
        .toList()
      ..sort();
    if (dates.isEmpty) return '';
    if (dates.length == 1) return DateFormat('MMMM y').format(dates.first);

    final first = dates.first;
    final last = dates.last;
    final start = DateFormat('MMM').format(first);
    final end = DateFormat('MMM').format(last);
    if (first.year == last.year) return '$start–$end ${last.year}';
    return '$start ${first.year}–$end ${last.year}';
  }
}

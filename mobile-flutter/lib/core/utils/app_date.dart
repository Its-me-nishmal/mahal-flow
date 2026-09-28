import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';

/// Date formatting used everywhere a date is shown. Every method accepts the
/// raw JSON value (ISO-8601 string, epoch int, DateTime or null), so screens
/// never call `DateTime.parse` themselves and never crash on a bad value.
///
/// * [formatDate]      → "5 Aug 2026"
/// * [formatDateTime]  → "5 Aug 2026 · 10:24 AM"
/// * [formatTime]      → "10:24 AM"
/// * [relative]        → "Just now" / "5 min ago" / "3 h ago" / "Yesterday" /
///                       "3 days ago" / "5 Aug 2026" (7 days or older, or future)
class AppDate {
  AppDate._();

  // Formatters follow the app language (Malayalam month names in ml), and
  // are rebuilt only when that language changes.
  static String? _cachedLocale;
  static late DateFormat _dateF, _timeF, _monthYearF;

  static void _sync() {
    final locale = L10n.localeName;
    if (locale == _cachedLocale) return;
    _dateF = DateFormat('d MMM y', locale);
    _timeF = DateFormat('h:mm a', locale);
    _monthYearF = DateFormat('MMM y', locale);
    _cachedLocale = locale;
  }

  static DateFormat get _date {
    _sync();
    return _dateF;
  }

  static DateFormat get _time {
    _sync();
    return _timeF;
  }

  static DateFormat get _monthYear {
    _sync();
    return _monthYearF;
  }

  /// Parses [value] to a local DateTime, or null. Accepts ISO-8601 strings
  /// (any fractional-second precision, with or without zone), epoch
  /// milliseconds or seconds (int or numeric string), and DateTime. Go's zero
  /// time ("0001-01-01T00:00:00Z") is treated as "no date".
  static DateTime? tryParse(dynamic value) {
    if (value == null) return null;
    DateTime? parsed;
    if (value is DateTime) {
      parsed = value;
    } else if (value is num) {
      parsed = _fromEpoch(value.toInt());
    } else {
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      final asInt = int.tryParse(text);
      parsed = asInt != null ? _fromEpoch(asInt) : DateTime.tryParse(text);
    }
    if (parsed == null || parsed.year <= 1) return null;
    return parsed.toLocal();
  }

  static DateTime _fromEpoch(int v) {
    // Heuristic: values below ~1e11 are seconds (covers dates up to 5138).
    return v.abs() < 100000000000
        ? DateTime.fromMillisecondsSinceEpoch(v * 1000)
        : DateTime.fromMillisecondsSinceEpoch(v);
  }

  /// "5 Aug 2026", or [fallback] when [value] is missing/unparseable.
  static String formatDate(dynamic value, {String fallback = '—'}) {
    final d = tryParse(value);
    return d == null ? fallback : _date.format(d);
  }

  /// "5 Aug 2026 · 10:24 AM".
  static String formatDateTime(dynamic value, {String fallback = '—'}) {
    final d = tryParse(value);
    return d == null ? fallback : '${_date.format(d)} · ${_time.format(d)}';
  }

  /// "10:24 AM".
  static String formatTime(dynamic value, {String fallback = '—'}) {
    final d = tryParse(value);
    return d == null ? fallback : _time.format(d);
  }

  /// "Aug 2026".
  static String formatMonthYear(dynamic value, {String fallback = '—'}) {
    final d = tryParse(value);
    return d == null ? fallback : _monthYear.format(d);
  }

  /// Human relative time for feeds (notices, activity, audit logs).
  /// [now] is injectable for tests.
  static String relative(
    dynamic value, {
    String fallback = '—',
    DateTime? now,
  }) {
    final d = tryParse(value);
    if (d == null) return fallback;
    final current = now ?? DateTime.now();
    final diff = current.difference(d);
    final l10n = L10n.current;

    // Future timestamps (clock skew, scheduled items) read best as a date.
    if (diff.isNegative) {
      return diff.inMinutes.abs() < 1 ? l10n.dateJustNow : _date.format(d);
    }
    if (diff.inMinutes < 1) return l10n.dateJustNow;
    if (diff.inMinutes < 60) return l10n.dateMinutesAgo(diff.inMinutes);

    final today = DateTime(current.year, current.month, current.day);
    final day = DateTime(d.year, d.month, d.day);
    final calendarDays = today.difference(day).inDays;

    if (calendarDays == 0) return l10n.dateHoursAgo(diff.inHours);
    if (calendarDays == 1) return l10n.dateYesterday;
    if (calendarDays < 7) return l10n.dateDaysAgo(calendarDays);
    return _date.format(d);
  }

  /// True when [a] and [b] fall on the same local calendar day.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

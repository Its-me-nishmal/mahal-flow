import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/dues_period.dart';
import '../../../l10n/l10n.dart';

/// Text colours for copy that sits on the brand gradient header. Kept in one
/// place so admin screens don't sprinkle `Colors.white.withValues(...)`.
class AdminHeroColors {
  AdminHeroColors._();

  static const Color text = Colors.white;
  static final Color muted = Colors.white.withValues(alpha: 0.78);
  static final Color faint = Colors.white.withValues(alpha: 0.62);
  static final Color fill = Colors.white.withValues(alpha: 0.16);
}

/// A member status mapped onto the semantic palette, with its text label.
class MemberStatusStyle {
  final String label;
  final AppTone tone;

  /// Filter bucket (internal English key, never shown):
  /// Active | Grace Period | Suspended | Pending | Other.
  final String bucket;

  const MemberStatusStyle(this.label, this.tone, this.bucket);

  Color foreground(BuildContext context) => context.colors.fg(tone);
  Color background(BuildContext context) => context.colors.bg(tone);
}

/// Formatting helpers shared by the committee screens.
class AdminFormat {
  AdminFormat._();

  /// "PAST_DUE" → "Past due", "GRACE_PERIOD" → "Grace period".
  static String humanize(String? raw, {String fallback = '—'}) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return fallback;
    final words = s.replaceAll(RegExp(r'[_\-]+'), ' ').toLowerCase();
    return words[0].toUpperCase() + words.substring(1);
  }

  static MemberStatusStyle memberStatus(String? raw) {
    final s = (raw ?? '').trim().toUpperCase();
    final l = L10n.current;
    switch (s) {
      case 'ACTIVE':
      case '':
        return MemberStatusStyle(
            l.adminFormatStatusActive, AppTone.success, 'Active');
      case 'GRACE_PERIOD':
      case 'OVERDUE':
        return MemberStatusStyle(
            l.adminFormatStatusGrace, AppTone.warning, 'Grace Period');
      case 'PENDING':
      case 'PENDING_APPROVAL':
        return MemberStatusStyle(
            l.adminFormatStatusAwaiting, AppTone.info, 'Pending');
      case 'SUSPENDED':
        return MemberStatusStyle(
            l.adminFormatStatusSuspended, AppTone.error, 'Suspended');
      case 'INACTIVE':
        return MemberStatusStyle(
            l.adminFormatStatusInactive, AppTone.error, 'Suspended');
      case 'REJECTED':
        return MemberStatusStyle(
            l.adminFormatStatusRejected, AppTone.error, 'Suspended');
      default:
        return MemberStatusStyle(
            humanize(s), AppTone.neutral, 'Other');
    }
  }

  static bool isSuspended(String? raw) {
    final s = (raw ?? '').trim().toUpperCase();
    return s == 'SUSPENDED' || s == 'INACTIVE';
  }

  /// The member's monthly dues from the server record, or null when unset.
  static double? monthlyDues(Map<String, dynamic> member) {
    final v = member['monthly_dues_custom_amount'] ?? member['monthly_dues'];
    final d = v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
    return (d == null || d <= 0) ? null : d;
  }

  static double? outstanding(Map<String, dynamic> member) {
    final v = member['outstanding_balance'];
    return v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
  }

  static String memberId(Map<String, dynamic> member) =>
      (member['id'] ?? member['_id'] ?? '').toString().trim();

  /// The next [count] dues months a payment must cover, starting right after
  /// `last_paid_month` (the server rejects anything else). Empty when the
  /// member has no `last_paid_month` on record.
  static List<String> nextDueMonths(Map<String, dynamic> member, int count) {
    final anchor =
        DuesPeriod.parseMonthKey(member['last_paid_month']?.toString());
    if (anchor == null || count <= 0) return const [];
    return [
      for (var i = 1; i <= count; i++)
        DuesPeriod.monthKeyOf(DateTime(anchor.year, anchor.month + i, 1)),
    ];
  }

  /// "1 month" / "3 months".
  static String months(int n) => L10n.current.adminFormatMonths(n);

  /// MONTHLY_DUES → "Monthly dues", CONTRIBUTION → "Contribution".
  static String paymentType(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'MONTHLY_DUES':
        return L10n.current.adminFormatMonthlyDues;
      case 'CONTRIBUTION':
      case 'DONATION':
        return L10n.current.adminFormatContribution;
      default:
        return humanize(raw, fallback: L10n.current.adminFormatPayment);
    }
  }

  /// "abcdef0123456789…" → "abcdef01…6789"; empty → "Unavailable".
  static String shortHash(String? hash) {
    final h = (hash ?? '').trim();
    if (h.isEmpty) return L10n.current.commonUnavailable;
    if (h.length <= 16) return h;
    return '${h.substring(0, 8)}…${h.substring(h.length - 6)}';
  }
}

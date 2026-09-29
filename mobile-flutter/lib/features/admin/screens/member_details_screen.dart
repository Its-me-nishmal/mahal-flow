import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/dues_period.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../l10n/l10n.dart';
import '../data/admin_context.dart';
import '../utils/admin_format.dart';
import '../widgets/receipt_sheet.dart';
import '../widgets/record_payment_sheet.dart';

/// One row of the dues history.
class _DuesMonth {
  final DateTime month;
  final String status; // Paid | Due | Overdue
  final String? receiptNumber;
  const _DuesMonth(this.month, this.status, this.receiptNumber);
}

class MemberDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const MemberDetailsScreen({super.key, required this.member});

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen> {
  static const int _historyMonths = 6;

  final ApiService _api = ApiService();
  late Map<String, dynamic> _member = Map<String, dynamic>.from(widget.member);

  List<Map<String, dynamic>> _receipts = const [];
  bool _loading = true;
  ApiException? _error;

  String get _id => AdminFormat.memberId(_member);

  @override
  void initState() {
    super.initState();
    if (_id.isNotEmpty) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait([
        _api.getMemberReceiptsOrThrow(memberId: _id),
        // Fresh record (last_paid_month / balance move after a payment).
        _api
            .getAdminMemberOrThrow(_id)
            .then<Map<String, dynamic>?>((m) => m, onError: (Object _) => null),
      ]);
      if (!mounted) return;
      final receipts = (results[0] as List)
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList();
      final fresh = results[1] as Map<String, dynamic>?;
      setState(() {
        _receipts = receipts;
        if (fresh != null) _member = {..._member, ...fresh};
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Derived
  // -------------------------------------------------------------------------

  /// Month the member joined (created_at), if known.
  DateTime? get _joinMonth {
    final d = AppDate.tryParse(_member['created_at'] ?? _member['joined_at']);
    return d == null ? null : DateTime(d.year, d.month, 1);
  }

  List<_DuesMonth> get _history {
    final paidByMonth = <String, String>{};
    for (final r in _receipts) {
      final months = r['paid_months'] ?? r['selected_months'];
      final number = r['receipt_number']?.toString();
      if (months is List && number != null) {
        for (final m in months) {
          paidByMonth[m.toString()] = number;
        }
      }
    }
    final lastPaid =
        DuesPeriod.parseMonthKey(_member['last_paid_month']?.toString());

    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final join = _joinMonth;
    final rows = <_DuesMonth>[];
    for (var i = 0; i < _historyMonths; i++) {
      final month = DateTime(thisMonth.year, thisMonth.month - i, 1);
      // Nothing was owed before the member joined.
      if (join != null && month.isBefore(join)) break;
      final key = DuesPeriod.monthKeyOf(month);
      final receipt = paidByMonth[key];
      final paid =
          receipt != null || (lastPaid != null && !month.isAfter(lastPaid));
      rows.add(_DuesMonth(
        month,
        paid
            ? 'Paid'
            : month.isAtSameMomentAs(thisMonth)
                ? 'Due'
                : 'Overdue',
        receipt,
      ));
    }
    return rows;
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  Future<void> _openEdit() async {
    final result = await Navigator.of(context)
        .pushNamed(AppRoutes.adminEditMember, arguments: _member);
    if (!mounted || result is! Map) return;
    setState(
        () => _member = {..._member, ...Map<String, dynamic>.from(result)});
    AdminContext.invalidateMembers();
  }

  Future<void> _recordPayment() async {
    final res = await RecordPaymentSheet.show(context, member: _member);
    if (res == null || !mounted) return;
    final receipt = Map<String, dynamic>.from(res['receipt'] as Map);
    final number = receipt['receipt_number']?.toString() ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            context.l10n.memberDetailsRecorded(
                Inr.formatAny(receipt['amount'] ?? res['amount']))),
        backgroundColor: context.colors.primary,
        action: number.isEmpty
            ? null
            : SnackBarAction(
                label: context.l10n.adminReceiptAction,
                textColor: context.colors.onPrimary,
                onPressed: () => ReceiptSheet.show(context, number),
              ),
      ),
    );
    _load();
  }

  /// A dues reminder, sent either in the app (POST /admin/alerts with
  /// audience MEMBER, so only this member sees it and gets the push) or
  /// through the admin's own WhatsApp / SMS app with the text prefilled.
  Future<void> _sendReminder() async {
    final phone =
        PhoneFormat.nationalDigits(_member['phone']?.toString() ?? '');
    final hasPhone = phone.length == 10;
    final canNotify = _id.isNotEmpty;
    if (!hasPhone && !canNotify) {
      _snack(context.l10n.memberDetailsNoValidPhone);
      return;
    }
    final l10n = context.l10n;
    final name =
        _member['name']?.toString() ?? l10n.memberDetailsReminderNameFallback;
    final outstanding = AdminFormat.outstanding(_member) ?? 0;
    final mahal =
        AdminContext.mahalName ?? l10n.memberDetailsReminderMahalFallback;
    // SMS / WhatsApp text avoids "₹", which some SMS encodings mangle.
    final text = outstanding > 0
        ? l10n.memberDetailsReminderWithAmount(
            name, mahal, Inr.format(outstanding).replaceAll('₹', 'Rs. '))
        : l10n.memberDetailsReminderNoAmount(name, mahal);
    final noticeText = outstanding > 0
        ? l10n.memberDetailsReminderWithAmount(
            name, mahal, Inr.format(outstanding))
        : text;

    final channel = await AppBottomSheet.show<String>(
      context: context,
      title: l10n.memberDetailsReminderTitle,
      subtitle: l10n.memberDetailsReminderChooseSubtitle,
      icon: Icons.sms_outlined,
      builder: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            color: context.colors.background,
            child: Text(text, style: context.text.body),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasPhone
                ? l10n.memberDetailsReminderTo(PhoneFormat.display(phone))
                : l10n.memberDetailsNoValidPhone,
            style: context.text.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (canNotify) ...[
            AppPrimaryButton(
              label: l10n.memberDetailsSendInAppNotice,
              icon: Icons.notifications_active_outlined,
              onPressed: () => Navigator.of(ctx).pop('app'),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.memberDetailsInAppNoticeHint,
                style: context.text.caption),
            if (hasPhone) const SizedBox(height: AppSpacing.sm),
          ],
          if (hasPhone) ...[
            AppSecondaryButton(
              label: l10n.memberDetailsOpenWhatsApp,
              icon: Icons.chat_outlined,
              onPressed: () => Navigator.of(ctx).pop('whatsapp'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: l10n.memberDetailsOpenSms,
              icon: Icons.sms_outlined,
              onPressed: () => Navigator.of(ctx).pop('sms'),
            ),
          ],
        ],
      ),
    );
    if (channel == null || !mounted) return;

    if (channel == 'app') {
      await _sendInAppNotice(noticeText, overdue: outstanding > 0);
      return;
    }

    final uri = channel == 'whatsapp'
        ? Uri.parse('https://wa.me/91$phone?text=${Uri.encodeComponent(text)}')
        : Uri(
            scheme: 'sms',
            path: '+91$phone',
            query: 'body=${Uri.encodeComponent(text)}',
          );
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!mounted || opened) return;
    _snack(channel == 'whatsapp'
        ? context.l10n.memberDetailsWhatsAppFailed
        : context.l10n.memberDetailsSmsFailed);
  }

  bool _sendingNotice = false;

  /// POST /admin/alerts {audience: MEMBER, member_ids: [id], type:
  /// DUES_REMINDER} — visible and pushed to this member only.
  Future<void> _sendInAppNotice(String message, {required bool overdue}) async {
    if (_sendingNotice) return;
    _sendingNotice = true;
    final l10n = context.l10n;
    try {
      await _api.createAlertOrThrow(
        title: l10n.memberDetailsNoticeTitle,
        description: message,
        severity: overdue ? 'WARNING' : 'INFO',
        audience: 'MEMBER',
        memberIds: [_id],
        type: 'DUES_REMINDER',
      );
      if (!mounted) return;
      _snack(context.l10n.memberDetailsNoticeSent);
    } on ApiException catch (e) {
      if (!mounted) return;
      _snack(context.l10n.memberDetailsNoticeFailed(e.userMessage));
    } finally {
      _sendingNotice = false;
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = _member['name']?.toString() ?? l10n.commonMember;
    final rawPhone = _member['phone']?.toString() ?? '';
    final code = _member['member_code']?.toString() ?? '';
    final missingId = _id.isEmpty;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_member);
      },
      child: AppPageScaffold(
        title: name,
        eyebrow: l10n.commonMember,
        onRefresh: missingId ? null : _load,
        actions: [
          if (!missingId) ...[
            AppHeaderIconButton(
              icon: Icons.sms_outlined,
              tooltip: l10n.memberDetailsSendReminderTooltip,
              onTap: _sendReminder,
            ),
            AppHeaderIconButton(
              icon: Icons.edit_outlined,
              tooltip: l10n.adminEditMember,
              onTap: _openEdit,
            ),
          ],
        ],
        headerChild: Row(
          children: [
            AppAvatar(name: name, size: 56, onHero: true),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rawPhone.isEmpty
                        ? l10n.memberDetailsNoPhone
                        : PhoneFormat.display(rawPhone),
                    style: context.text.body
                        .copyWith(color: AdminHeroColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    code.isNotEmpty
                        ? l10n.memberDetailsMemberCode(code)
                        : l10n.memberDetailsIdLabel(_id.isEmpty ? '—' : _id),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.small
                        .copyWith(color: AdminHeroColors.faint),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingChild: missingId ? null : _summaryCard(),
        content: [
          const SizedBox(height: AppSpacing.md),
          if (missingId)
            AppCard(
              child: AppErrorStateView(
                title: l10n.memberDetailsIncompleteTitle,
                description: l10n.memberDetailsIncompleteBody,
                actionLabel: l10n.memberDetailsBackToMembers,
                icon: Icons.person_off_outlined,
                onRetry: () => Navigator.of(context).maybePop(),
              ),
            )
          else ...[
            AppSectionHeader(
              title: _joinMonth != null && _history.length < _historyMonths
                  ? l10n.memberDetailsSinceJoining
                  : l10n.memberDetailsLastSixMonths,
            ),
            _duesHistoryCard(),
          ],
        ],
        bottomBar: missingId
            ? null
            : AppBottomActionBar(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          label: l10n.adminEditMember,
                          icon: Icons.edit_outlined,
                          height: AppSizes.minTouch,
                          onPressed: _openEdit,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.ms),
                      Expanded(
                        child: AppPrimaryButton(
                          label: l10n.adminRecordPayment,
                          height: AppSizes.minTouch,
                          onPressed: AdminFormat.isSuspended(
                                  _member['status']?.toString())
                              ? null
                              : _recordPayment,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _summaryCard() {
    final l10n = context.l10n;
    final status = AdminFormat.memberStatus(_member['status']?.toString());
    final dues = AdminFormat.monthlyDues(_member);
    final outstanding = AdminFormat.outstanding(_member);
    final house = _member['house_name']?.toString() ?? '';
    final lastPaid =
        DuesPeriod.parseMonthKey(_member['last_paid_month']?.toString());
    final history =
        _loading || _error != null ? const <_DuesMonth>[] : _history;
    final unpaid = history.where((h) => h.status != 'Paid').length;

    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.memberDetailsMonthlyDuesCaps,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.label,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 160),
                child: StatusPill(
                  label: status.label,
                  foreground: status.foreground(context),
                  background: status.background(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          Text(
            dues == null ? '—' : Inr.format(dues),
            style: context.text.amount.copyWith(color: context.colors.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _loading
                ? l10n.memberDetailsLoadingHistory
                : _error != null
                    ? l10n.memberDetailsHistoryUnavailable
                    : history.isEmpty
                        ? l10n.memberDetailsNoDuesMonths
                        : unpaid == 0
                            ? l10n.memberDetailsAllPaid
                            : l10n.memberDetailsUnpaidCount(
                                unpaid, history.length),
            style: context.text.body.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
            label: l10n.memberDetailsOutstanding,
            value: outstanding == null ? '—' : Inr.format(outstanding),
          ),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
            label: l10n.memberDetailsPaidUpTo,
            value: lastPaid == null ? '—' : AppDate.formatMonthYear(lastPaid),
          ),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
            label: l10n.memberDetailsHouse,
            value: house.isEmpty ? l10n.memberDetailsNotRecorded : house,
          ),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
            label: l10n.memberDetailsMemberSince,
            value: AppDate.formatMonthYear(_member['created_at']),
          ),
        ],
      ),
    );
  }

  Widget _duesHistoryCard() {
    if (_loading) {
      return ShimmerLoading(
        semanticsLabel: context.l10n.memberDetailsLoadingDues,
        child: const ShimmerCardSkeleton(height: 260),
      );
    }
    if (_error != null) {
      return AppCard(
        child: AppErrorStateView(
          title: context.l10n.memberDetailsDuesError,
          description: _error!.userMessage,
          onRetry: () {
            setState(() => _loading = true);
            _load();
          },
        ),
      );
    }
    final history = _history;
    if (history.isEmpty) {
      return AppCard(
        child: EmptyStateView(
          icon: Icons.event_available_outlined,
          title: context.l10n.memberDetailsNoDuesTitle,
          description: context.l10n.memberDetailsNoDuesBody,
        ),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < history.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.colors.border),
            _duesRow(history[i]),
          ],
        ],
      ),
    );
  }

  Widget _duesRow(_DuesMonth m) {
    late final Color fg;
    late final Color bg;
    late final IconData icon;
    switch (m.status) {
      case 'Paid':
        fg = context.colors.success;
        bg = context.colors.successBg;
        icon = Icons.check_circle_rounded;
      case 'Overdue':
        fg = context.colors.error;
        bg = context.colors.errorBg;
        icon = Icons.error_outline_rounded;
      default:
        fg = context.colors.warning;
        bg = context.colors.warningBg;
        icon = Icons.schedule_rounded;
    }
    final receipt = m.receiptNumber;
    final statusLabel = switch (m.status) {
      'Paid' => context.l10n.memberDetailsPaid,
      'Overdue' => context.l10n.memberDetailsOverdue,
      _ => context.l10n.memberDetailsDue,
    };

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.ms,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppDate.formatMonthYear(m.month),
                  style:
                      context.text.body.copyWith(fontWeight: FontWeight.w500),
                ),
                if (receipt != null)
                  Text(context.l10n.memberDetailsReceiptNumber(receipt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: StatusPill(
                label: statusLabel, foreground: fg, background: bg, icon: icon),
          ),
          if (receipt != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: context.colors.textMuted),
          ],
        ],
      ),
    );

    if (receipt == null) return row;
    return Semantics(
      button: true,
      hint: context.l10n.memberDetailsOpenReceipt,
      child: InkWell(
        onTap: () => ReceiptSheet.show(context, receipt),
        child: row,
      ),
    );
  }
}

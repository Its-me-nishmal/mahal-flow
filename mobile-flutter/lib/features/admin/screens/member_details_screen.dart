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
            '${Inr.formatAny(receipt['amount'] ?? res['amount'])} recorded'),
        backgroundColor: context.colors.primary,
        action: number.isEmpty
            ? null
            : SnackBarAction(
                label: 'Receipt',
                textColor: context.colors.onPrimary,
                onPressed: () => ReceiptSheet.show(context, number),
              ),
      ),
    );
    _load();
  }

  /// There is no per-member notice endpoint (POST /admin/alerts only targets
  /// ALL / OVERDUE_ONLY / FAMILY_HEADS), so a personal reminder goes out
  /// through the admin's own WhatsApp or SMS app with the text prefilled.
  Future<void> _sendReminder() async {
    final phone =
        PhoneFormat.nationalDigits(_member['phone']?.toString() ?? '');
    if (phone.length != 10) {
      _snack('This member has no valid mobile number on record.');
      return;
    }
    final name = _member['name']?.toString() ?? 'member';
    final outstanding = AdminFormat.outstanding(_member) ?? 0;
    final mahal = AdminContext.mahalName ?? 'the Mahal committee';
    final amountLine = outstanding > 0
        ? ' Pending amount: ${Inr.format(outstanding).replaceAll('₹', 'Rs. ')}.'
        : '';
    final text = 'Assalamu alaikum $name, this is a reminder from $mahal that '
        'your monthly dues are pending.$amountLine You can pay in the '
        'MahalFlow app. Thank you.';

    final channel = await AppBottomSheet.show<String>(
      context: context,
      title: 'Send a dues reminder',
      subtitle: 'Opens your messaging app with the text filled in',
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
            'To ${PhoneFormat.display(phone)}. Nothing is sent until you press '
            'send in the other app.',
            style: context.text.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'Open WhatsApp',
            icon: Icons.chat_outlined,
            onPressed: () => Navigator.of(ctx).pop('whatsapp'),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: 'Open SMS',
            icon: Icons.sms_outlined,
            onPressed: () => Navigator.of(ctx).pop('sms'),
          ),
        ],
      ),
    );
    if (channel == null || !mounted) return;

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
        ? "Couldn't open WhatsApp on this phone."
        : "Couldn't open the SMS app on this phone.");
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final name = _member['name']?.toString() ?? 'Member';
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
        eyebrow: 'Member',
        onRefresh: missingId ? null : _load,
        actions: [
          if (!missingId) ...[
            AppHeaderIconButton(
              icon: Icons.sms_outlined,
              tooltip: 'Send dues reminder',
              onTap: _sendReminder,
            ),
            AppHeaderIconButton(
              icon: Icons.edit_outlined,
              tooltip: 'Edit member',
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
                        ? 'No phone on record'
                        : PhoneFormat.display(rawPhone),
                    style: context.text.body
                        .copyWith(color: AdminHeroColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    code.isNotEmpty
                        ? 'Member code $code'
                        : 'ID ${_id.isEmpty ? '—' : _id}',
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
                title: 'This member record is incomplete',
                description: 'It has no member ID, so its history cannot be '
                    'loaded and no payment can be recorded. Go back and open '
                    'the member again from the directory.',
                actionLabel: 'Back to members',
                icon: Icons.person_off_outlined,
                onRetry: () => Navigator.of(context).maybePop(),
              ),
            )
          else ...[
            AppSectionHeader(
              title: _joinMonth != null && _history.length < _historyMonths
                  ? 'Since joining'
                  : 'Last six months',
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
                          label: 'Edit member',
                          icon: Icons.edit_outlined,
                          height: AppSizes.minTouch,
                          onPressed: _openEdit,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.ms),
                      Expanded(
                        child: AppPrimaryButton(
                          label: 'Record payment',
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
              Expanded(child: Text('MONTHLY DUES', style: context.text.label)),
              StatusPill(
                label: status.label,
                foreground: status.foreground(context),
                background: status.background(context),
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
                ? 'Loading payment history…'
                : _error != null
                    ? 'Payment history unavailable.'
                    : history.isEmpty
                        ? 'No dues months yet.'
                        : unpaid == 0
                            ? 'Paid every month shown below.'
                            : '$unpaid of ${history.length} recent months unpaid.',
            style: context.text.body.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
            label: 'Outstanding',
            value: outstanding == null ? '—' : Inr.format(outstanding),
          ),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
            label: 'Paid up to',
            value: lastPaid == null ? '—' : AppDate.formatMonthYear(lastPaid),
          ),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
            label: 'House',
            value: house.isEmpty ? 'Not recorded' : house,
          ),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
            label: 'Member since',
            value: AppDate.formatMonthYear(_member['created_at']),
          ),
        ],
      ),
    );
  }

  Widget _duesHistoryCard() {
    if (_loading) {
      return const ShimmerLoading(
        semanticsLabel: 'Loading dues history',
        child: ShimmerCardSkeleton(height: 260),
      );
    }
    if (_error != null) {
      return AppCard(
        child: AppErrorStateView(
          title: "Couldn't load dues history",
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
      return const AppCard(
        child: EmptyStateView(
          icon: Icons.event_available_outlined,
          title: 'No dues yet',
          description: 'Dues start from the month the member joined.',
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
                  Text('Receipt $receipt',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusPill(
              label: m.status, foreground: fg, background: bg, icon: icon),
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
      hint: 'Open receipt',
      child: InkWell(
        onTap: () => ReceiptSheet.show(context, receipt),
        child: row,
      ),
    );
  }
}

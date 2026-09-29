import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/dues_period.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../l10n/l10n.dart';
import '../data/admin_context.dart';
import '../utils/admin_format.dart';

/// Result of a successful cash recording: the server's response, which
/// always carries a `receipt` map.
typedef RecordPaymentResult = Map<String, dynamic>;

/// "Record a payment" sheet for dues collected in cash. Pass [member] to skip
/// the member picker. Resolves to the server response (with `receipt`) only
/// when the server committed the payment; null when dismissed.
class RecordPaymentSheet {
  RecordPaymentSheet._();

  static Future<RecordPaymentResult?> show(
    BuildContext context, {
    Map<String, dynamic>? member,
  }) {
    return AppBottomSheet.show<RecordPaymentResult>(
      context: context,
      title: context.l10n.recordPayTitle,
      subtitle: context.l10n.recordPaySubtitle,
      icon: Icons.receipt_long_rounded,
      builder: (ctx, _) => _RecordPaymentBody(initialMember: member),
    );
  }
}

class _RecordPaymentBody extends StatefulWidget {
  final Map<String, dynamic>? initialMember;
  const _RecordPaymentBody({this.initialMember});

  @override
  State<_RecordPaymentBody> createState() => _RecordPaymentBodyState();
}

class _RecordPaymentBodyState extends State<_RecordPaymentBody> {
  static const List<int> _monthOptions = [1, 2, 3, 6];

  final ApiService _api = ApiService();
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  // Picker
  List<Map<String, dynamic>>? _members;
  ApiException? _membersError;
  bool _loadingMembers = false;

  // Selection
  Map<String, dynamic>? _member;
  int _months = 1;
  bool _saving = false;
  String? _submitError;

  /// One key per sheet + member + months, so retrying after a timeout cannot
  /// record the same cash twice, while a different selection gets a new key.
  final int _openedAt = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _member = widget.initialMember;
    if (_member == null) _loadMembers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _loadingMembers = true;
      _membersError = null;
    });
    try {
      final list = await AdminContext.allMembers();
      if (!mounted) return;
      setState(() {
        _members = list;
        _loadingMembers = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _membersError = e;
        _loadingMembers = false;
      });
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim().toLowerCase());
    });
  }

  List<Map<String, dynamic>> get _matches {
    final list = _members ?? const [];
    final q = _query;
    final filtered = q.isEmpty
        ? list
        : list.where((m) {
            final hay = [
              m['name'],
              m['phone'],
              m['house_name'],
              m['member_code'],
            ].map((v) => (v ?? '').toString().toLowerCase()).join(' ');
            return hay.contains(q);
          }).toList();
    return filtered.take(30).toList();
  }

  List<String> get _selectedMonths =>
      _member == null ? const [] : AdminFormat.nextDueMonths(_member!, _months);

  double? get _dues =>
      _member == null ? null : AdminFormat.monthlyDues(_member!);

  Future<void> _submit() async {
    final member = _member!;
    final months = _selectedMonths;
    final dues = _dues!;
    final total = dues * months.length;
    final l10n = context.l10n;
    final name = member['name']?.toString() ?? l10n.recordPayThisMember;
    final period = DuesPeriod.paidMonthsLabel(months);

    final ok = await AppBottomSheet.showConfirmation(
      context: context,
      title: l10n.recordPayConfirmTitle(Inr.format(total)),
      message: l10n.recordPayConfirmMessage(Inr.format(total), name, period,
          AdminFormat.months(months.length)),
      confirmLabel: l10n.recordPayConfirm,
      icon: Icons.receipt_long_rounded,
    );
    if (ok != true || !mounted) return;

    setState(() {
      _saving = true;
      _submitError = null;
    });
    try {
      final memberId = AdminFormat.memberId(member);
      final res = await _api.recordCashDuesPaymentOrThrow(
        memberId: memberId,
        selectedMonths: months,
        idempotencyKey: 'ADMIN_CASH_${memberId}_${months.join('_')}_$_openedAt',
      );
      AdminContext.invalidateMembers();
      if (!mounted) return;
      Navigator.of(context).pop(res);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = e.userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_member == null) return _picker();
    return _details();
  }

  // -------------------------------------------------------------------------
  // Step 1: choose a member
  // -------------------------------------------------------------------------

  Widget _picker() {
    final l10n = context.l10n;
    Widget body;
    if (_loadingMembers) {
      body = ShimmerLoading(
        semanticsLabel: l10n.recordPayLoadingMembers,
        child: const Column(
          children: [
            ShimmerCardSkeleton(height: 56),
            ShimmerCardSkeleton(height: 56),
            ShimmerCardSkeleton(height: 56),
          ],
        ),
      );
    } else if (_membersError != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNoticeCard(
            icon: Icons.cloud_off_rounded,
            title: l10n.recordPayMembersError,
            message: _membersError!.userMessage,
            color: context.colors.error,
            background: context.colors.errorBg,
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            label: l10n.recordPayTryAgain,
            icon: Icons.refresh_rounded,
            onPressed: _loadMembers,
          ),
        ],
      );
    } else {
      final matches = _matches;
      body = matches.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                (_members ?? const []).isEmpty
                    ? l10n.recordPayNoMembers
                    : l10n.recordPayNoMatch(_query),
                textAlign: TextAlign.center,
                style:
                    context.text.body.copyWith(color: context.colors.textSecondary),
              ),
            )
          : Column(
              children: [
                for (final m in matches) _memberOption(m),
                if ((_members?.length ?? 0) > matches.length)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      l10n.recordPayShowing(matches.length, _members!.length),
                      style: context.text.caption,
                    ),
                  ),
              ],
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.recordPayMemberHeading, style: context.text.label),
        const SizedBox(height: AppSpacing.sm),
        AppSearchBar(
          controller: _search,
          hintText: l10n.recordPaySearchHint,
          onChanged: _onSearch,
        ),
        const SizedBox(height: AppSpacing.ms),
        body,
      ],
    );
  }

  Widget _memberOption(Map<String, dynamic> m) {
    final name = m['name']?.toString() ?? '—';
    final house = m['house_name']?.toString() ?? '';
    final phone = m['phone']?.toString() ?? '';
    final status = AdminFormat.memberStatus(m['status']?.toString());
    return InkWell(
      onTap: () => setState(() {
        _member = m;
        _months = 1;
        _submitError = null;
      }),
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            AppAvatar(name: name, size: 40, excludeFromSemantics: true),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.listTitle),
                  Text(
                    [phone, house].where((s) => s.isNotEmpty).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.small,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: StatusPill(
                label: status.label,
                foreground: status.foreground(context),
                background: status.background(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Step 2: months + confirm
  // -------------------------------------------------------------------------

  Widget _details() {
    final m = _member!;
    final name = m['name']?.toString() ?? '—';
    final dues = _dues;
    final months = _selectedMonths;
    final hasAnchor = months.isNotEmpty;
    final l10n = context.l10n;
    final blocked = AdminFormat.memberId(m).isEmpty
        ? l10n.recordPayNoId
        : dues == null
            ? l10n.recordPayNoDues
            : !hasAnchor
                ? l10n.recordPayNoAnchor
                : null;
    final total = (dues ?? 0) * months.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.recordPayMemberHeading, style: context.text.label),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            AppAvatar(name: name, size: 40, excludeFromSemantics: true),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.listTitle),
                  Text(
                    dues == null
                        ? l10n.recordPayDuesNotSet
                        : l10n.recordPayPerMonth(Inr.format(dues)),
                    style: context.text.small,
                  ),
                ],
              ),
            ),
            if (widget.initialMember == null)
              AppTextActionButton(
                label: l10n.recordPayChange,
                onPressed: _saving
                    ? null
                    : () => setState(() {
                          _member = null;
                          _submitError = null;
                        }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (blocked != null)
          AppNoticeCard(
            icon: Icons.info_outline_rounded,
            title: l10n.recordPayCantRecord,
            message: blocked,
            color: context.colors.warning,
            background: context.colors.warningBg,
          )
        else ...[
          Text(l10n.recordPayMonthsHeading, style: context.text.label),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var i = 0; i < _monthOptions.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: _monthChip(_monthOptions[i])),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.recordPayCovers(DuesPeriod.paidMonthsLabel(months)),
            style: context.text.caption,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.recordPayMethodHeading, style: context.text.label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.recordPayMethodDesc,
            style: context.text.small,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.ms),
            decoration: BoxDecoration(
              color: context.colors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.recordPayTotal,
                    style: context.text.body
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  Inr.format(total),
                  style: context.text.sectionTitle
                      .copyWith(color: context.colors.primary),
                ),
              ],
            ),
          ),
        ],
        if (_submitError != null) ...[
          const SizedBox(height: AppSpacing.md),
          AppNoticeCard(
            icon: Icons.error_outline_rounded,
            title: l10n.recordPayNotRecorded,
            message: _submitError!,
            color: context.colors.error,
            background: context.colors.errorBg,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: l10n.recordPayReview,
          isLoading: _saving,
          onPressed: (blocked != null || _saving) ? null : _submit,
        ),
      ],
    );
  }

  Widget _monthChip(int count) {
    final selected = _months == count;
    return Semantics(
      selected: selected,
      button: true,
      label: AdminFormat.months(count),
      excludeSemantics: true,
      child: InkWell(
        onTap: _saving ? null : () => setState(() => _months = count),
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? context.colors.primaryLight : context.colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: selected ? context.colors.primary : context.colors.border,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AdminFormat.months(count),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: context.text.buttonSmall.copyWith(
                color: selected
                    ? context.colors.primary
                    : context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

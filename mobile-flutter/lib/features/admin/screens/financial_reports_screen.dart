import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/dues_period.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../l10n/l10n.dart';
import '../data/admin_context.dart';
import '../utils/admin_format.dart';
import '../utils/share_file.dart';
import '../utils/statement_pdf.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../widgets/receipt_sheet.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  /// Internal filter keys; shown via [_typeFilterLabel].
  static const List<String> _typeFilters = ['All', 'Dues', 'Contribution'];
  static const String _allTime = 'ALL';
  static const int _pageSize = 100;
  static const int _maxPages = 20;

  final ApiService _api = ApiService();

  String _typeFilter = 'All';

  /// "ALL" or a "YYYY-MM" month key.
  String _period = _allTime;

  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  ApiException? _summaryError;

  List<Map<String, dynamic>> _payments = const [];
  bool _paymentsComplete = true;
  ApiException? _paymentsError;
  Map<String, String> _names = const {};

  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Fetches the server summary (for the selected period) and the tenant's
  /// transactions once; the type filter and the transaction list then work
  /// in memory. Changing the period re-fetches only the summary.
  Future<void> _loadData() async {
    setState(() {
      _summaryError = null;
      _paymentsError = null;
    });
    await Future.wait([_loadSummary(), _loadPayments()]);
    if (mounted) setState(() => _isLoading = false);
  }

  /// GET /admin/reports/financial?month=YYYY-MM (none = all time), so the
  /// server totals cover the same period as the filter. `pending_dues` is
  /// always the current snapshot.
  Future<void> _loadSummary() async {
    final period = _period;
    try {
      final r = await _api.getFinancialReportOrThrow(
        month: period == _allTime ? null : period,
      );
      // A newer period was picked while this one loaded.
      if (!mounted || period != _period) return;
      setState(() => _summary = r['summary'] is Map
          ? Map<String, dynamic>.from(r['summary'] as Map)
          : const {});
    } on ApiException catch (e) {
      if (mounted && period == _period) setState(() => _summaryError = e);
    }
  }

  void _setPeriod(String period) {
    if (period == _period) return;
    setState(() {
      _period = period;
      _summary = null;
      _summaryError = null;
    });
    _loadSummary();
  }

  Future<void> _loadPayments() async {
    try {
      final all = <Map<String, dynamic>>[];
      var complete = false;
      for (var page = 1; page <= _maxPages; page++) {
        final res = await _api.getAdminPayments(page: page, limit: _pageSize);
        all.addAll(res.items.whereType<Map>().map(Map<String, dynamic>.from));
        if (!res.hasMore || res.items.isEmpty) {
          complete = true;
          break;
        }
      }
      final names = await AdminContext.memberNames();
      if (!mounted) return;
      setState(() {
        _payments = all;
        _paymentsComplete = complete;
        _names = names;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _paymentsError = e);
    }
  }

  // -------------------------------------------------------------------------
  // In-memory filtering
  // -------------------------------------------------------------------------

  bool _matchesType(Map<String, dynamic> p) {
    final t = (p['type'] ?? '').toString().toUpperCase();
    switch (_typeFilter) {
      case 'Dues':
        return t == 'MONTHLY_DUES';
      case 'Contribution':
        return t == 'CONTRIBUTION' || t == 'DONATION';
      default:
        return true;
    }
  }

  static DateTime? _when(Map<String, dynamic> p) =>
      AppDate.tryParse(p['completed_at'] ?? p['created_at']);

  static String? _monthKey(Map<String, dynamic> p) {
    final d = _when(p);
    return d == null ? null : DuesPeriod.monthKeyOf(d);
  }

  static bool _isSuccess(Map<String, dynamic> p) =>
      (p['status'] ?? '').toString().toUpperCase() == 'SUCCESS';

  /// Successful transactions matching the type + period filters, newest first.
  List<Map<String, dynamic>> get _filtered {
    final list = _payments.where((p) {
      if (!_isSuccess(p) || !_matchesType(p)) return false;
      return _period == _allTime || _monthKey(p) == _period;
    }).toList();
    list.sort((a, b) {
      final da = _when(a), db = _when(b);
      if (da == null || db == null) return 0;
      return db.compareTo(da);
    });
    return list;
  }

  static double _amount(Map<String, dynamic> p) {
    final v = p['amount'];
    return v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
  }

  /// Month → (total, count) over [list].
  List<({String month, double total, int count})> _byMonth(
      List<Map<String, dynamic>> list) {
    final map = <String, ({double total, int count})>{};
    for (final p in list) {
      final k = _monthKey(p);
      if (k == null) continue;
      final cur = map[k] ?? (total: 0.0, count: 0);
      map[k] = (total: cur.total + _amount(p), count: cur.count + 1);
    }
    final keys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final k in keys)
        (month: k, total: map[k]!.total, count: map[k]!.count)
    ];
  }

  /// The last 12 months (derived from today) plus any older month that has
  /// transactions, newest first.
  List<String> get _monthOptions {
    final now = DateTime.now();
    final keys = <String>{
      for (var i = 0; i < 12; i++)
        DuesPeriod.monthKeyOf(DateTime(now.year, now.month - i, 1)),
      for (final p in _payments)
        if (_monthKey(p) != null) _monthKey(p)!,
      if (_period != _allTime) _period,
    };
    return keys.toList()..sort((a, b) => b.compareTo(a));
  }

  String _periodLabel(String p) => p == _allTime
      ? context.l10n.reportsAllTime
      : AppDate.formatMonthYear(DuesPeriod.parseMonthKey(p));

  String _typeFilterLabel(String key) {
    final l = context.l10n;
    switch (key) {
      case 'Dues':
        return l.reportsFilterDues;
      case 'Contribution':
        return l.reportsFilterContribution;
      default:
        return l.reportsFilterAll;
    }
  }

  String get _typeLabel => _typeFilter == 'All'
      ? context.l10n.reportsAllTypes
      : _typeFilterLabel(_typeFilter);

  // The PDF uses built-in Helvetica (Latin only), so everything written into
  // it stays English regardless of the app language.
  static final DateFormat _pdfDate = DateFormat('d MMM y', 'en_US');

  static String _pdfPeriodLabel(String p) {
    if (p == _allTime) return 'All time';
    final d = DuesPeriod.parseMonthKey(p);
    return d == null ? p : DateFormat('MMM y', 'en_US').format(d);
  }

  String get _pdfTypeLabel => _typeFilter == 'All' ? 'All types' : _typeFilter;

  static String _pdfPaymentType(String? raw) {
    final t = (raw ?? '').trim().toUpperCase();
    switch (t) {
      case 'MONTHLY_DUES':
        return 'Monthly dues';
      case 'CONTRIBUTION':
      case 'DONATION':
        return 'Contribution';
      case '':
        return 'Payment';
      default:
        final words = t.replaceAll(RegExp(r'[_\-]+'), ' ').toLowerCase();
        return words[0].toUpperCase() + words.substring(1);
    }
  }

  String _memberName(Map<String, dynamic> p) {
    final id = p['member_id']?.toString() ?? '';
    final n = _names[id] ?? '';
    return n.isNotEmpty ? n : (id.isEmpty ? '—' : id);
  }

  // -------------------------------------------------------------------------
  // Export
  // -------------------------------------------------------------------------

  Future<void> _export() async {
    final list = _filtered;
    final total = list.fold<double>(0, (s, p) => s + _amount(p));
    final mahal = AdminContext.mahalName ?? 'MahalFlow';
    setState(() => _exporting = true);
    try {
      final bytes = StatementPdf.build(
        mahalName: mahal,
        registrationNumber: AdminContext.registrationNumber,
        periodLabel: _pdfPeriodLabel(_period),
        typeLabel: _pdfTypeLabel,
        generatedAt:
            DateFormat('d MMM y, h:mm a', 'en_US').format(DateTime.now()),
        summary: [
          ('Collected in this statement', Inr.format(total)),
          ('Transactions', '${list.length}'),
          if (_summary != null) ...[
            (
              _period == _allTime
                  ? 'All-time collected (server)'
                  : 'Collected in period (server)',
              Inr.formatAny(_summary!['total_collected'])
            ),
            (
              'Pending dues now (server)',
              Inr.formatAny(_summary!['pending_dues'])
            ),
          ],
        ],
        lines: [
          for (final p in list)
            StatementLine(
              date: _when(p) == null ? '-' : _pdfDate.format(_when(p)!),
              member: _memberName(p),
              type: _pdfPaymentType(p['type']?.toString()),
              reference: (p['receipt_id'] ?? p['id'] ?? '').toString(),
              amount: Inr.format(_amount(p)),
            ),
        ],
        footnote: _paymentsComplete
            ? 'Successful transactions only. Generated on this device from '
                'the MahalFlow ledger.'
            : 'Only the ${_payments.length} most recent transactions were '
                'available when this statement was generated.',
      );
      if (!mounted) return;
      final stem = safeFileStem(
          '${mahal}_statement_${_period == _allTime ? 'all_time' : _period}');
      await shareGeneratedFile(
        context,
        bytes: bytes,
        fileName: '$stem.pdf',
        mimeType: 'application/pdf',
        subject: context.l10n.reportsShareSubject(mahal, _periodLabel(_period)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.reportsExportError('$e')),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bothFailed = _summaryError != null && _paymentsError != null;
    final l = context.l10n;
    final filterLabels = [for (final f in _typeFilters) _typeFilterLabel(f)];

    return AppPageScaffold(
      title: l.reportsTitle,
      eyebrow: l.reportsEyebrow,
      subtitle: '${_periodLabel(_period)} · $_typeLabel',
      onBack: () => AppNav.adminHome(context),
      headerChild: AppHeroFilterChips(
        options: filterLabels,
        selected: _typeFilterLabel(_typeFilter),
        onSelected: (label) {
          final i = filterLabels.indexOf(label);
          setState(() => _typeFilter = i < 0 ? 'All' : _typeFilters[i]);
        },
      ),
      onRefresh: _loadData,
      floatingChild: bothFailed ? null : _summaryCard(),
      content: [
        const SizedBox(height: AppSpacing.md),
        if (bothFailed)
          AppErrorStateView(
            title: l.reportsLoadError,
            description: _paymentsError!.userMessage,
            onRetry: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          )
        else ...[
          AppDropdownField<String>(
            label: l.reportsPeriod,
            value: _period,
            items: [
              DropdownMenuItem(
                  value: _allTime, child: Text(l.reportsAllTime)),
              for (final m in _monthOptions)
                DropdownMenuItem(value: m, child: Text(_periodLabel(m))),
            ],
            onChanged: (v) {
              if (v != null) _setPeriod(v);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _periodCard(),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            label: _exporting ? l.reportsPreparing : l.reportsExport,
            icon: Icons.picture_as_pdf_outlined,
            onPressed: (_isLoading || _exporting || _paymentsError != null)
                ? null
                : _export,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: _period == _allTime
                ? l.reportsMonthByMonth
                : l.reportsTransactions,
          ),
          _breakdown(),
        ],
      ],
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 2),
    );
  }

  /// Server totals for the selected period, all types.
  Widget _summaryCard() {
    final s = _summary;
    final l = context.l10n;
    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l.reportsTotalCollected,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.label),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: StatusPill(
                    label: _period == _allTime
                        ? l.reportsAllTimeAllTypes
                        : l.reportsPeriodAllTypes(_periodLabel(_period)),
                    foreground: context.colors.primary,
                    background: context.colors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          if (_summaryError != null)
            AppNoticeCard(
              icon: Icons.cloud_off_rounded,
              title: l.reportsTotalsError,
              message: _summaryError!.userMessage,
              color: context.colors.error,
              background: context.colors.errorBg,
              actionLabel: l.reportsTryAgain,
              onAction: () {
                setState(() => _summaryError = null);
                _loadSummary();
              },
            )
          else if (s == null)
            ShimmerLoading(
              semanticsLabel: l.reportsLoadingTotals,
              child: const ShimmerSkeletonBox(width: 200, height: 34),
            )
          else ...[
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                Inr.formatAny(s['total_collected']),
                style: context.text.amount.copyWith(color: context.colors.success),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: context.colors.border),
            const SizedBox(height: AppSpacing.ms),
            Row(
              children: [
                Expanded(
                  child: _miniStat(l.reportsDues, Inr.formatAny(s['dues_collected']),
                      context.colors.primary),
                ),
                Expanded(
                  child: _miniStat(l.reportsContributions,
                      Inr.formatAny(s['donations']), context.colors.info),
                ),
                Expanded(
                  child: _miniStat(l.reportsPendingDuesNow,
                      Inr.formatAny(s['pending_dues']), context.colors.warning),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.small),
          const SizedBox(height: AppSpacing.xs / 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: context.text.listTitle.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  /// Totals for the selected period + type, computed from the transactions.
  Widget _periodCard() {
    if (_paymentsError != null) {
      return AppNoticeCard(
        icon: Icons.cloud_off_rounded,
        title: context.l10n.reportsTransactionsError,
        message: _paymentsError!.userMessage,
        color: context.colors.error,
        background: context.colors.errorBg,
        actionLabel: context.l10n.reportsTryAgain,
        onAction: () {
          setState(() {
            _paymentsError = null;
            _isLoading = true;
          });
          _loadData();
        },
      );
    }
    if (_isLoading) {
      return ShimmerLoading(
        semanticsLabel: context.l10n.reportsLoadingPeriod,
        child: const ShimmerCardSkeleton(height: 88),
      );
    }
    final list = _filtered;
    final total = list.fold<double>(0, (s, p) => s + _amount(p));
    return AppCard(
      child: Row(
        children: [
          AppIconChip(
            icon: Icons.calendar_month_outlined,
            color: context.colors.primary,
            background: context.colors.primaryLight,
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_periodLabel(_period)} · $_typeLabel',
                    style: context.text.small),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(Inr.format(total),
                      style: context.text.statValue
                          .copyWith(color: context.colors.success)),
                ),
                Text(
                  context.l10n.reportsSuccessfulPayments(list.length),
                  style: context.text.caption,
                ),
                if (!_paymentsComplete)
                  Text(
                    context.l10n.reportsBasedOnRecent(_payments.length),
                    style: context.text.caption
                        .copyWith(color: context.colors.warning),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdown() {
    if (_paymentsError != null) return const SizedBox.shrink();
    if (_isLoading) {
      return ShimmerLoading(
        semanticsLabel: context.l10n.reportsLoadingBreakdown,
        child: Column(
          children: [
            for (var i = 0; i < 3; i++) const ShimmerCardSkeleton(height: 64),
          ],
        ),
      );
    }
    final list = _filtered;
    if (list.isEmpty) {
      return AppCard(
        child: EmptyStateView(
          icon: Icons.bar_chart_rounded,
          title: context.l10n.reportsNoPayments,
          description: context.l10n.reportsNoPaymentsDesc,
        ),
      );
    }

    if (_period == _allTime) {
      final months = _byMonth(list);
      return AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < months.length; i++) ...[
              if (i > 0) Divider(height: 1, color: context.colors.border),
              _monthRow(months[i]),
            ],
          ],
        ),
      );
    }

    final shown = list.take(100).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < shown.length; i++) ...[
                if (i > 0) Divider(height: 1, color: context.colors.border),
                _paymentRow(shown[i]),
              ],
            ],
          ),
        ),
        if (list.length > shown.length)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              context.l10n.reportsShowingOf(shown.length, list.length),
              style: context.text.caption,
            ),
          ),
      ],
    );
  }

  Widget _monthRow(({String month, double total, int count}) m) {
    return InkWell(
      onTap: () => _setPeriod(m.month),
      child: Padding(
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
                  Text(_periodLabel(m.month), style: context.text.listTitle),
                  const SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    context.l10n.reportsPaymentsRecorded(m.count),
                    style: context.text.small,
                  ),
                ],
              ),
            ),
            Text(
              Inr.format(m.total),
              style: context.text.listTitle.copyWith(color: context.colors.success),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: context.colors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _paymentRow(Map<String, dynamic> p) {
    final receipt = p['receipt_id']?.toString() ?? '';
    final content = Padding(
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
                Text(_memberName(p),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.listTitle),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(
                  '${AdminFormat.paymentType(p['type']?.toString())} · '
                  '${AppDate.formatDate(_when(p))}',
                  style: context.text.small,
                ),
              ],
            ),
          ),
          Text(Inr.format(_amount(p)), style: context.text.listTitle),
          if (receipt.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: context.colors.textMuted),
          ],
        ],
      ),
    );
    if (receipt.isEmpty) return content;
    return InkWell(
      onTap: () => ReceiptSheet.show(context, receipt),
      child: content,
    );
  }
}

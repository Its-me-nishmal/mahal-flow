import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../l10n/l10n.dart';
import '../utils/admin_format.dart';
import '../widgets/admin_bottom_nav_bar.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  static const int _pageSize = 40;
  /// Internal filter keys (also what [typeOf] returns); shown via
  /// [_filterLabel].
  static const List<String> _filters = [
    'All',
    'Payment',
    'Member',
    'Alerts',
    'System',
  ];

  String _filterLabel(String key) {
    final l = context.l10n;
    switch (key) {
      case 'Payment':
        return l.auditFilterPayment;
      case 'Member':
        return l.auditFilterMember;
      case 'Alerts':
        return l.auditFilterAlerts;
      case 'System':
        return l.auditFilterSystem;
      default:
        return l.auditFilterAll;
    }
  }

  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;

  final List<Map<String, dynamic>> _logs = [];
  int _total = 0;
  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _loadingMore = false;
  ApiException? _error;
  ApiException? _moreError;

  String _activeFilter = 'All';
  String _query = '';
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _refresh();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = _logs.isEmpty;
      _error = null;
      _moreError = null;
    });
    try {
      final res = await _api.getAuditLogsPage(page: 1, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _logs
          ..clear()
          ..addAll(res.items.whereType<Map>().map(Map<String, dynamic>.from));
        _total = res.total;
        _page = 1;
        _hasMore = res.hasMore && res.items.isNotEmpty;
        _isLoading = false;
      });
      _maybeFillViewport();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _error != null) return;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final res =
          await _api.getAuditLogsPage(page: _page + 1, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _logs.addAll(res.items.whereType<Map>().map(Map<String, dynamic>.from));
        _total = res.total;
        _page = res.page;
        _hasMore = res.hasMore && res.items.isNotEmpty;
        _loadingMore = false;
      });
      _maybeFillViewport();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _moreError = e;
        _loadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.extentAfter < 400) _loadMore();
  }

  void _maybeFillViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (_scroll.position.maxScrollExtent < 200 && !_pastRange) _loadMore();
    });
  }

  /// Logs arrive newest first; once the oldest loaded entry is before the
  /// chosen range there is nothing more to find by paging further.
  bool get _pastRange {
    final r = _range;
    if (r == null || _logs.isEmpty) return false;
    final oldest = AppDate.tryParse(_logs.last['timestamp']);
    return oldest != null && oldest.isBefore(r.start);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value.trim().toLowerCase());
      _maybeFillViewport();
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _range,
      helpText: context.l10n.auditDateRangeHelp,
    );
    if (picked == null || !mounted) return;
    setState(() => _range = DateTimeRange(
          start:
              DateTime(picked.start.year, picked.start.month, picked.start.day),
          end: DateTime(
              picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
        ));
    _maybeFillViewport();
  }

  static String typeOf(dynamic action) {
    final a = action?.toString().toUpperCase() ?? '';
    if (a.startsWith('MEMBER_')) return 'Member';
    if (a.startsWith('ALERT_')) return 'Alerts';
    if (a.contains('PAYMENT') ||
        a.contains('DONATION') ||
        a.contains('REFUND') ||
        a.startsWith('AUTOPAY_')) {
      return 'Payment';
    }
    return 'System';
  }

  List<Map<String, dynamic>> get _filteredLogs {
    final q = _query;
    final r = _range;
    return _logs.where((l) {
      if (_activeFilter != 'All' && typeOf(l['action']) != _activeFilter) {
        return false;
      }
      if (r != null) {
        final t = AppDate.tryParse(l['timestamp'] ?? l['created_at']);
        if (t == null || t.isBefore(r.start) || t.isAfter(r.end)) return false;
      }
      if (q.isEmpty) return true;
      return [l['action'], l['details'], l['actor'], l['entity_id']]
          .map((v) => (v ?? '').toString().toLowerCase())
          .any((v) => v.contains(q));
    }).toList();
  }

  bool get _isFiltering =>
      _query.isNotEmpty || _activeFilter != 'All' || _range != null;

  String get _subtitle {
    final l = context.l10n;
    if (_isLoading) return l.auditSubtitleLoading;
    if (_error != null) return l.auditSubtitleUnavailable;
    if (!_isFiltering) return l.auditSubtitleShowing(_logs.length, _total);
    final n = _filteredLogs.length;
    return _hasMore && !_pastRange
        ? l.auditSubtitleMatchesLoaded(n, _logs.length, _total)
        : l.auditSubtitleMatching(n);
  }

  @override
  Widget build(BuildContext context) {
    final r = _range;
    final l = context.l10n;
    final filterLabels = [for (final f in _filters) _filterLabel(f)];
    return AppPageScaffold(
      title: l.auditTitle,
      eyebrow: l.auditEyebrow,
      subtitle: _subtitle,
      onBack: () => AppNav.adminHome(context),
      actions: [
        AppHeaderIconButton(
          icon:
              r == null ? Icons.date_range_outlined : Icons.event_busy_outlined,
          tooltip: r == null ? l.auditFilterByDate : l.auditClearDateFilter,
          onTap: r == null ? _pickRange : () => setState(() => _range = null),
        ),
      ],
      headerChild: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSearchBar(
            controller: _searchController,
            hintText: l.auditSearchHint,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
          ),
          const SizedBox(height: AppSpacing.ms),
          AppHeroFilterChips(
            options: filterLabels,
            selected: _filterLabel(_activeFilter),
            onSelected: (label) {
              final i = filterLabels.indexOf(label);
              setState(() => _activeFilter = i < 0 ? 'All' : _filters[i]);
              _maybeFillViewport();
            },
          ),
          if (r != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${AppDate.formatDate(r.start)} – ${AppDate.formatDate(r.end)}',
              style: context.text.small.copyWith(color: AdminHeroColors.muted),
            ),
          ],
        ],
      ),
      expandedChild: RefreshIndicator(
        onRefresh: _refresh,
        color: context.colors.primary,
        backgroundColor: context.colors.surface,
        child: _body(),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 3),
    );
  }

  Widget _body() {
    if (_isLoading) return _skeleton();
    if (_error != null) {
      return AppErrorStateView(
        title: context.l10n.auditLoadError,
        description: _error!.userMessage,
        onRetry: _refresh,
      );
    }
    final displayed = _filteredLogs;
    final canLoadMore = _hasMore && !_pastRange;
    if (displayed.isEmpty && !canLoadMore) return _empty();

    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xl,
      ),
      itemCount: displayed.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == displayed.length) return _footer(canLoadMore);
        return _logEntry(displayed[index]);
      },
    );
  }

  Widget _footer(bool canLoadMore) {
    if (_moreError != null) {
      return AppNoticeCard(
        icon: Icons.cloud_off_rounded,
        title: context.l10n.auditLoadOlderError,
        message: _moreError!.userMessage,
        color: context.colors.error,
        background: context.colors.errorBg,
        actionLabel: context.l10n.auditTryAgain,
        onAction: _loadMore,
      );
    }
    if (canLoadMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        _pastRange
            ? context.l10n.auditEndOfRange
            : context.l10n.auditStartOfLog,
        textAlign: TextAlign.center,
        style: context.text.caption,
      ),
    );
  }

  ({Color color, Color bg, IconData icon}) _style(String type) {
    switch (type) {
      case 'Payment':
        return (
          color: context.colors.success,
          bg: context.colors.successBg,
          icon: Icons.payments_outlined
        );
      case 'Member':
        return (
          color: context.colors.info,
          bg: context.colors.infoBg,
          icon: Icons.person_outline_rounded
        );
      case 'Alerts':
        return (
          color: context.colors.warning,
          bg: context.colors.warningBg,
          icon: Icons.campaign_outlined
        );
      default:
        return (
          color: context.colors.textSecondary,
          bg: context.colors.neutralBg,
          icon: Icons.settings_outlined
        );
    }
  }

  Widget _logEntry(Map<String, dynamic> log) {
    final type = typeOf(log['action']);
    final s = _style(type);
    final action = AdminFormat.humanize(log['action']?.toString(),
        fallback: context.l10n.auditSystemAction);
    final details = (log['details']?.toString().trim().isNotEmpty ?? false)
        ? log['details'].toString()
        : action;
    final actor = log['actor']?.toString().trim() ?? '';
    final time = AppDate.relative(log['timestamp'] ?? log['created_at']);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.ms),
      onTap: () => _showDetail(log),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconChip(
            icon: s.icon,
            color: s.color,
            background: s.bg,
            size: 38,
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: StatusPill(
                        label: action,
                        foreground: s.color,
                        background: s.bg,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Spacer(),
                    Text(time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.caption),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  details,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style:
                      context.text.body.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: AppSpacing.xs / 2),
                Text(context.l10n.auditBy(actor.isEmpty ? '—' : actor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.small),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.chevron_right_rounded,
              size: 20, color: context.colors.textMuted),
        ],
      ),
    );
  }

  void _showDetail(Map<String, dynamic> log) {
    String v(dynamic x) {
      final s = x?.toString().trim() ?? '';
      return s.isEmpty ? '—' : s;
    }

    final entity = log['entity_id']?.toString() ?? '';
    final l = context.l10n;
    AppBottomSheet.show(
      context: context,
      title: AdminFormat.humanize(log['action']?.toString(),
          fallback: l.auditLogEntry),
      subtitle: AppDate.formatDateTime(log['timestamp'] ?? log['created_at']),
      icon: _style(typeOf(log['action'])).icon,
      builder: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppDetailRow(label: l.auditDetailAction, value: v(log['action'])),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(label: l.auditDetailBy, value: v(log['actor'])),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
            label: l.auditDetailRecord,
            value: v(entity),
            copyable: entity.isNotEmpty,
            onCopy: entity.isEmpty
                ? null
                : () {
                    Clipboard.setData(ClipboardData(text: entity));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.auditRecordIdCopied)),
                    );
                  },
          ),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(label: l.auditDetailIp, value: v(log['ip_address'])),
          Divider(height: 1, color: context.colors.border),
          const SizedBox(height: AppSpacing.ms),
          Text(l.auditDetailsHeading, style: context.text.label),
          const SizedBox(height: AppSpacing.xs),
          SelectableText(v(log['details']), style: context.text.body),
        ],
      ),
    );
  }

  Widget _empty() {
    final l = context.l10n;
    if (_logs.isEmpty) {
      return EmptyStateView(
        icon: Icons.history_rounded,
        title: l.auditEmptyTitle,
        description: l.auditEmptyDesc,
      );
    }
    return EmptyStateView(
      icon: Icons.history_rounded,
      title: l.auditNoMatchTitle,
      description: _query.isNotEmpty
          ? l.auditNoMatchQuery(_searchController.text.trim())
          : l.auditNoMatchFilters,
      actionLabel: l.auditClearFilters,
      onAction: () {
        _clearSearch();
        setState(() {
          _activeFilter = 'All';
          _range = null;
        });
      },
    );
  }

  Widget _skeleton() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xl,
      ),
      children: [
        ShimmerLoading(
          semanticsLabel: context.l10n.auditLoadingSemantics,
          child: Column(
            children: [
              for (var i = 0; i < 6; i++) const ShimmerCardSkeleton(height: 80),
            ],
          ),
        ),
      ],
    );
  }
}

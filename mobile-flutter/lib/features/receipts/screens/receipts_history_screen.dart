import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../l10n/l10n.dart';
import '../receipt_view.dart';
import 'receipt_details_screen.dart';

class ReceiptsHistoryScreen extends StatefulWidget {
  const ReceiptsHistoryScreen({super.key});

  @override
  State<ReceiptsHistoryScreen> createState() => _ReceiptsHistoryScreenState();
}

class _ReceiptsHistoryScreenState extends State<ReceiptsHistoryScreen> {
  final ApiService _apiService = ApiService();
  // Internal filter keys; [_filterLabel] gives the display text.
  static const List<String> _filters = ['All', 'Monthly', 'Contribution'];

  String _filterLabel(String key) {
    final l10n = context.l10n;
    switch (key) {
      case 'Monthly':
        return l10n.receiptsFilterMonthly;
      case 'Contribution':
        return l10n.receiptsFilterContribution;
      default:
        return l10n.receiptsFilterAll;
    }
  }

  String _selectedFilter = 'All';
  List<ReceiptView> _receipts = [];
  bool _isLoading = true;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    // A pull-to-refresh keeps the current list on screen while it loads.
    final firstLoad = _receipts.isEmpty;
    if (mounted && firstLoad) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final rawList = await _apiService.getMemberReceiptsOrThrow();
      final loaded = rawList
          .whereType<Map>()
          .map((m) => ReceiptView.fromJson(m.cast<String, dynamic>()))
          .toList()
        ..sort((a, b) {
          final da = a.createdAt, db = b.createdAt;
          if (da == null || db == null) return 0;
          return db.compareTo(da);
        });
      if (!mounted) return;
      setState(() {
        _receipts = loaded;
        _error = null;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (firstLoad) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      } else {
        // Never blank out receipts the member is already looking at.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.dashboardRefreshFailed(e.userMessage)),
          ),
        );
      }
    }
  }

  List<ReceiptView> get _filteredReceipts {
    switch (_selectedFilter) {
      case 'Monthly':
        return _receipts.where((r) => r.isDues).toList();
      case 'Contribution':
        return _receipts.where((r) => !r.isDues).toList();
      default:
        return _receipts;
    }
  }

  /// Counts keyed by the chip's display label.
  Map<String, int> get _counts => {
        _filterLabel('All'): _receipts.length,
        _filterLabel('Monthly'): _receipts.where((r) => r.isDues).length,
        _filterLabel('Contribution'):
            _receipts.where((r) => !r.isDues).length,
      };

  void _openReceipt(ReceiptView receipt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReceiptDetailsScreen(receipt: receipt),
      ),
    );
  }

  (Color, Color) _statusColors(ReceiptView r) {
    if (r.isSuccess) return (context.colors.success, context.colors.successBg);
    switch (r.status) {
      case 'PENDING':
      case 'PROCESSING':
        return (context.colors.warning, context.colors.warningBg);
      case 'REFUNDED':
        return (context.colors.info, context.colors.infoBg);
      case 'FAILED':
        return (context.colors.error, context.colors.errorBg);
      default:
        return (context.colors.textSecondary, context.colors.neutralBg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipts = _filteredReceipts;

    Widget body;
    if (_isLoading) {
      body = _skeleton();
    } else if (_error != null) {
      body = AppErrorStateView(
        title: context.l10n.receiptsLoadError,
        description: _error!.userMessage,
        onRetry: _loadReceipts,
      );
    } else if (receipts.isEmpty) {
      body = _empty();
    } else {
      body = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.md,
          AppSpacing.screenH,
          AppSpacing.xl,
        ),
        itemCount: receipts.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final receipt = receipts[index];
          final (fg, bg) = _statusColors(receipt);
          return AppListRow(
            icon: receipt.isDues
                ? Icons.receipt_long_outlined
                : Icons.volunteer_activism_outlined,
            iconColor: receipt.isDues ? context.colors.primary : context.colors.warning,
            iconBackground:
                receipt.isDues ? context.colors.primaryLight : context.colors.warningBg,
            title: receipt.title,
            caption: '${receipt.subtitle} · ${receipt.dateLabel}',
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(receipt.amountLabel, style: context.text.listTitle),
                const SizedBox(height: AppSpacing.xs),
                StatusPill(
                  label: receipt.statusLabel,
                  foreground: fg,
                  background: bg,
                ),
              ],
            ),
            onTap: () => _openReceipt(receipt),
            showChevron: true,
          );
        },
      );
    }

    return AppPageScaffold(
      title: context.l10n.receiptsTitle,
      eyebrow: context.l10n.receiptsEyebrow,
      subtitle: context.l10n.receiptsSubtitle,
      onBack: () => AppNav.memberHome(context),
      headerChild: AppHeroFilterChips(
        // Chips show translated labels; state keeps the internal key.
        options: [for (final f in _filters) _filterLabel(f)],
        selected: _filterLabel(_selectedFilter),
        counts: (_isLoading || _error != null) ? null : _counts,
        onSelected: (label) => setState(() {
          _selectedFilter = _filters.firstWhere(
            (f) => _filterLabel(f) == label,
            orElse: () => 'All',
          );
        }),
      ),
      expandedChild: RefreshIndicator(
        onRefresh: _loadReceipts,
        color: context.colors.primary,
        backgroundColor: context.colors.surface,
        child: body,
      ),
      bottomNavigationBar: const MemberBottomNavBar(currentIndex: 2),
    );
  }

  Widget _empty() {
    final l10n = context.l10n;
    final all = _selectedFilter == 'All';
    return EmptyStateView(
      icon: Icons.receipt_long_outlined,
      title: all
          ? l10n.receiptsEmptyTitle
          : _selectedFilter == 'Monthly'
              ? l10n.receiptsEmptyMonthlyTitle
              : l10n.receiptsEmptyContributionTitle,
      description: all ? l10n.receiptsEmptyBody : l10n.receiptsEmptyFilteredBody,
      actionLabel: all ? l10n.receiptsPayDues : null,
      onAction: _selectedFilter == 'All'
          ? () => AppNav.switchMemberTab(context, AppRoutes.memberPay)
          : null,
    );
  }

  Widget _skeleton() {
    return ShimmerLoading(
      semanticsLabel: context.l10n.receiptsLoadingSemantics,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.md,
          AppSpacing.screenH,
          AppSpacing.xl,
        ),
        children: [
          for (var i = 0; i < 6; i++) const ShimmerCardSkeleton(height: 72),
        ],
      ),
    );
  }
}

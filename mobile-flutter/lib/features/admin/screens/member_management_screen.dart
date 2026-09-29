import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../l10n/l10n.dart';
import '../utils/admin_format.dart';
import '../widgets/add_member_sheet.dart';
import '../widgets/admin_bottom_nav_bar.dart';

class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  static const int _pageSize = 30;
  static const List<String> _filters = [
    'All',
    'Active',
    'Grace Period',
    'Suspended',
    'Pending',
  ];

  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;

  final List<Map<String, dynamic>> _members = [];
  int _total = 0;
  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _loadingMore = false;
  ApiException? _error;
  ApiException? _moreError;

  String _query = '';
  String _selectedStatusFilter = 'All';

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
      _isLoading = _members.isEmpty;
      _error = null;
      _moreError = null;
    });
    try {
      final res = await _api.getAdminMembersPage(page: 1, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _members
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
          await _api.getAdminMembersPage(page: _page + 1, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        final seen = _members.map(AdminFormat.memberId).toSet();
        for (final m
            in res.items.whereType<Map>().map(Map<String, dynamic>.from)) {
          if (seen.add(AdminFormat.memberId(m))) _members.add(m);
        }
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
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < 400) _loadMore();
  }

  /// A filter can leave too few rows to scroll; keep paging until the
  /// viewport is filled or the directory is exhausted.
  void _maybeFillViewport() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      if (_scroll.position.maxScrollExtent < 200) _loadMore();
    });
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

  /// Filter keys stay English internally; this is what the chip shows.
  String _filterLabel(String key) {
    final l10n = context.l10n;
    return switch (key) {
      'Active' => l10n.membersFilterActive,
      'Grace Period' => l10n.membersFilterGrace,
      'Suspended' => l10n.membersFilterSuspended,
      'Pending' => l10n.membersFilterPending,
      _ => l10n.membersFilterAll,
    };
  }

  bool get _isFiltering => _query.isNotEmpty || _selectedStatusFilter != 'All';

  List<Map<String, dynamic>> get _filteredMembers {
    final q = _query;
    final qDigits = q.replaceAll(RegExp(r'\D'), '');
    return _members.where((m) {
      final bucket = AdminFormat.memberStatus(m['status']?.toString()).bucket;
      if (_selectedStatusFilter != 'All' && bucket != _selectedStatusFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      final name = (m['name'] ?? '').toString().toLowerCase();
      final house = (m['house_name'] ?? '').toString().toLowerCase();
      final code = (m['member_code'] ?? '').toString().toLowerCase();
      final phone = (m['phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
      return name.contains(q) ||
          house.contains(q) ||
          code.contains(q) ||
          (qDigits.length >= 3 && phone.contains(qDigits));
    }).toList();
  }

  /// Bucket counts — only shown once every page is loaded, so the numbers
  /// are never a silent subset of the directory.
  Map<String, int>? get _statusCounts {
    if (_hasMore || _isLoading) return null;
    final counts = {for (final f in _filters) f: 0};
    counts['All'] = _members.length;
    for (final m in _members) {
      final b = AdminFormat.memberStatus(m['status']?.toString()).bucket;
      if (counts.containsKey(b)) counts[b] = counts[b]! + 1;
    }
    return counts;
  }

  Future<void> _openAddMember() async {
    final created = await AddMemberSheet.show(context);
    if (created == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.adminMemberRegistered(
            created['name']?.toString() ?? context.l10n.commonMember)),
        backgroundColor: context.colors.primary,
      ),
    );
    _refresh();
  }

  Future<void> _openMember(Map<String, dynamic> member) async {
    final result = await Navigator.of(context)
        .pushNamed(AppRoutes.adminMemberDetails, arguments: member);
    if (!mounted) return;
    if (result is Map) {
      final updated = Map<String, dynamic>.from(result);
      final id = AdminFormat.memberId(updated);
      final i = _members.indexWhere((m) => AdminFormat.memberId(m) == id);
      if (i >= 0) setState(() => _members[i] = {..._members[i], ...updated});
    }
  }

  String get _subtitle {
    final l10n = context.l10n;
    if (_isLoading) return l10n.membersLoadingDirectory;
    if (_error != null) return l10n.membersDirectoryUnavailable;
    final shown = _filteredMembers.length;
    if (!_isFiltering) {
      return l10n.membersShowingOf(_members.length, _total);
    }
    return _hasMore
        ? l10n.membersMatchesLoaded(shown, _members.length, _total)
        : l10n.membersMatchCount(shown, _total);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filterLabels = [for (final f in _filters) _filterLabel(f)];
    final counts = _statusCounts;
    return AppPageScaffold(
      title: l10n.membersTitle,
      eyebrow: l10n.membersEyebrow,
      subtitle: _subtitle,
      onBack: () => AppNav.adminHome(context),
      actions: [
        AppHeaderIconButton(
          icon: Icons.upload_file_rounded,
          tooltip: l10n.adminBulkImport,
          onTap: () async {
            await Navigator.of(context).pushNamed(AppRoutes.adminImportStep1);
            if (mounted) _refresh();
          },
        ),
      ],
      headerChild: Column(
        children: [
          AppSearchBar(
            controller: _searchController,
            hintText: l10n.membersSearchHint,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
          ),
          const SizedBox(height: AppSpacing.ms),
          AppHeroFilterChips(
            options: filterLabels,
            selected: _filterLabel(_selectedStatusFilter),
            counts: counts == null
                ? null
                : {
                    for (var i = 0; i < _filters.length; i++)
                      filterLabels[i]: counts[_filters[i]] ?? 0,
                  },
            onSelected: (label) {
              final i = filterLabels.indexOf(label);
              setState(
                  () => _selectedStatusFilter = i < 0 ? 'All' : _filters[i]);
              _maybeFillViewport();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMember,
        backgroundColor: context.colors.primary,
        foregroundColor: context.colors.onPrimary,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: Text(
          l10n.adminAddMember,
          style: context.text.buttonSmall.copyWith(color: context.colors.onPrimary),
        ),
      ),
      expandedChild: RefreshIndicator(
        onRefresh: _refresh,
        color: context.colors.primary,
        backgroundColor: context.colors.surface,
        child: _body(),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 1),
    );
  }

  Widget _body() {
    if (_isLoading) return _skeleton();
    if (_error != null) {
      return AppErrorStateView(
        title: context.l10n.membersLoadError,
        description: _error!.userMessage,
        onRetry: _refresh,
      );
    }
    final displayed = _filteredMembers;
    if (displayed.isEmpty && !_hasMore) return _empty();

    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xxl + AppSpacing.xxl,
      ),
      itemCount: displayed.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == displayed.length) return _footer(displayed.isEmpty);
        return _memberCard(displayed[index]);
      },
    );
  }

  Widget _footer(bool noneShown) {
    if (_moreError != null) {
      return AppNoticeCard(
        icon: Icons.cloud_off_rounded,
        title: context.l10n.membersLoadMoreError,
        message: _moreError!.userMessage,
        color: context.colors.error,
        background: context.colors.errorBg,
        actionLabel: context.l10n.adminTryAgain,
        onAction: _loadMore,
      );
    }
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            if (noneShown)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  context.l10n.membersNoMatchesYet(_members.length),
                  textAlign: TextAlign.center,
                  style: context.text.small,
                ),
              ),
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        context.l10n.membersAllLoaded(_total),
        textAlign: TextAlign.center,
        style: context.text.caption,
      ),
    );
  }

  Widget _memberCard(Map<String, dynamic> member) {
    final status = AdminFormat.memberStatus(member['status']?.toString());
    final name = member['name']?.toString() ?? '—';
    final rawPhone = member['phone']?.toString() ?? '';
    final phone = rawPhone.isEmpty ? '' : PhoneFormat.display(rawPhone);
    final house = member['house_name']?.toString() ?? '';
    final dues = AdminFormat.monthlyDues(member);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.ms),
      onTap: () => _openMember(member),
      child: Row(
        children: [
          AppAvatar(name: name, excludeFromSemantics: true),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.listTitle,
                ),
                const SizedBox(height: AppSpacing.xs / 2),
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
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dues == null
                      ? '—'
                      : context.l10n.membersDuesPerMonth(Inr.format(dues)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.listTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                StatusPill(
                  label: status.label,
                  foreground: status.foreground(context),
                  background: status.background(context),
                ),
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

  Widget _empty() {
    final hasQuery = _query.isNotEmpty;
    final l10n = context.l10n;
    if (_members.isEmpty) {
      return EmptyStateView(
        icon: Icons.groups_outlined,
        title: l10n.membersEmptyTitle,
        description: l10n.membersEmptyBody,
        actionLabel: l10n.addMemberTitle,
        onAction: _openAddMember,
      );
    }
    return EmptyStateView(
      icon: Icons.person_search_rounded,
      title: l10n.membersNotFound,
      description: hasQuery
          ? l10n.membersNothingMatches(_searchController.text.trim())
          : l10n.membersNoneInStatus(_filterLabel(_selectedStatusFilter)),
      actionLabel: hasQuery ? l10n.commonClearSearch : l10n.membersShowAll,
      onAction: hasQuery
          ? _clearSearch
          : () => setState(() => _selectedStatusFilter = 'All'),
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
          semanticsLabel: context.l10n.membersLoading,
          child: Column(
            children: [
              for (var i = 0; i < 6; i++) const ShimmerCardSkeleton(height: 76),
            ],
          ),
        ),
      ],
    );
  }
}

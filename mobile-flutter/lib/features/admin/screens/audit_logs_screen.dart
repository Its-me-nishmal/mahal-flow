import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../widgets/admin_bottom_nav_bar.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  static const List<String> _filters = [
    'All',
    'Payment',
    'Member',
    'Alerts',
    'System',
  ];

  String _activeFilter = 'All';
  bool _isLoading = true;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    if (mounted) setState(() => _isLoading = true);
    final data = await _apiService.getAuditLogs();
    if (mounted) {
      setState(() {
        _logs = data;
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(dynamic rawDate) {
    if (rawDate == null) return 'Just now';
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      if (dt.year < 2000) return 'Recent';
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return DateFormat('MMM d · h:mm a').format(dt);
    } catch (_) {
      return 'Recent';
    }
  }

  String _deriveType(dynamic action) {
    final act = action?.toString().toUpperCase() ?? '';
    if (act.contains('PAYMENT') ||
        act.contains('DUES') ||
        act.contains('RECEIPT') ||
        act.contains('DONATION')) {
      return 'Payment';
    }
    if (act.contains('MEMBER') || act.contains('PROFILE')) return 'Member';
    if (act.contains('ALERT') || act.contains('BROADCAST')) return 'Alerts';
    return 'System';
  }

  List<Map<String, dynamic>> get _filteredLogs {
    final query = _searchController.text.trim().toLowerCase();
    return _logs
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .where((l) {
      final type = _deriveType(l["action"]);
      final action = (l["action"] ?? '').toString().toLowerCase();
      final details = (l["details"] ?? '').toString().toLowerCase();
      final actor = (l["actor"] ?? '').toString().toLowerCase();

      final matchesType = _activeFilter == 'All' || type == _activeFilter;
      final matchesQuery = query.isEmpty ||
          action.contains(query) ||
          details.contains(query) ||
          actor.contains(query);

      return matchesType && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayed = _filteredLogs;

    return AppPageScaffold(
      title: 'Audit log',
      eyebrow: 'Committee',
      subtitle: _isLoading
          ? 'Loading the log…'
          : '${displayed.length} recorded actions',
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        }
      },
      actions: [
        AppHeaderIconButton(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh',
          onTap: _loadLogs,
        ),
      ],
      headerChild: Column(
        children: [
          AppSearchBar(
            controller: _searchController,
            hintText: 'Search action, actor or details…',
          ),
          const SizedBox(height: AppSpacing.ms),
          AppHeroFilterChips(
            options: _filters,
            selected: _activeFilter,
            onSelected: (val) => setState(() => _activeFilter = val),
          ),
        ],
      ),
      expandedChild: RefreshIndicator(
        onRefresh: _loadLogs,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: _isLoading
            ? _skeleton()
            : displayed.isEmpty
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      AppSpacing.md,
                      AppSpacing.screenH,
                      AppSpacing.xl,
                    ),
                    itemCount: displayed.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final log = displayed[index];
                      return _logEntry(log, _deriveType(log["action"]));
                    },
                  ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 3),
    );
  }

  Widget _logEntry(Map<String, dynamic> log, String type) {
    late final Color typeColor;
    late final Color typeBg;
    late final IconData typeIcon;

    switch (type) {
      case 'Payment':
        typeColor = AppColors.success;
        typeBg = AppColors.successBg;
        typeIcon = Icons.payments_outlined;
      case 'Member':
        typeColor = AppColors.info;
        typeBg = AppColors.infoBg;
        typeIcon = Icons.person_outline_rounded;
      case 'Alerts':
        typeColor = AppColors.warning;
        typeBg = AppColors.warningBg;
        typeIcon = Icons.campaign_outlined;
      default:
        typeColor = AppColors.textSecondary;
        typeBg = AppColors.neutralBg;
        typeIcon = Icons.settings_outlined;
    }

    final action = log["action"]?.toString() ?? 'SYSTEM_ACTION';
    final details = log["details"]?.toString() ?? action;
    final actor = log["actor"]?.toString() ?? 'System';
    final timeStr = _formatTimestamp(log["created_at"] ?? log["timestamp"]);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md - 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconChip(
            icon: typeIcon,
            color: typeColor,
            background: typeBg,
            size: 38,
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusPill(
                      label: type,
                      foreground: typeColor,
                      background: typeBg,
                    ),
                    const Spacer(),
                    Text(
                      timeStr,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  details,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text('By $actor', style: AppTextStyles.small),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    final hasQuery = _searchController.text.isNotEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.06),
        EmptyStateView(
          icon: Icons.history_rounded,
          title: 'No entries',
          description: hasQuery
              ? "Nothing matches '${_searchController.text}'."
              : "No '$_activeFilter' actions have been recorded yet.",
        ),
      ],
    );
  }

  Widget _skeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.xl,
      ),
      children: [
        for (var i = 0; i < 6; i++)
          const ShimmerLoading(child: ShimmerCardSkeleton(height: 80)),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'alert_details_screen.dart';

class _AlertData {
  final String id;
  final String title;
  final String body;
  final String time;
  bool unread;
  final _AlertType type;

  _AlertData({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.unread = false,
    this.type = _AlertType.system,
  });
}

enum _AlertType { payment, overdue, success, system, default_ }

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ApiService _apiService = ApiService();
  static const List<String> _filters = ['All', 'Unread', 'Payment', 'System'];

  String _selectedFilter = 'All';
  List<_AlertData> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
    PushNotificationService.instance.inboxChanged.addListener(_onPush);
  }

  @override
  void dispose() {
    PushNotificationService.instance.inboxChanged.removeListener(_onPush);
    super.dispose();
  }

  // A notice pushed while this screen is open should appear without a pull.
  void _onPush() {
    if (!_isLoading) _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    if (mounted) setState(() => _isLoading = true);
    final rawList = await _apiService.getAlerts();

    List<_AlertData> loaded = [];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        final id = item["id"]?.toString() ?? item["_id"]?.toString() ?? "ALT_00";
        final title = item["title"]?.toString() ?? "Notice";
        final body = item["description"]?.toString() ??
            item["message"]?.toString() ??
            item["details"]?.toString() ??
            "";
        final status = item["status"]?.toString() ?? "ACTIVE";
        final severity = item["severity"]?.toString() ?? "INFO";

        String timeStr = "Recent";
        final rawDate = item["created_at"]?.toString();
        if (rawDate != null) {
          final parsed = DateTime.tryParse(rawDate);
          if (parsed != null) {
            final diff = DateTime.now().difference(parsed);
            if (diff.inMinutes < 60) {
              timeStr = "${diff.inMinutes}m ago";
            } else if (diff.inHours < 24) {
              timeStr = "${diff.inHours}h ago";
            } else {
              timeStr = "${diff.inDays}d ago";
            }
          }
        }

        _AlertType aType = _AlertType.system;
        if (severity == "WARNING" || severity == "ERROR") {
          aType = _AlertType.overdue;
        } else if (severity == "SUCCESS") {
          aType = _AlertType.success;
        } else if (title.toLowerCase().contains("payment") ||
            title.toLowerCase().contains("due")) {
          aType = _AlertType.payment;
        }

        loaded.add(
          _AlertData(
            id: id,
            title: title,
            body: body,
            time: timeStr,
            unread: status == "ACTIVE",
            type: aType,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _alerts = loaded;
        _isLoading = false;
      });
    }
  }

  List<_AlertData> get _filteredAlerts {
    switch (_selectedFilter) {
      case 'Unread':
        return _alerts.where((a) => a.unread).toList();
      case 'Payment':
        return _alerts
            .where((a) =>
                a.type == _AlertType.payment || a.type == _AlertType.overdue)
            .toList();
      case 'System':
        return _alerts
            .where((a) =>
                a.type == _AlertType.system || a.type == _AlertType.default_)
            .toList();
      default:
        return _alerts;
    }
  }

  int get _unreadCount => _alerts.where((a) => a.unread).length;

  Future<void> _markAsRead(_AlertData alert) async {
    if (mounted) setState(() => alert.unread = false);
    await _apiService.acknowledgeAlert(alert.id);
  }

  Future<void> _markAllAsRead() async {
    if (mounted) {
      setState(() {
        for (var a in _alerts) {
          a.unread = false;
        }
      });
    }
    await _apiService.markAllAlertsRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notices marked as read')),
      );
    }
  }

  Future<void> _clearAllAlerts() async {
    final confirmed = await AppBottomSheet.showConfirmation(
      context: context,
      title: 'Clear all notices?',
      message: 'This removes every notice from your inbox. It cannot be undone.',
      confirmLabel: 'Clear All',
      confirmColor: AppColors.error,
      icon: Icons.delete_sweep_rounded,
    );

    if (confirmed != true) return;
    if (mounted) setState(() => _alerts.clear());
    await _apiService.clearAllAlerts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notices cleared')),
      );
    }
  }

  Future<void> _removeAlert(int index, _AlertData alert) async {
    if (mounted) {
      setState(() => _alerts.removeWhere((item) => item.id == alert.id));
    }

    await _apiService.dismissAlert(alert.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cleared: ${alert.title}'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () {
              if (mounted) {
                setState(() {
                  _alerts.insert(
                    index < _alerts.length ? index : _alerts.length,
                    alert,
                  );
                });
              }
            },
          ),
        ),
      );
    }
  }

  void _openAlert(_AlertData alert) {
    _markAsRead(alert);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlertDetailsScreen(
          title: alert.title,
          body: alert.body,
          time: alert.time,
          type: _mapType(alert.type),
        ),
      ),
    );
  }

  AlertType _mapType(_AlertType type) {
    switch (type) {
      case _AlertType.payment:
        return AlertType.payment;
      case _AlertType.overdue:
        return AlertType.overdue;
      case _AlertType.success:
        return AlertType.success;
      case _AlertType.system:
        return AlertType.system;
      case _AlertType.default_:
        return AlertType.default_;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _filteredAlerts;

    return AppPageScaffold(
      title: 'Notices',
      eyebrow: 'From the committee',
      subtitle: _isLoading
          ? 'Loading your notices…'
          : _unreadCount == 0
              ? 'You are all caught up.'
              : '$_unreadCount unread',
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/member/dashboard');
        }
      },
      actions: [
        if (_alerts.isNotEmpty) ...[
          AppHeaderIconButton(
            icon: Icons.done_all_rounded,
            tooltip: 'Mark all as read',
            onTap: _markAllAsRead,
          ),
          AppHeaderIconButton(
            icon: Icons.delete_sweep_outlined,
            tooltip: 'Clear all notices',
            onTap: _clearAllAlerts,
          ),
        ],
      ],
      headerChild: AppHeroFilterChips(
        options: _filters,
        selected: _selectedFilter,
        onSelected: (f) => setState(() => _selectedFilter = f),
      ),
      expandedChild: RefreshIndicator(
        onRefresh: _loadAlerts,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: _isLoading
            ? _skeleton()
            : alerts.isEmpty
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenH,
                      AppSpacing.md,
                      AppSpacing.screenH,
                      AppSpacing.xl,
                    ),
                    itemCount: alerts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return Dismissible(
                        key: Key(alert.id),
                        direction: DismissDirection.horizontal,
                        background: _dismissBackground(Alignment.centerLeft),
                        secondaryBackground:
                            _dismissBackground(Alignment.centerRight),
                        onDismissed: (_) => _removeAlert(index, alert),
                        child: _alertCard(alert),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: const MemberBottomNavBar(currentIndex: 3),
    );
  }

  Widget _dismissBackground(Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
    );
  }

  Widget _alertCard(_AlertData alert) {
    final visual = _visualFor(alert.type);

    return AppCard(
      onTap: () => _openAlert(alert),
      padding: const EdgeInsets.all(AppSpacing.md - 2),
      color: alert.unread ? AppColors.surface : AppColors.surface,
      borderColor: alert.unread
          ? visual.color.withValues(alpha: 0.35)
          : AppColors.border,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconChip(
            icon: visual.icon,
            color: visual.color,
            background: visual.background,
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(
                          fontSize: 15,
                          fontWeight:
                              alert.unread ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      alert.time,
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                if (alert.body.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    alert.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.small,
                  ),
                ],
                if (alert.unread) ...[
                  const SizedBox(height: AppSpacing.sm),
                  StatusPill(
                    label: 'Unread',
                    foreground: visual.color,
                    background: visual.background,
                    icon: Icons.fiber_manual_record_rounded,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _AlertVisual _visualFor(_AlertType type) {
    switch (type) {
      case _AlertType.payment:
        return const _AlertVisual(
          Icons.payments_outlined,
          AppColors.info,
          AppColors.infoBg,
        );
      case _AlertType.overdue:
        return const _AlertVisual(
          Icons.error_outline_rounded,
          AppColors.error,
          AppColors.errorBg,
        );
      case _AlertType.success:
        return const _AlertVisual(
          Icons.check_circle_outline_rounded,
          AppColors.success,
          AppColors.successBg,
        );
      case _AlertType.system:
      case _AlertType.default_:
        return const _AlertVisual(
          Icons.campaign_outlined,
          AppColors.warning,
          AppColors.warningBg,
        );
    }
  }

  Widget _empty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.08),
        EmptyStateView(
          icon: Icons.campaign_outlined,
          title: _selectedFilter == 'All' ? 'No notices' : 'Nothing here',
          description: _selectedFilter == 'All'
              ? 'Announcements and dues reminders from the committee appear here.'
              : 'Try another filter, or pull down to refresh.',
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
        for (var i = 0; i < 5; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: ShimmerLoading(child: ShimmerCardSkeleton(height: 84)),
          ),
      ],
    );
  }
}

class _AlertVisual {
  final IconData icon;
  final Color color;
  final Color background;

  const _AlertVisual(this.icon, this.color, this.background);
}

import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../l10n/l10n.dart';
import 'alert_details_screen.dart';

class _AlertData {
  final String id;
  final String title;
  final String body;
  final DateTime? createdAt;
  bool unread;
  final AlertType type;

  _AlertData({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.unread,
    required this.type,
  });

  String get time => AppDate.relative(createdAt, fallback: '');
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ApiService _apiService = ApiService();
  // Internal filter keys; [_filterLabel] gives the display text.
  static const List<String> _filters = ['All', 'Unread', 'Payment', 'System'];

  String _filterLabel(String key) {
    final l10n = context.l10n;
    switch (key) {
      case 'Unread':
        return l10n.alertsFilterUnread;
      case 'Payment':
        return l10n.alertsFilterPayment;
      case 'System':
        return l10n.alertsFilterSystem;
      default:
        return l10n.alertsFilterAll;
    }
  }

  String _selectedFilter = 'All';
  List<_AlertData> _alerts = [];
  bool _isLoading = true;
  ApiException? _error;

  /// Alerts swiped away whose DELETE is waiting for the Undo snackbar to
  /// close. Hidden from the list; re-fetches must not bring them back.
  final Set<String> _pendingDismiss = {};

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
    final firstLoad = _alerts.isEmpty && _error == null;
    if (mounted && (firstLoad || _error != null)) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    final fallbackTitle = context.l10n.alertNotice;
    try {
      final rawList = await _apiService.getAlertsOrThrow();
      final loaded = <_AlertData>[];
      for (final item in rawList) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        final id = (map["id"] ?? map["_id"])?.toString() ?? '';
        // Without an id an alert can't be read, dismissed or keyed.
        if (id.isEmpty || _pendingDismiss.contains(id)) continue;
        loaded.add(
          _AlertData(
            id: id,
            title: map["title"]?.toString() ?? fallbackTitle,
            body: map["description"]?.toString() ??
                map["message"]?.toString() ??
                map["details"]?.toString() ??
                "",
            createdAt: AppDate.tryParse(map["created_at"]),
            unread: (map["status"]?.toString() ?? "ACTIVE") == "ACTIVE",
            type: alertTypeFromApi(map),
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _alerts = loaded;
        _error = null;
        _isLoading = false;
      });
      _syncBadge();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (_alerts.isEmpty) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _snack(context.l10n.dashboardRefreshFailed(e.userMessage));
      }
    }
  }

  /// Keep the shared badge equal to what this screen shows.
  void _syncBadge() {
    ApiService.unreadAlertsCount.value = _alerts.where((a) => a.unread).length;
  }

  void _snack(String message, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  bool _isPaymentType(AlertType t) =>
      t == AlertType.payment ||
      t == AlertType.overdue ||
      t == AlertType.success;

  List<_AlertData> get _filteredAlerts {
    switch (_selectedFilter) {
      case 'Unread':
        return _alerts.where((a) => a.unread).toList();
      case 'Payment':
        return _alerts.where((a) => _isPaymentType(a.type)).toList();
      case 'System':
        return _alerts.where((a) => !_isPaymentType(a.type)).toList();
      default:
        return _alerts;
    }
  }

  int get _unreadCount => _alerts.where((a) => a.unread).length;

  Future<void> _markAsRead(_AlertData alert) async {
    if (!alert.unread) return;
    setState(() => alert.unread = false);
    final ok = await _apiService.acknowledgeAlert(alert.id, wasUnread: true);
    if (ok || !mounted) return;
    // Roll back: the server still has it unread.
    setState(() => alert.unread = true);
    _syncBadge();
  }

  Future<void> _markAllAsRead() async {
    final wasUnread = _alerts.where((a) => a.unread).toList();
    if (wasUnread.isEmpty) {
      _snack(context.l10n.alertsAlreadyRead);
      return;
    }
    setState(() {
      for (final a in wasUnread) {
        a.unread = false;
      }
    });
    final ok = await _apiService.markAllAlertsRead();
    if (!mounted) return;
    if (ok) {
      _snack(context.l10n.alertsMarkedAllRead);
    } else {
      setState(() {
        for (final a in wasUnread) {
          a.unread = true;
        }
      });
      _syncBadge();
      _snack(context.l10n.alertsMarkReadFailed);
    }
  }

  Future<void> _clearAllAlerts() async {
    final confirmed = await AppBottomSheet.showConfirmation(
      context: context,
      title: context.l10n.alertsClearTitle,
      message: context.l10n.alertsClearMessage,
      confirmLabel: context.l10n.alertsClearConfirm,
      destructive: true,
      icon: Icons.delete_sweep_rounded,
    );
    if (confirmed != true || !mounted) return;

    final previous = List<_AlertData>.of(_alerts);
    setState(() => _alerts = []);
    final ok = await _apiService.clearAllAlerts();
    if (!mounted) return;
    if (ok) {
      _snack(context.l10n.alertsCleared);
    } else {
      setState(() => _alerts = previous);
      _syncBadge();
      _snack(context.l10n.alertsClearFailed);
    }
  }

  /// Swipe-to-dismiss. The notice disappears at once, but the DELETE is only
  /// sent once the Undo snackbar has closed without Undo being tapped.
  void _removeAlert(_AlertData alert) {
    final originalIndex = _alerts.indexOf(alert);
    if (originalIndex < 0) return;
    _pendingDismiss.add(alert.id);
    setState(() => _alerts.removeAt(originalIndex));

    void restore() {
      _pendingDismiss.remove(alert.id);
      if (!mounted) return;
      setState(() {
        _alerts.insert(originalIndex.clamp(0, _alerts.length), alert);
      });
    }

    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.alertsClearedOne(alert.title)),
        action: SnackBarAction(
          label: l10n.commonUndo,
          onPressed: () {},
        ),
      ),
    );
    controller.closed.then((reason) async {
      if (reason == SnackBarClosedReason.action) {
        restore();
        return;
      }
      final ok =
          await _apiService.dismissAlert(alert.id, wasUnread: alert.unread);
      if (ok) {
        _pendingDismiss.remove(alert.id);
        return;
      }
      if (alert.unread) {
        // dismissAlert already dropped the badge; put it back.
        ApiService.unreadAlertsCount.value++;
      }
      restore();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.alertsRemoveFailed)),
        );
      }
    });
  }

  Future<void> _openAlert(_AlertData alert) async {
    _markAsRead(alert);
    await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.memberAlertDetails),
        builder: (_) => AlertDetailsScreen(
          title: alert.title,
          body: alert.body,
          time: AppDate.formatDateTime(alert.createdAt, fallback: ''),
          type: alert.type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _filteredAlerts;

    Widget body;
    if (_isLoading) {
      body = _skeleton();
    } else if (_error != null) {
      body = AppErrorStateView(
        title: context.l10n.alertsLoadError,
        description: _error!.userMessage,
        onRetry: _loadAlerts,
      );
    } else if (alerts.isEmpty) {
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
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final alert = alerts[index];
          return Dismissible(
            key: ValueKey('alert-${alert.id}'),
            direction: DismissDirection.horizontal,
            background: _dismissBackground(Alignment.centerLeft),
            secondaryBackground: _dismissBackground(Alignment.centerRight),
            onDismissed: (_) => _removeAlert(alert),
            child: _alertCard(alert),
          );
        },
      );
    }

    return AppPageScaffold(
      title: context.l10n.alertsTitle,
      eyebrow: context.l10n.alertsEyebrow,
      subtitle: _isLoading
          ? context.l10n.alertsLoadingSubtitle
          : _error != null
              ? context.l10n.alertsErrorSubtitle
              : _unreadCount == 0
                  ? context.l10n.alertsCaughtUp
                  : context.l10n.alertsUnreadCount(_unreadCount),
      onBack: () => AppNav.memberHome(context),
      actions: [
        if (_alerts.isNotEmpty) ...[
          AppHeaderIconButton(
            icon: Icons.done_all_rounded,
            tooltip: context.l10n.alertsMarkAllRead,
            onTap: _unreadCount == 0 ? null : _markAllAsRead,
          ),
          AppHeaderIconButton(
            icon: Icons.delete_sweep_outlined,
            tooltip: context.l10n.alertsClearAllTooltip,
            onTap: _clearAllAlerts,
          ),
        ],
      ],
      headerChild: AppHeroFilterChips(
        // Chips show translated labels; state keeps the internal key.
        options: [for (final f in _filters) _filterLabel(f)],
        selected: _filterLabel(_selectedFilter),
        onSelected: (label) => setState(() {
          _selectedFilter = _filters.firstWhere(
            (f) => _filterLabel(f) == label,
            orElse: () => 'All',
          );
        }),
      ),
      expandedChild: RefreshIndicator(
        onRefresh: _loadAlerts,
        color: context.colors.primary,
        backgroundColor: context.colors.surface,
        child: body,
      ),
      bottomNavigationBar: const MemberBottomNavBar(currentIndex: 3),
    );
  }

  Widget _dismissBackground(Alignment alignment) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.error,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Icon(
        Icons.delete_outline_rounded,
        color: context.colors.onPrimary,
        semanticLabel: context.l10n.commonRemove,
      ),
    );
  }

  Widget _alertCard(_AlertData alert) {
    final visual = AlertVisual.of(context, alert.type);

    return Semantics(
      label: alert.unread ? context.l10n.alertsUnreadSemantics : null,
      child: AppCard(
        onTap: () => _openAlert(alert),
        padding: const EdgeInsets.all(AppSpacing.ms),
        color: alert.unread ? context.colors.primaryLight : context.colors.surface,
        borderColor: alert.unread
            ? context.colors.primary.withValues(alpha: 0.22)
            : context.colors.border,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconChip(
              icon: visual.icon,
              color: visual.color,
              background: alert.unread ? context.colors.surface : visual.background,
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (alert.unread)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xs + 2,
                            right: AppSpacing.xs + 2,
                          ),
                          child: Container(
                            width: AppSpacing.sm,
                            height: AppSpacing.sm,
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          alert.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.listTitle.copyWith(
                            fontWeight: alert.unread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (alert.time.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          alert.time,
                          style: context.text.small.copyWith(
                            color: context.colors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (alert.body.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      alert.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.small,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return EmptyStateView(
      icon: Icons.campaign_outlined,
      title: _selectedFilter == 'All'
          ? context.l10n.alertsEmptyTitle
          : context.l10n.alertsEmptyFilteredTitle,
      description: _selectedFilter == 'All'
          ? context.l10n.alertsEmptyBody
          : context.l10n.alertsEmptyFilteredBody,
    );
  }

  Widget _skeleton() {
    return ShimmerLoading(
      semanticsLabel: context.l10n.alertsLoadingSemantics,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.md,
          AppSpacing.screenH,
          AppSpacing.xl,
        ),
        children: [
          for (var i = 0; i < 5; i++) const ShimmerCardSkeleton(height: 84),
        ],
      ),
    );
  }
}

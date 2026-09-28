import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../l10n/l10n.dart';
import '../data/admin_context.dart';
import '../widgets/add_member_sheet.dart';
import '../widgets/admin_bottom_nav_bar.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/broadcast_sheet.dart';
import '../widgets/dashboard_cards.dart';
import '../widgets/receipt_sheet.dart';
import '../widgets/record_payment_sheet.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ApiService _api = ApiService();

  AdminDashboardStats? _stats;
  ApiException? _statsError;

  List<Map<String, dynamic>>? _payments;
  ApiException? _paymentsError;
  Map<String, String> _names = const {};

  @override
  void initState() {
    super.initState();
    PushNotificationService.instance.markSessionReady();
    AdminContext.loadMahal();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadStats(),
      _loadPayments(),
      AdminContext.refreshPendingCount(),
      if (AdminContext.mahal.value == null) AdminContext.loadMahal(),
    ]);
  }

  Future<void> _loadStats() async {
    try {
      final d = await _api.getAdminDashboardOrThrow();
      if (!mounted) return;
      setState(() {
        _stats = AdminDashboardStats.fromJson(d);
        _statsError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _statsError = e);
    }
  }

  Future<void> _loadPayments() async {
    try {
      final page = await _api.getAdminPayments(page: 1, limit: 5);
      final names = await AdminContext.memberNames();
      if (!mounted) return;
      setState(() {
        _payments =
            page.items.whereType<Map>().map(Map<String, dynamic>.from).toList();
        _names = names;
        _paymentsError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _paymentsError = e);
    }
  }

  void _retryStats() {
    setState(() {
      _statsError = null;
      _stats = null;
    });
    _loadStats();
  }

  void _retryPayments() {
    setState(() {
      _paymentsError = null;
      _payments = null;
    });
    _loadPayments();
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  Future<void> _addMember() async {
    final created = await AddMemberSheet.show(context);
    if (created == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.adminMemberRegistered(
            '${created['name'] ?? context.l10n.commonMember}')),
        backgroundColor: context.colors.primary,
        action: SnackBarAction(
          label: context.l10n.commonView,
          textColor: context.colors.onPrimary,
          onPressed: () => Navigator.of(context)
              .pushNamed(AppRoutes.adminMemberDetails, arguments: created),
        ),
      ),
    );
    _loadStats();
  }

  Future<void> _recordPayment() async {
    final res = await RecordPaymentSheet.show(context);
    if (res == null || !mounted) return;
    final receipt = Map<String, dynamic>.from(res['receipt'] as Map);
    final number = receipt['receipt_number']?.toString() ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.adminDashRecordedFor(
            Inr.formatAny(receipt['amount'] ?? res['amount']),
            '${receipt['member_name'] ?? context.l10n.adminDashTheMember}',
          ),
        ),
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
    _loadAll();
  }

  Future<void> _broadcast() async {
    final sent = await BroadcastSheet.show(
      context,
      totalMembers: _stats?.totalMembers,
      pendingMembers: _stats?.pendingMembers,
    );
    if (sent != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.adminDashNoticeSent),
        backgroundColor: context.colors.primary,
      ),
    );
  }

  void _tab(String route) => AppNav.switchAdminTab(context, route);

  Future<void> _openPendingApprovals() async {
    await Navigator.of(context).pushNamed(AppRoutes.adminPendingApprovals);
    AdminContext.refreshPendingCount();
    if (mounted) _loadStats();
  }

  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: AdminContext.mahal,
      builder: (context, _, __) => AppPageScaffold(
        scaffoldKey: _scaffoldKey,
        drawer: AdminDrawer(
          onBroadcast: _broadcast,
          onSignOut: () => AdminDrawer.confirmSignOut(context),
        ),
        title: l10n.adminDashTitle,
        eyebrow: l10n.adminCommitteeEyebrow,
        subtitle: AdminContext.mahalName == null
            ? l10n.adminDashLiveLedger
            : l10n.adminDashMahalLiveLedger(AdminContext.mahalName!),
        leading: AppHeaderIconButton(
          icon: Icons.menu_rounded,
          tooltip: l10n.adminMenu,
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        onRefresh: _loadAll,
        floatingChild:
            _statsError == null ? CollectionCard(stats: _stats) : null,
        content: [
          const SizedBox(height: AppSpacing.md),
          if (_statsError != null) ...[
            AppCard(
              child: AppErrorStateView(
                title: l10n.adminDashLoadError,
                description: _statsError!.userMessage,
                onRetry: _retryStats,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          _quickActions(),
          if (_statsError == null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppSectionHeader(title: l10n.adminDashOverview),
            DashboardStatGrid(
              stats: _stats,
              onReports: () => _tab(AppRoutes.adminReports),
              onMembers: () => _tab(AppRoutes.adminMembers),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: l10n.adminDashRecentTransactions,
            actionLabel: l10n.adminViewAll,
            onAction: () => _tab(AppRoutes.adminReports),
          ),
          RecentTransactionsCard(
            payments: _payments,
            error: _paymentsError,
            memberNames: _names,
            onRetry: _retryPayments,
            onOpenReceipt: (n) => ReceiptSheet.show(context, n),
          ),
          const SizedBox(height: AppSpacing.lg),
          BroadcastCard(onCompose: _broadcast),
        ],
        bottomNavigationBar: const AdminBottomNavBar(currentIndex: 0),
      ),
    );
  }

  Widget _quickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppSecondaryButton(
                label: context.l10n.adminAddMember,
                icon: Icons.person_add_alt_outlined,
                height: AppSizes.buttonHeightCompact,
                onPressed: _addMember,
              ),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: AppPrimaryButton(
                label: context.l10n.adminRecordPayment,
                height: AppSizes.buttonHeightCompact,
                onPressed: _recordPayment,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.ms),
        ValueListenableBuilder<int?>(
          valueListenable: AdminContext.pendingCount,
          builder: (context, count, _) => AppSecondaryButton(
            label: (count != null && count > 0)
                ? context.l10n.adminDashPendingApprovalsWaiting(count)
                : context.l10n.adminPendingApprovals,
            icon: Icons.how_to_reg_outlined,
            color: (count != null && count > 0)
                ? context.colors.warning
                : context.colors.primary,
            height: AppSizes.buttonHeightCompact,
            onPressed: _openPendingApprovals,
          ),
        ),
      ],
    );
  }
}

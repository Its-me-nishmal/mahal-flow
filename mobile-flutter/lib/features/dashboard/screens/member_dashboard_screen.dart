import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_service.dart';
import '../../../core/storage/autopay_local_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/dues_period.dart';
import '../../../core/widgets/app_error_state_view.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';
import '../../receipts/screens/receipt_details_screen.dart';
import '../widgets/member_dashboard_widgets.dart';

enum _DashboardStatus { loading, ready, error }

/// Immutable view model for the member home.
class MemberDashboardData {
  final String memberId;
  final String firstName;
  final String mahalName;
  final double outstanding;
  final double advanceCredit;
  final String? lastPaidMonth;
  final Map<String, dynamic>? latestPayment;

  const MemberDashboardData({
    required this.memberId,
    required this.firstName,
    required this.mahalName,
    required this.outstanding,
    required this.advanceCredit,
    required this.lastPaidMonth,
    required this.latestPayment,
  });

  factory MemberDashboardData.fromJson(Map<String, dynamic> json) {
    final memberId = json['member_id']?.toString() ?? '';
    final fullName = json['member_name']?.toString() ?? 'Member';
    final rawOutstanding = (json['outstanding_balance'] as num?)?.toDouble() ?? 0;

    // GetLatestReceipt in the Go repository filters on mahal_id only, so this
    // payload can carry another member's receipt. Drop anything that is not
    // ours rather than show one member another member's payment.
    var latest = json['latest_payment'] as Map<String, dynamic>?;
    final latestOwner = latest?['member_id']?.toString();
    if (latest != null &&
        latestOwner != null &&
        memberId.isNotEmpty &&
        latestOwner != memberId) {
      latest = null;
    }

    return MemberDashboardData(
      memberId: memberId,
      firstName: fullName.split(' ').first,
      mahalName: json['mahal_name']?.toString() ?? 'Your Mahal',
      outstanding: rawOutstanding > 0 ? rawOutstanding : 0,
      advanceCredit: (json['advance_credit'] as num?)?.toDouble() ?? 0,
      lastPaidMonth: json['last_paid_month']?.toString(),
      latestPayment: latest,
    );
  }

  bool get isUpToDate => outstanding <= 0;
}

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  final ApiService _apiService = ApiService();

  _DashboardStatus _status = _DashboardStatus.loading;
  MemberDashboardData? _data;
  bool _autoPayEnabled = true; // assume on until the local flag is read
  int _unreadAlerts = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool isRefresh = false}) async {
    if (!isRefresh) setState(() => _status = _DashboardStatus.loading);

    final results = await Future.wait([
      _apiService.getMemberDashboard(),
      _apiService.getAlerts(),
    ]);
    if (!mounted) return;

    final payload = results[0] as Map<String, dynamic>?;

    if (payload == null) {
      // Never blank out financial data the member is already looking at.
      if (isRefresh && _data != null) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't refresh. Showing your last known balance."),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        setState(() => _status = _DashboardStatus.error);
      }
      return;
    }

    final data = MemberDashboardData.fromJson(payload);
    final autoPay = await AutoPayLocalStore.isEnabled(data.memberId);
    if (!mounted) return;

    setState(() {
      _data = data;
      _autoPayEnabled = autoPay;
      _unreadAlerts = ApiService.unreadAlertsCount.value;
      _status = _DashboardStatus.ready;
    });
  }

  Future<void> _openRoute(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) _loadDashboardData(isRefresh: true);
  }

  Future<void> _openAutoPaySetup() async {
    final result = await Navigator.of(context).pushNamed('/member/setup-autopay');
    if (!mounted) return;
    if (result == true) {
      await AutoPayLocalStore.setEnabled(_data?.memberId ?? '', true);
      if (!mounted) return;
      setState(() => _autoPayEnabled = true);
    }
    _loadDashboardData(isRefresh: true);
  }

  void _openLatestReceipt() {
    final receipt = _data?.latestPayment;
    if (receipt == null) return;

    final isDues = receipt['payment_type']?.toString() == 'MONTHLY_DUES';
    final paidMonths =
        (receipt['paid_months'] as List?)?.map((m) => m.toString()).toList() ??
            const <String>[];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReceiptDetailsScreen(
          title: isDues ? 'Monthly Dues' : 'Mahal Contribution',
          subtitle: DuesPeriod.paidMonthsLabel(paidMonths),
          amount: '₹${(receipt['amount'] as num?)?.toInt() ?? 0}',
          status: receipt['status']?.toString() ?? 'SUCCESS',
          receiptNumber: receipt['receipt_number']?.toString() ?? '—',
          memberName: receipt['member_name']?.toString() ??
              _data?.firstName ??
              'Member',
          date: receipt['created_at']?.toString() ?? '',
          paymentMethod: receipt['gateway']?.toString() ?? 'UPI',
        ),
      ),
    );
  }

  /// The API returns names in mixed case ("aslam"); the hero shows a proper
  /// capitalised first name.
  String get _displayName {
    final raw = _data?.firstName ??
        ApiService.cachedMemberName.split(' ').first;
    if (raw.isEmpty) return 'Member';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Need help? Contact your Mahal Committee office.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    // Gradient runs past the hero content so the balance card floats over it.
    // Scales with the system text size so large type cannot outgrow it.
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6);
    final gradientHeight = topPad + 212 * textScale;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: gradientHeight,
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.hero),
              ),
            ),
            RefreshIndicator(
              onRefresh: () => _loadDashboardData(isRefresh: true),
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              edgeOffset: topPad + 72,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardHero(
                      firstName: _displayName,
                      mahalName: _data?.mahalName ?? 'Loading your Mahal…',
                      onAvatarTap: () => _openRoute('/member/profile'),
                      onHelpTap: _showHelp,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenH,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: KeyedSubtree(
                          key: ValueKey(_status),
                          child: _buildBody(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const MemberBottomNavBar(currentIndex: 0),
      ),
    );
  }

  Widget _buildBody() {
    switch (_status) {
      case _DashboardStatus.loading:
        return const MemberDashboardSkeleton();
      case _DashboardStatus.error:
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xl),
          child: AppErrorStateView(
            description:
                "We couldn't load your dues. Check your connection and try again.",
            onRetry: _loadDashboardData,
          ),
        );
      case _DashboardStatus.ready:
        return _buildContent(_data!);
    }
  }

  Widget _buildContent(MemberDashboardData data) {
    final months = DuesPeriod.unpaidMonths(data.lastPaidMonth);
    final lastPaid = DuesPeriod.parseMonthKey(data.lastPaidMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BalanceCard(
          outstanding: data.outstanding,
          advanceCredit: data.advanceCredit,
          pendingSummary: DuesPeriod.pendingSummary(data.lastPaidMonth),
          months: months,
          paidUpToLabel:
              lastPaid == null ? null : DueMonth(lastPaid, DueMonthStatus.overdue).longLabel,
          onPayDues: () => _openRoute('/member/pay'),
          onContribute: () => _openRoute('/member/contribution'),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildQuickActions(),
        const SizedBox(height: AppSpacing.md),
        LatestPaymentCard(
          receipt: data.latestPayment,
          isUpToDate: data.isUpToDate,
          onViewReceipt: _openLatestReceipt,
          onPrimaryAction: () => _openRoute(
            data.isUpToDate ? '/member/contribution' : '/member/pay',
          ),
        ),
        if (!_autoPayEnabled) ...[
          const SizedBox(height: AppSpacing.md),
          AutoPayNudgeCard(onSetUp: _openAutoPaySetup),
        ],
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: QuickActionTile(
                  icon: Icons.volunteer_activism_outlined,
                  iconColor: AppColors.warning,
                  iconBackground: AppColors.warningBg,
                  label: 'Contribute',
                  caption: 'Zakat and general fund',
                  onTap: () => _openRoute('/member/contribution'),
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: QuickActionTile(
                  icon: Icons.receipt_long_outlined,
                  iconColor: AppColors.info,
                  iconBackground: AppColors.infoBg,
                  label: 'Receipts',
                  caption: 'All past payments',
                  onTap: () => _openRoute('/member/receipts'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.ms),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: QuickActionTile(
                  icon: Icons.campaign_outlined,
                  iconColor: AppColors.success,
                  iconBackground: AppColors.successBg,
                  label: 'Notices',
                  caption: 'From the committee',
                  badgeCount: _unreadAlerts,
                  onTap: () => _openRoute('/member/alerts'),
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: QuickActionTile(
                  icon: Icons.person_outline_rounded,
                  iconColor: AppColors.textSecondary,
                  iconBackground: AppColors.neutralBg,
                  label: 'Profile',
                  caption: 'Details and settings',
                  onTap: () => _openRoute('/member/profile'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

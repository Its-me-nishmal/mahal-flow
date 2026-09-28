import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/dues_period.dart';
import '../../../core/widgets/app_error_state_view.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';
import '../../../l10n/l10n.dart';
import '../../profile/widgets/member_help_sheet.dart';
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

  /// The raw payload, for optional fields (e.g. an office phone for Help).
  final Map<String, dynamic> raw;

  const MemberDashboardData({
    required this.memberId,
    required this.firstName,
    required this.mahalName,
    required this.outstanding,
    required this.advanceCredit,
    required this.lastPaidMonth,
    required this.latestPayment,
    this.raw = const {},
  });

  factory MemberDashboardData.fromJson(Map<String, dynamic> json) {
    final memberId = json['member_id']?.toString() ?? '';
    final fullName = json['member_name']?.toString() ?? L10n.current.commonMember;
    final rawOutstanding =
        (json['outstanding_balance'] as num?)?.toDouble() ?? 0;

    // GetLatestReceipt in the Go repository filters on mahal_id only, so this
    // payload can carry another member's receipt. Drop anything that is not
    // ours rather than show one member another member's payment.
    final rawLatest = json['latest_payment'];
    var latest = rawLatest is Map ? rawLatest.cast<String, dynamic>() : null;
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
      mahalName: json['mahal_name']?.toString() ?? L10n.current.homeYourMahal,
      outstanding: rawOutstanding > 0 ? rawOutstanding : 0,
      advanceCredit: (json['advance_credit'] as num?)?.toDouble() ?? 0,
      lastPaidMonth: json['last_paid_month']?.toString(),
      latestPayment: latest,
      raw: json,
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
  ApiException? _error;

  /// From GET /autopay/mandate/status. Null = unknown (loading or the call
  /// failed): the nudge stays hidden rather than guess.
  bool? _autoPaySetUp;

  @override
  void initState() {
    super.initState();
    PushNotificationService.instance.markSessionReady();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _status = _DashboardStatus.loading;
        _error = null;
      });
    }

    // Alerts only refresh the unread badge; AutoPay only decides the nudge.
    // Neither may fail the dashboard.
    final alertsFuture = _apiService.getAlerts();
    final autoPayFuture = _apiService.getAutoPayStatus();

    Map<String, dynamic> payload;
    try {
      payload = await _apiService.getMemberDashboardOrThrow();
    } on ApiException catch (e) {
      if (!mounted) return;
      // Never blank out financial data the member is already looking at.
      if (isRefresh && _data != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.dashboardRefreshFailed(e.userMessage)),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _status = _DashboardStatus.error;
          _error = e;
        });
      }
      return;
    }
    final autoPay = await autoPayFuture;
    await alertsFuture;
    if (!mounted) return;

    setState(() {
      _data = MemberDashboardData.fromJson(payload);
      if (autoPay != null) {
        final st = autoPay['status']?.toString().toUpperCase() ?? '';
        // A mandate waiting for the bank counts as set up: nudging would
        // invite a duplicate mandate.
        _autoPaySetUp = autoPay['active'] == true ||
            st == 'ACTIVE' ||
            st == 'PENDING_AUTHORIZATION';
      }
      _status = _DashboardStatus.ready;
    });
  }

  /// Opens a screen above home and refreshes when it closes (or is replaced,
  /// e.g. by a payment result). Home is the stack root, so this matches what
  /// AppNav.switchMemberTab would build for tab destinations.
  Future<void> _openRoute(String route) async {
    await Navigator.of(context).pushNamed(route);
    if (mounted) _loadDashboardData(isRefresh: true);
  }

  void _openLatestReceipt() {
    final receipt = _data?.latestPayment;
    if (receipt == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReceiptDetailsScreen.fromJson(receipt)),
    );
  }

  /// The API returns names in mixed case ("aslam"); the hero shows a proper
  /// capitalised first name.
  String get _displayName {
    final raw =
        _data?.firstName ?? ApiService.cachedMemberName.split(' ').first;
    if (raw.isEmpty) return context.l10n.commonMember;
    return raw[0].toUpperCase() + raw.substring(1);
  }

  void _showHelp() {
    MemberHelpSheet.show(
      context,
      mahalName: _data?.mahalName,
      officePhone: MemberHelpSheet.contactPhoneFrom(_data?.raw),
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
      value: context.colors.gradientHeaderOverlay,
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: gradientHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: context.colors.heroGradient),
              ),
            ),
            RefreshIndicator(
              onRefresh: () => _loadDashboardData(isRefresh: true),
              color: context.colors.primary,
              backgroundColor: context.colors.surface,
              edgeOffset: topPad + 72,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardHero(
                      firstName: _displayName,
                      mahalName: _data?.mahalName ?? context.l10n.homeLoadingMahal,
                      onAvatarTap: () => _openRoute(AppRoutes.memberProfile),
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
            title: context.l10n.homeLoadErrorTitle,
            description:
                _error?.userMessage ?? context.l10n.homeLoadErrorBody,
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
          paidUpToLabel: lastPaid == null
              ? null
              : DueMonth(lastPaid, DueMonthStatus.overdue).longLabel,
          onPayDues: () => _openRoute(AppRoutes.memberPay),
          onContribute: () => _openRoute(AppRoutes.memberContribution),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildQuickActions(),
        const SizedBox(height: AppSpacing.md),
        LatestPaymentCard(
          receipt: data.latestPayment,
          isUpToDate: data.isUpToDate,
          onViewReceipt: _openLatestReceipt,
          onPrimaryAction: () => data.isUpToDate
              ? _openRoute(AppRoutes.memberContribution)
              : _openRoute(AppRoutes.memberPay),
        ),
        if (_autoPaySetUp == false) ...[
          const SizedBox(height: AppSpacing.md),
          AutoPayNudgeCard(onSetUp: () => _openRoute(AppRoutes.memberAutopay)),
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
                  iconColor: context.colors.warning,
                  iconBackground: context.colors.warningBg,
                  label: context.l10n.homeContribute,
                  caption: context.l10n.homeContributeCaption,
                  onTap: () => _openRoute(AppRoutes.memberContribution),
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: QuickActionTile(
                  icon: Icons.receipt_long_outlined,
                  iconColor: context.colors.info,
                  iconBackground: context.colors.infoBg,
                  label: context.l10n.homeReceipts,
                  caption: context.l10n.homeReceiptsCaption,
                  onTap: () => _openRoute(AppRoutes.memberReceipts),
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
                // Live badge: reading an alert elsewhere updates it here.
                child: ValueListenableBuilder<int>(
                  valueListenable: ApiService.unreadAlertsCount,
                  builder: (context, unread, _) => QuickActionTile(
                    icon: Icons.campaign_outlined,
                    iconColor: context.colors.success,
                    iconBackground: context.colors.successBg,
                    label: context.l10n.homeNotices,
                    caption: context.l10n.homeNoticesCaption,
                    badgeCount: unread,
                    onTap: () => _openRoute(AppRoutes.memberAlerts),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: QuickActionTile(
                  icon: Icons.person_outline_rounded,
                  iconColor: context.colors.textSecondary,
                  iconBackground: context.colors.neutralBg,
                  label: context.l10n.homeProfile,
                  caption: context.l10n.homeProfileCaption,
                  onTap: () => _openRoute(AppRoutes.memberProfile),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

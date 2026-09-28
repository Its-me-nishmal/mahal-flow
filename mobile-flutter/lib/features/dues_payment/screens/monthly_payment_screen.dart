import 'package:flutter/material.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/payu_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/dues_period.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../l10n/l10n.dart';
import '../../payment_result/payment_result_args.dart';
import '../../payment_result/payment_result_nav.dart';
import '../../payment_result/payu_checkout.dart';
import '../../profile/widgets/member_help_sheet.dart';

/// One payable month on the list.
class DueMonthItem {
  final DueMonth month;

  /// False for "pay ahead" months that are not due yet.
  final bool isDue;
  bool isSelected;

  DueMonthItem({
    required this.month,
    required this.isDue,
    this.isSelected = false,
  });

  String get monthKey => month.key;
  String get displayName => month.longLabel;
}

enum _LoadState { loading, ready, error }

class MonthlyPaymentScreen extends StatefulWidget {
  const MonthlyPaymentScreen({super.key});

  /// How many future months a member may pay ahead.
  static const int payAheadMonths = 3;

  @override
  State<MonthlyPaymentScreen> createState() => _MonthlyPaymentScreenState();
}

class _MonthlyPaymentScreenState extends State<MonthlyPaymentScreen>
    implements PayUCheckoutProProtocol {
  final ApiService _apiService = ApiService();
  late final PayUCheckoutProFlutter _checkoutPro;

  _LoadState _state = _LoadState.loading;
  ApiException? _error;
  bool _isProcessing = false;

  /// Due months first (oldest → newest), then pay-ahead months. Selection is
  /// always a prefix of this list: dues are paid in order (AGENTS.md
  /// invariant 2), so a later month can't be picked while an earlier one is
  /// left unpaid.
  List<DueMonthItem> _months = [];

  /// Monthly dues rate from the API, or null when it can't be determined.
  double? _rate;
  bool _lastPaidKnown = true;
  Map<String, dynamic>? _dashboard;

  String? _activeTxnId;
  List<String> _activeSelectedKeys = [];
  num? _activeAmount;
  DateTime? _activeStartedAt;
  Map<String, dynamic>? _activePayUData;

  @override
  void initState() {
    super.initState();
    _checkoutPro = PayUCheckoutProFlutter(this);
    _load();
  }

  Future<void> _load() async {
    final firstLoad = _state != _LoadState.ready;
    if (firstLoad) {
      setState(() {
        _state = _LoadState.loading;
        _error = null;
      });
    }
    try {
      final dashboardFuture = _apiService.getMemberDashboardOrThrow();
      // The profile carries the member's own dues rate. It is optional: when
      // it fails we derive the rate from the outstanding balance instead.
      final profileFuture = _apiService.getMemberProfile();
      final dashboard = await dashboardFuture;
      final profile = await profileFuture;
      if (!mounted) return;
      _apply(dashboard, profile);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (firstLoad) {
        setState(() {
          _state = _LoadState.error;
          _error = e;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.l10n.duesPayRefreshFailed(e.userMessage))),
        );
      }
    }
  }

  void _apply(Map<String, dynamic> dashboard, Map<String, dynamic>? profile) {
    final lastPaid = dashboard['last_paid_month']?.toString();
    final anchor = DuesPeriod.parseMonthKey(lastPaid);
    final due = DuesPeriod.unpaidMonths(lastPaid);
    final outstanding =
        (dashboard['outstanding_balance'] as num?)?.toDouble() ?? 0;

    final custom = (profile?['monthly_dues_custom_amount'] as num?)?.toDouble();
    double? rate;
    if (custom != null && custom > 0) {
      rate = custom;
    } else if (outstanding > 0 && due.isNotEmpty) {
      rate = outstanding / due.length;
    }

    final items = <DueMonthItem>[
      // Preselect everything that is due, so the total matches the
      // "Pay ₹outstanding" the member tapped on the home screen.
      for (final m in due)
        DueMonthItem(month: m, isDue: true, isSelected: true),
    ];
    // Pay ahead continues straight after the last listed month so the
    // selection stays contiguous. When the backlog is longer than the list
    // (DuesPeriod caps it) there is nothing to pay ahead yet.
    final backlogComplete =
        due.isEmpty || due.last.status == DueMonthStatus.dueNow;
    if (anchor != null && backlogComplete) {
      final lastListed = due.isNotEmpty ? due.last.date : anchor;
      var cursor = DateTime(lastListed.year, lastListed.month + 1, 1);
      for (var i = 0; i < MonthlyPaymentScreen.payAheadMonths; i++) {
        items.add(DueMonthItem(
          month: DueMonth(cursor, DueMonthStatus.upcoming),
          isDue: false,
        ));
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }
    }

    setState(() {
      _dashboard = dashboard;
      _rate = rate;
      _lastPaidKnown = anchor != null;
      _months = items;
      _state = _LoadState.ready;
      _error = null;
    });
  }

  List<DueMonthItem> get _dueItems => _months.where((m) => m.isDue).toList();
  List<DueMonthItem> get _aheadItems => _months.where((m) => !m.isDue).toList();

  int get _selectedCount => _months.where((m) => m.isSelected).length;

  /// Total for the selection, or null when the rate is unknown.
  double? get _totalAmount => _rate == null ? null : _rate! * _selectedCount;

  String get _totalLabel =>
      _totalAmount == null ? '—' : Inr.format(_totalAmount!);

  /// Selecting a month selects every earlier one; clearing a month clears
  /// every later one. Keeps the selection contiguous from the oldest month.
  void _toggleMonth(DueMonthItem item, bool selected) {
    if (_isProcessing) return;
    final index = _months.indexOf(item);
    if (index < 0) return;
    setState(() {
      for (var i = 0; i < _months.length; i++) {
        if (selected && i <= index) _months[i].isSelected = true;
        if (!selected && i >= index) _months[i].isSelected = false;
      }
    });
  }

  bool get _allDueSelected =>
      _dueItems.isNotEmpty && _dueItems.every((m) => m.isSelected);

  void _toggleAllDue(bool? value) {
    if (_isProcessing || _dueItems.isEmpty) return;
    final target = value ?? false;
    setState(() {
      for (final m in _months) {
        if (m.isDue) {
          m.isSelected = target;
        } else if (!target) {
          m.isSelected = false;
        }
      }
    });
  }

  String get _selectionLabel {
    final keys =
        _months.where((m) => m.isSelected).map((m) => m.monthKey).toList();
    return DuesPeriod.paidMonthsLabel(keys);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handlePayment() async {
    final selectedKeys =
        _months.where((m) => m.isSelected).map((m) => m.monthKey).toList();
    if (selectedKeys.isEmpty || _isProcessing) return;

    final memberId = ApiService.currentMemberId;
    if (memberId == null) {
      _snack(context.l10n.duesPaySignInAgain);
      return;
    }

    setState(() => _isProcessing = true);
    _activeStartedAt = DateTime.now();

    final initRes = await _apiService.initializeDuesPayment(
      memberId: memberId,
      selectedMonths: selectedKeys,
      idempotencyKey: "IDEMP_${DateTime.now().millisecondsSinceEpoch}",
      gateway: "PAYU",
    );
    if (!mounted) return;

    final txnId = initRes?["transaction_id"]?.toString();
    if (txnId == null) {
      setState(() => _isProcessing = false);
      _snack(context.l10n.payuStartFailed);
      return;
    }

    _activeTxnId = txnId;
    _activeSelectedKeys = selectedKeys;
    // The server computes the amount; prefer it over our estimate.
    _activeAmount = (initRes!["amount"] as num?) ?? _totalAmount;
    final orderId = initRes["gateway_order_id"]?.toString() ?? "ORD$txnId";

    final payUData = await _apiService.getPayUCheckoutData(orderId);
    if (!mounted) return;
    _activePayUData = payUData;

    final params = payUData == null
        ? null
        : PayUCheckout.paymentParams(
            checkout: payUData,
            transactionId: orderId,
            referenceId: txnId,
            memberId: memberId,
          );
    if (params == null) {
      setState(() => _isProcessing = false);
      _snack(context.l10n.payuOpenFailed);
      return;
    }

    try {
      _checkoutPro.openCheckoutScreen(
        payUPaymentParams: params,
        payUCheckoutProConfig: PayUCheckout.config(upiIntentOnly: true),
      );
    } catch (e) {
      debugPrint("[PAYU_SDK_ERROR] Failed to open native checkout: $e");
      setState(() => _isProcessing = false);
      _snack(context.l10n.payuOpenFailed);
    }
  }

  PaymentResultArgs _args({
    String? reason,
    bool cancelled = false,
    bool gatewayReportedSuccess = false,
    String? gatewayPaymentId,
  }) =>
      PaymentResultArgs(
        kind: PaymentKind.dues,
        at: _activeStartedAt ?? DateTime.now(),
        amount: _activeAmount,
        coverage: DuesPeriod.paidMonthsLabel(_activeSelectedKeys),
        transactionId: _activeTxnId,
        gatewayReportedSuccess: gatewayReportedSuccess,
        gatewayPaymentId: gatewayPaymentId,
        reason: reason,
        cancelled: cancelled,
      );

  // --- PayUCheckoutProProtocol Implementation ---

  @override
  void generateHash(Map response) {
    PayUCheckout.respondToHashRequest(
      api: _apiService,
      checkoutPro: _checkoutPro,
      response: response,
      checkout: _activePayUData,
    );
  }

  @override
  void onPaymentSuccess(dynamic response) async {
    debugPrint("[PAYU_NATIVE_SUCCESS] $response");
    final txnId = _activeTxnId;
    if (txnId == null) return;
    final mihpayid = extractMihpayid(response);
    final confirmRes = await _apiService.confirmPayment(
      txnId,
      gatewayPaymentId: mihpayid,
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);

    final receipt = confirmRes?["receipt"];
    if (confirmRes?["status"] == "SUCCESS" && receipt is Map) {
      PaymentResultNav.success(
        context,
        PaymentResultArgs.fromReceipt(
          kind: PaymentKind.dues,
          receipt: receipt.cast<String, dynamic>(),
          fallbackAmount: _activeAmount,
          fallbackCoverage: DuesPeriod.paidMonthsLabel(_activeSelectedKeys),
          transactionId: txnId,
        ),
      );
      return;
    }
    // PayU took the payment but the server has not confirmed it: never
    // report success, never invite a second payment — wait for it.
    PaymentResultNav.pending(
      context,
      _args(
        gatewayReportedSuccess: true,
        gatewayPaymentId: mihpayid.isEmpty ? null : mihpayid,
      ),
    );
  }

  @override
  void onPaymentFailure(dynamic response) {
    debugPrint("[PAYU_NATIVE_FAILURE] $response");
    if (!mounted) return;
    setState(() => _isProcessing = false);
    PaymentResultNav.failed(
      context,
      _args(reason: PayUCheckout.failureReason(response)),
    );
  }

  @override
  void onPaymentCancel(Map? response) {
    debugPrint("[PAYU_NATIVE_CANCEL] $response");
    if (!mounted) return;
    setState(() => _isProcessing = false);
    PaymentResultNav.failed(context, _args(cancelled: true));
  }

  @override
  void onError(Map? response) {
    debugPrint("[PAYU_NATIVE_ERROR] $response");
    if (!mounted) return;
    setState(() => _isProcessing = false);
    PaymentResultNav.failed(
      context,
      _args(reason: PayUCheckout.failureReason(response)),
    );
  }

  void _showHelp() {
    MemberHelpSheet.show(
      context,
      mahalName: _dashboard?['mahal_name']?.toString(),
      officePhone: MemberHelpSheet.contactPhoneFrom(_dashboard),
      extraNote: _rate == null
          ? null
          : context.l10n.duesPayHelpNote(Inr.format(_rate!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Leaving mid-checkout would orphan the gateway callback.
      canPop: !_isProcessing,
      child: AppPageScaffold(
        title: context.l10n.duesPayTitle,
        eyebrow: context.l10n.duesPayEyebrow,
        subtitle: context.l10n.duesPaySubtitle,
        onBack: _isProcessing ? null : () => AppNav.memberHome(context),
        onRefresh: _isProcessing ? null : _load,
        actions: [
          AppHeaderIconButton(
            icon: Icons.help_outline_rounded,
            tooltip: context.l10n.duesPayHelp,
            onTap: _showHelp,
          ),
        ],
        floatingChild: _state == _LoadState.ready ? _summaryCard() : null,
        content: [
          const SizedBox(height: AppSpacing.md),
          ..._body(),
        ],
        bottomBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_state == _LoadState.ready) _payBar(),
            IgnorePointer(
              ignoring: _isProcessing,
              child: const MemberBottomNavBar(currentIndex: 1),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _body() {
    switch (_state) {
      case _LoadState.loading:
        return [_skeleton()];
      case _LoadState.error:
        return [
          AppErrorStateView(
            title: context.l10n.duesPayLoadFailedTitle,
            description:
                _error?.userMessage ?? context.l10n.duesPayLoadFailedFallback,
            onRetry: _load,
          ),
        ];
      case _LoadState.ready:
        if (!_lastPaidKnown) {
          return [
            EmptyStateView(
              icon: Icons.event_busy_outlined,
              title: context.l10n.duesPayPeriodNotSetTitle,
              description: context.l10n.duesPayPeriodNotSetMessage,
              actionLabel: context.l10n.duesPayGetHelp,
              onAction: _showHelp,
            ),
          ];
        }
        return [
          if (_dueItems.isEmpty)
            AppNoticeCard(
              icon: Icons.check_circle_outline_rounded,
              title: context.l10n.duesPayUpToDateTitle,
              message: context.l10n.duesPayUpToDateMessage,
              color: context.colors.success,
              background: context.colors.successBg,
            )
          else
            _monthsCard(
              label: context.l10n.duesPayDueNowHeader,
              items: _dueItems,
              selectAll: true,
            ),
          const SizedBox(height: AppSpacing.md),
          if (_aheadItems.isNotEmpty) ...[
            _monthsCard(
                label: context.l10n.duesPayPayAheadHeader, items: _aheadItems),
            const SizedBox(height: AppSpacing.md),
          ],
          AppNoticeCard(
            icon: Icons.volunteer_activism_outlined,
            title: context.l10n.duesPayContributeTitle,
            message: context.l10n.duesPayContributeMessage,
            color: context.colors.warning,
            background: context.colors.warningBg,
            actionLabel: context.l10n.duesPayOpen,
            onAction: _isProcessing
                ? null
                : () => Navigator.of(context)
                    .pushNamed(AppRoutes.memberContribution),
          ),
        ];
    }
  }

  Widget _payBar() {
    final total = _totalAmount;
    return AppBottomActionBar(
      applySafeArea: false,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.duesPayMonthsSelected(_selectedCount),
                    style: context.text.small,
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(_totalLabel, style: context.text.pageTitle),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                context.l10n.duesPayNoFee,
                textAlign: TextAlign.end,
                style: context.text.small.copyWith(
                  color: context.colors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.ms),
        AppPrimaryButton(
          label: _isProcessing
              ? context.l10n.duesPayProcessing
              : total == null
                  ? context.l10n.duesPayContinueToPay
                  : context.l10n.duesPayPayAmount(Inr.format(total)),
          icon: Icons.lock_rounded,
          isLoading: _isProcessing,
          onPressed: _selectedCount == 0 ? null : _handlePayment,
        ),
      ],
    );
  }

  Widget _summaryCard() {
    final total = _totalAmount;
    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(context.l10n.duesPayTotalSelected,
                      style: context.text.label)),
              if (_selectedCount > 0)
                StatusPill(
                  label: context.l10n.duesPayMonthCount(_selectedCount),
                  foreground: context.colors.primary,
                  background: context.colors.primaryLight,
                  icon: Icons.event_available_rounded,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _totalLabel,
              semanticsLabel: total == null
                  ? context.l10n.duesPayTotalUnavailableSemantics
                  : context.l10n.duesPayTotalSemantics(Inr.spoken(total)),
              style: context.text.amount.copyWith(color: context.colors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _selectedCount == 0
                ? context.l10n.duesPaySelectAtLeastOne
                : [
                    _selectionLabel,
                    if (_rate != null)
                      context.l10n.duesPayPerMonth(Inr.format(_rate!)),
                  ].where((s) => s.isNotEmpty).join(' · '),
            style: context.text.body.copyWith(color: context.colors.textSecondary),
          ),
          if (_rate == null && _selectedCount > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.duesPayExactAmountNote,
              style: context.text.small,
            ),
          ],
        ],
      ),
    );
  }

  Widget _monthsCard({
    required String label,
    required List<DueMonthItem> items,
    bool selectAll = false,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: context.text.label)),
                  if (selectAll) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        context.l10n.duesPaySelectAll,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: context.text.small,
                      ),
                    ),
                    Checkbox(
                      value: _allDueSelected,
                      activeColor: context.colors.primary,
                      semanticLabel: context.l10n.duesPaySelectAllSemantics,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      onChanged: _isProcessing ? null : _toggleAllDue,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Divider(height: 1, color: context.colors.border),
          for (var i = 0; i < items.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i == items.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: context.colors.border)),
              ),
              child: _monthRow(items[i]),
            ),
        ],
      ),
    );
  }

  Widget _monthRow(DueMonthItem item) {
    return MergeSemantics(
      child: InkWell(
        onTap:
            _isProcessing ? null : () => _toggleMonth(item, !item.isSelected),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Checkbox(
                value: item.isSelected,
                activeColor: context.colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                onChanged: _isProcessing
                    ? null
                    : (v) => _toggleMonth(item, v ?? false),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.displayName, style: context.text.listTitle),
                    const SizedBox(height: AppSpacing.xs),
                    _statusPill(item.month.status),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _rate == null ? '—' : Inr.format(_rate!),
                style: context.text.cardTitle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(DueMonthStatus status) {
    switch (status) {
      case DueMonthStatus.overdue:
        return StatusPill(
          label: context.l10n.statusOverdue,
          foreground: context.colors.error,
          background: context.colors.errorBg,
          icon: Icons.error_outline_rounded,
        );
      case DueMonthStatus.dueNow:
        return StatusPill(
          label: context.l10n.duesPayStatusDueNow,
          foreground: context.colors.warning,
          background: context.colors.warningBg,
          icon: Icons.schedule_rounded,
        );
      case DueMonthStatus.upcoming:
        return StatusPill(
          label: context.l10n.duesPayStatusUpcoming,
          foreground: context.colors.textSecondary,
          background: context.colors.neutralBg,
          icon: Icons.event_outlined,
        );
    }
  }

  Widget _skeleton() {
    return ShimmerLoading(
      semanticsLabel: context.l10n.duesPayLoadingSemantics,
      child: Column(
        children: [
          for (final h in const [120.0, 230.0])
            Container(
              height: h,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.border.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
        ],
      ),
    );
  }
}

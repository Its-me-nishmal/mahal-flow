import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';

import '../../../core/network/api_service.dart';
import '../../../core/network/payu_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/dues_period.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../l10n/l10n.dart';
import '../../payment_result/payu_checkout.dart';

enum _LoadState { loading, ready, error }

/// Server mandate states (domain.Mandate.Status).
enum _MandateState { none, pending, active }

class SetupAutoPayScreen extends StatefulWidget {
  const SetupAutoPayScreen({super.key});

  /// Years the standing instruction stays valid (matches the server's
  /// `paymentEndDate`, now + 3 years).
  static const int mandateYears = 3;

  @override
  State<SetupAutoPayScreen> createState() => _SetupAutoPayScreenState();
}

class _SetupAutoPayScreenState extends State<SetupAutoPayScreen>
    implements PayUCheckoutProProtocol {
  final ApiService _apiService = ApiService();
  late final PayUCheckoutProFlutter _checkoutPro;

  _LoadState _state = _LoadState.loading;
  ApiException? _error;
  bool _isProcessing = false;

  _MandateState _mandate = _MandateState.none;
  Map<String, dynamic> _status = const {};

  /// The member's monthly dues, from the API. Null = unknown: setup is then
  /// blocked rather than guessed.
  double? _duesAmount;

  // MINUTELY/HOURLY/DAILY are test cadences for the PayU sandbox and our
  // scheduler (PayU ADHOC). They are only offered in debug builds; a release
  // build always creates a MONTHLY mandate.
  static const List<String> _debugFrequencies = [
    "MONTHLY",
    "DAILY",
    "HOURLY",
    "MINUTELY",
  ];
  String _frequency = "MONTHLY";

  String? _activeMandateId;
  Map<String, dynamic>? _activePayUData;

  @override
  void initState() {
    super.initState();
    _checkoutPro = PayUCheckoutProFlutter(this);
    _load();
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> _load() async {
    final firstLoad = _state != _LoadState.ready;
    if (firstLoad) {
      setState(() {
        _state = _LoadState.loading;
        _error = null;
      });
    }
    try {
      final statusF = _apiService.getAutoPayStatusOrThrow();
      final profileF = _apiService.getMemberProfile();
      final dashboardF = _apiService.getMemberDashboard();
      final status = await statusF;
      final profile = await profileF;
      final dashboard = await dashboardF;
      if (!mounted) return;
      setState(() {
        _status = status;
        _mandate = _mandateStateOf(status);
        _duesAmount = _duesFrom(status, profile, dashboard);
        final serverFreq = status['frequency']?.toString().toUpperCase();
        if (serverFreq != null && serverFreq.isNotEmpty) {
          _frequency = serverFreq;
        }
        _state = _LoadState.ready;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (firstLoad) {
        setState(() {
          _state = _LoadState.error;
          _error = e;
        });
      } else {
        _snack(context.l10n.autopayRefreshFailed(e.userMessage));
      }
    }
  }

  static _MandateState _mandateStateOf(Map<String, dynamic> status) {
    final s = status['status']?.toString().toUpperCase() ?? '';
    if (status['active'] == true || s == 'ACTIVE') return _MandateState.active;
    if (s == 'PENDING_AUTHORIZATION' || s == 'PENDING') {
      return _MandateState.pending;
    }
    return _MandateState.none;
  }

  /// Existing mandate amount, else the member's dues rate from the server
  /// (`effective_monthly_dues`: custom amount or the Mahal default), else the
  /// custom amount, else the outstanding balance spread over the unpaid
  /// months.
  static double? _duesFrom(
    Map<String, dynamic> status,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? dashboard,
  ) {
    final existing = (status['amount'] as num?)?.toDouble();
    if (existing != null && existing > 0) return existing;
    for (final source in [dashboard, profile]) {
      final effective = (source?['effective_monthly_dues'] as num?)?.toDouble();
      if (effective != null && effective > 0) return effective;
    }
    final custom = (profile?['monthly_dues_custom_amount'] as num?)?.toDouble();
    if (custom != null && custom > 0) return custom;
    final outstanding = (dashboard?['outstanding_balance'] as num?)?.toDouble();
    final months =
        DuesPeriod.unpaidMonths(dashboard?['last_paid_month']?.toString());
    if (outstanding != null && outstanding > 0 && months.isNotEmpty) {
      return outstanding / months.length;
    }
    return null;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------------
  // Copy
  // ---------------------------------------------------------------------------

  bool get _isTestCadence => _frequency != "MONTHLY" && _frequency != "WEEKLY";

  /// PayU SI billingCycle: sub-daily/daily test cadences use ADHOC.
  String get _billingCycle {
    switch (_frequency) {
      case "MINUTELY":
      case "HOURLY":
      case "DAILY":
        return "ADHOC";
      case "WEEKLY":
        return "WEEKLY";
      default:
        return "MONTHLY";
    }
  }

  String _frequencyLabel(String f) {
    final l = context.l10n;
    switch (f) {
      case "MONTHLY":
        return l.autopayFrequencyMonthly;
      case "WEEKLY":
        return l.autopayFrequencyWeekly;
      case "DAILY":
        return l.autopayFrequencyDaily;
      case "HOURLY":
        return l.autopayFrequencyHourly;
      case "MINUTELY":
        return l.autopayFrequencyMinutely;
      default:
        return f.isEmpty ? f : f[0] + f.substring(1).toLowerCase();
    }
  }

  /// "on the 1st of every month", "every day"…
  String get _scheduleCopy {
    final l = context.l10n;
    switch (_frequency) {
      case "MINUTELY":
        return l.autopayScheduleMinutely;
      case "HOURLY":
        return l.autopayScheduleHourly;
      case "DAILY":
        return l.autopayScheduleDaily;
      case "WEEKLY":
        return l.autopayScheduleWeekly;
      default:
        // The server schedules monthly mandates on recurring_day (the 1st).
        final day = (_status['recurring_day'] as num?)?.toInt() ?? 1;
        // English ordinals ("1st"); Malayalam adds its own suffix in the
        // message ("1-ാം").
        return l.autopayScheduleMonthly(
            l.localeName == 'en' ? _ordinal(day) : '$day');
    }
  }

  static String _ordinal(int d) {
    if (d >= 11 && d <= 13) return '${d}th';
    switch (d % 10) {
      case 1:
        return '${d}st';
      case 2:
        return '${d}nd';
      case 3:
        return '${d}rd';
      default:
        return '${d}th';
    }
  }

  DateTime get _endDate {
    final now = DateTime.now();
    return DateTime(
        now.year + SetupAutoPayScreen.mandateYears, now.month, now.day);
  }

  String get _nextDebitLabel =>
      AppDate.formatDate(_status['next_debit'], fallback: '—');

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _confirmAndSetUp() async {
    final amount = _duesAmount;
    if (amount == null || _isProcessing) return;

    final ok = await AppBottomSheet.show<bool>(
      context: context,
      title: context.l10n.autopayConfirmTitle,
      subtitle: context.l10n.autopayConfirmSubtitle,
      icon: Icons.sync_rounded,
      builder: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppDetailRow(
              label: context.l10n.autopayAmountPerDebit,
              value: Inr.format(amount)),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
            label: context.l10n.autopayMaxPerDebit,
            value: Inr.format(amount),
            emphasize: true,
          ),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(label: context.l10n.autopayWhen, value: _scheduleCopy),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
              label: context.l10n.autopayValidUntil,
              value: AppDate.formatDate(_endDate)),
          const SizedBox(height: AppSpacing.ms),
          Text(
            context.l10n.autopayAuthChargeNote,
            style: context.text.small,
          ),
        ],
      ),
      actions: [
        AppSecondaryButton(
          label: context.l10n.commonCancel,
          color: context.colors.textSecondary,
          height: AppSizes.buttonHeightCompact,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppPrimaryButton(
          label: context.l10n.commonContinue,
          height: AppSizes.buttonHeightCompact,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (ok == true && mounted) await _startMandate(amount);
  }

  Future<void> _startMandate(double amount) async {
    final memberId = ApiService.currentMemberId;
    if (memberId == null) {
      _snack(context.l10n.autopaySignInAgain);
      return;
    }
    setState(() => _isProcessing = true);

    final res = await _apiService.createAutoPayMandate(
      maxAmount: amount,
      debitAmount: amount,
      frequency: _frequency,
    );
    if (!mounted) return;

    final mandateId = res?["mandate_id"]?.toString();
    final rawCheckout = res?["payu_checkout"];
    final checkout =
        rawCheckout is Map ? rawCheckout.cast<String, dynamic>() : null;
    if (mandateId == null || checkout == null) {
      setState(() => _isProcessing = false);
      _snack(context.l10n.autopayStartFailed);
      return;
    }

    _activeMandateId = mandateId;
    _activePayUData = checkout;

    String fmt(DateTime d) =>
        "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
    final now = DateTime.now();
    final params = PayUCheckout.paymentParams(
      checkout: checkout,
      transactionId: mandateId,
      referenceId: mandateId,
      memberId: memberId,
      // The standing instruction the member approves: debits up to [amount]
      // each cycle until the end date.
      siParams: {
        PayUSIParamsKeys.billingAmount: amount.toStringAsFixed(2),
        PayUSIParamsKeys.billingCurrency: "INR",
        PayUSIParamsKeys.billingCycle: _billingCycle,
        PayUSIParamsKeys.billingInterval: 1,
        PayUSIParamsKeys.paymentStartDate: fmt(now),
        PayUSIParamsKeys.paymentEndDate: fmt(_endDate),
        PayUSIParamsKeys.billingRule: "MAX",
        PayUSIParamsKeys.billingLimit: "ON",
        PayUSIParamsKeys.remarks: "MahalFlow monthly dues AutoPay",
      },
    );
    if (params == null) {
      setState(() => _isProcessing = false);
      _snack(context.l10n.autopayOpenMandateFailed);
      return;
    }

    try {
      _checkoutPro.openCheckoutScreen(
        payUPaymentParams: params,
        payUCheckoutProConfig: PayUCheckout.config(),
      );
    } catch (e) {
      debugPrint("[PAYU_SI_ERROR] open mandate checkout: $e");
      setState(() => _isProcessing = false);
      _snack(context.l10n.autopayOpenMandateFailed);
    }
  }

  Future<void> _cancelAutoPay() async {
    final pending = _mandate == _MandateState.pending;
    final confirmed = await AppBottomSheet.showConfirmation(
      context: context,
      title: pending
          ? context.l10n.autopayCancelSetupTitle
          : context.l10n.autopayTurnOffTitle,
      message: pending
          ? context.l10n.autopayCancelSetupMessage
          : context.l10n.autopayTurnOffMessage,
      confirmLabel: pending
          ? context.l10n.autopayCancelSetupAction
          : context.l10n.autopayTurnOffAction,
      cancelLabel: context.l10n.autopayKeep,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isProcessing = true);
    final res = await _apiService.cancelAutoPayMandate(
      mandateId: _status['mandate_id']?.toString(),
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (res != null && res["status"] == "CANCELLED") {
      _snack(pending
          ? context.l10n.autopaySetupCancelled
          : context.l10n.autopayTurnedOff);
      await _load();
    } else {
      _snack(context.l10n.autopayCancelFailed);
    }
  }

  // ---------------------------------------------------------------------------
  // PayUCheckoutProProtocol
  // ---------------------------------------------------------------------------

  @override
  void generateHash(Map response) {
    PayUCheckout.respondToHashRequest(
      api: _apiService,
      checkoutPro: _checkoutPro,
      response: response,
      checkout: _activePayUData,
      txnid: _activeMandateId,
    );
  }

  @override
  void onPaymentSuccess(dynamic response) async {
    debugPrint("[PAYU_SI_SUCCESS] $response");
    final mandateId = _activeMandateId;
    if (mandateId == null) return;
    final confirmRes = await _apiService.confirmAutoPayMandate(
      mandateId: mandateId,
      gatewayPaymentId: extractMihpayid(response),
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (confirmRes != null && confirmRes["status"] == "ACTIVE") {
      await _load();
      if (mounted) _showSuccessSheet(confirmRes["next_debit"]);
      return;
    }
    // Approved at the bank but not active on our side yet: show it as
    // pending so the member cannot start a second mandate.
    setState(() {
      _mandate = _MandateState.pending;
      _status = {
        ..._status,
        'mandate_id': mandateId,
        'status': 'PENDING_AUTHORIZATION'
      };
    });
    _snack(context.l10n.autopayBankApprovedPending);
    await _load();
  }

  @override
  void onPaymentFailure(dynamic response) {
    debugPrint("[PAYU_SI_FAILURE] $response");
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _snack(context.l10n
        .autopaySetupFailedReason(PayUCheckout.failureReason(response)));
    _load();
  }

  @override
  void onPaymentCancel(Map? response) {
    debugPrint("[PAYU_SI_CANCEL] $response");
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _snack(context.l10n.autopaySetupCancelledNoCharge);
    _load();
  }

  @override
  void onError(Map? response) {
    debugPrint("[PAYU_SI_ERROR] $response");
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _snack(context.l10n
        .autopayErrorReason(PayUCheckout.failureReason(response)));
    _load();
  }

  void _showSuccessSheet(dynamic nextDebit) {
    final amount = _duesAmount;
    AppBottomSheet.show(
      context: context,
      title: context.l10n.autopayOnTitle,
      subtitle: context.l10n.autopayOnSubtitle,
      icon: Icons.check_circle_rounded,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.autopayOnMessage(
              amount == null ? context.l10n.autopayYourDues : Inr.format(amount),
              _scheduleCopy,
            ),
            style: context.text.body.copyWith(color: context.colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppDetailRow(
            label: context.l10n.autopayFirstDebit,
            value: AppDate.formatDate(nextDebit, fallback: _nextDebitLabel),
          ),
          if (_activeMandateId != null)
            AppDetailRow(
                label: context.l10n.autopayMandateId,
                value: _activeMandateId!),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: context.l10n.commonDone,
            onPressed: () {
              Navigator.of(ctx).pop();
              // true tells the caller AutoPay setup completed.
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isProcessing,
      child: AppPageScaffold(
        title: context.l10n.autopayTitle,
        eyebrow: context.l10n.autopayEyebrow,
        subtitle: context.l10n.autopaySubtitle,
        onBack: _isProcessing ? null : () => Navigator.of(context).maybePop(),
        onRefresh:
            (_isProcessing || _state == _LoadState.loading) ? null : _load,
        floatingChild: _state == _LoadState.ready ? _summaryCard() : null,
        content: [
          const SizedBox(height: AppSpacing.md),
          ..._body(),
        ],
        bottomBar: _state == _LoadState.ready ? _actions() : null,
      ),
    );
  }

  List<Widget> _body() {
    switch (_state) {
      case _LoadState.loading:
        return [
          ShimmerLoading(
            semanticsLabel: context.l10n.autopayLoadingSemantics,
            child: Column(
              children: [
                for (final h in const [150.0, 180.0])
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
          ),
        ];
      case _LoadState.error:
        return [
          AppErrorStateView(
            title: context.l10n.autopayLoadFailedTitle,
            description:
                _error?.userMessage ?? context.l10n.autopayLoadFailedFallback,
            onRetry: _load,
          ),
        ];
      case _LoadState.ready:
        return [
          if (_mandate == _MandateState.none && kDebugMode) ...[
            _debugFrequencyCard(),
            const SizedBox(height: AppSpacing.md),
          ],
          _detailsCard(),
          const SizedBox(height: AppSpacing.md),
          if (_mandate == _MandateState.pending)
            AppNoticeCard(
              icon: Icons.hourglass_top_rounded,
              title: context.l10n.autopayWaitingBankTitle,
              message: context.l10n.autopayWaitingBankMessage,
              color: context.colors.warning,
              background: context.colors.warningBg,
            )
          else if (_mandate == _MandateState.none && _duesAmount == null)
            AppNoticeCard(
              icon: Icons.info_outline_rounded,
              title: context.l10n.autopayDuesNotSetTitle,
              message: context.l10n.autopayDuesNotSetMessage,
              color: context.colors.warning,
              background: context.colors.warningBg,
            )
          else
            AppNoticeCard(
              icon: Icons.info_outline_rounded,
              title: context.l10n.autopayHowItWorksTitle,
              message: context.l10n.autopayHowItWorksMessage,
              color: context.colors.info,
              background: context.colors.infoBg,
            ),
        ];
    }
  }

  Widget _summaryCard() {
    final (label, fg, bg, icon) = switch (_mandate) {
      _MandateState.active => (
          context.l10n.statusActive,
          context.colors.success,
          context.colors.successBg,
          Icons.check_circle_rounded
        ),
      _MandateState.pending => (
          context.l10n.autopayStatePendingActivation,
          context.colors.warning,
          context.colors.warningBg,
          Icons.hourglass_top_rounded
        ),
      _MandateState.none => (
          context.l10n.autopayStateOff,
          context.colors.textSecondary,
          context.colors.neutralBg,
          Icons.pause_circle_outline_rounded
        ),
    };
    final amount = _duesAmount;
    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isTestCadence
                      ? context.l10n.autopayDebitTestCadence
                      : context.l10n.autopayMonthlyDebit,
                  style: context.text.label,
                ),
              ),
              StatusPill(
                  label: label, foreground: fg, background: bg, icon: icon),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount == null ? '—' : Inr.format(amount),
              style: context.text.amount.copyWith(color: context.colors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.autopayDebitedBy(_scheduleCopy),
            style: context.text.body.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard() {
    final amount = _duesAmount;
    final maxAmount = (_status['max_amount'] as num?)?.toDouble() ?? amount;
    final isOn = _mandate == _MandateState.active;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionLabel(context.l10n.autopayMandateDetails),
          const SizedBox(height: AppSpacing.sm),
          AppDetailRow(
            label: context.l10n.autopayPaymentMethod,
            value: _status['mode']?.toString() == 'E_NACH'
                ? 'e-NACH'
                : 'UPI e-Mandate',
          ),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
              label: context.l10n.autopayFrequency,
              value: _frequencyLabel(_frequency)),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
            label: context.l10n.autopayAmountPerDebit,
            value: amount == null ? '—' : Inr.format(amount),
            emphasize: true,
          ),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
            label: context.l10n.autopayMaxPerDebit,
            value: maxAmount == null ? '—' : Inr.format(maxAmount),
          ),
          Divider(height: 1, color: context.colors.border),
          if (isOn) ...[
            AppDetailRow(
                label: context.l10n.autopayNextDebit, value: _nextDebitLabel),
            Divider(height: 1, color: context.colors.border),
            AppDetailRow(
              label: context.l10n.autopayLastDebit,
              value: AppDate.formatDate(_status['last_debit_at']),
            ),
          ] else if (_mandate == _MandateState.none) ...[
            AppDetailRow(
              label: context.l10n.autopayAuthorisation,
              value: context.l10n.autopaySmallOneTimeCharge,
            ),
            Divider(height: 1, color: context.colors.border),
            AppDetailRow(
                label: context.l10n.autopayValidUntil,
                value: AppDate.formatDate(_endDate)),
          ] else
            AppDetailRow(
              label: context.l10n.autopayMandateId,
              value: _status['mandate_id']?.toString() ?? '—',
            ),
        ],
      ),
    );
  }

  /// Debug builds only: pick a test cadence to exercise the scheduler.
  Widget _debugFrequencyCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionLabel(context.l10n.autopayTestFrequency),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _debugFrequencies.map((f) {
              final active = f == _frequency;
              return Semantics(
                button: true,
                selected: active,
                inMutuallyExclusiveGroup: true,
                label: context.l10n.autopayFrequencySemantics(_frequencyLabel(f)),
                excludeSemantics: true,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isProcessing
                        ? null
                        : () => setState(() => _frequency = f),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      constraints:
                          const BoxConstraints(minHeight: AppSizes.minTouch),
                      alignment: Alignment.center,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color:
                            active ? context.colors.primary : context.colors.background,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: active ? context.colors.primary : context.colors.border,
                        ),
                      ),
                      child: Text(
                        _frequencyLabel(f),
                        style: context.text.buttonSmall.copyWith(
                          color:
                              active
                                  ? context.colors.onPrimary
                                  : context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    switch (_mandate) {
      case _MandateState.active:
        return AppBottomActionBar(
          children: [
            AppSecondaryButton(
              label: _isProcessing
                  ? context.l10n.autopayTurningOff
                  : context.l10n.autopayTurnOffButton,
              icon: Icons.close_rounded,
              color: context.colors.error,
              onPressed: _isProcessing ? null : _cancelAutoPay,
            ),
          ],
        );
      case _MandateState.pending:
        return AppBottomActionBar(
          children: [
            AppPrimaryButton(
              label: context.l10n.autopayCheckStatus,
              icon: Icons.refresh_rounded,
              isLoading: _isProcessing,
              onPressed: _isProcessing ? null : _load,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: context.l10n.autopayCancelSetupAction,
              color: context.colors.error,
              onPressed: _isProcessing ? null : _cancelAutoPay,
            ),
          ],
        );
      case _MandateState.none:
        return AppBottomActionBar(
          children: [
            AppPrimaryButton(
              label: _isProcessing
                  ? context.l10n.autopaySettingUp
                  : context.l10n.autopayConfirmTitle,
              icon: Icons.check_rounded,
              isLoading: _isProcessing,
              onPressed: (_isProcessing || _duesAmount == null)
                  ? null
                  : _confirmAndSetUp,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: context.l10n.autopayNotNow,
              color: context.colors.textSecondary,
              onPressed:
                  _isProcessing ? null : () => Navigator.of(context).maybePop(),
            ),
          ],
        );
    }
  }
}

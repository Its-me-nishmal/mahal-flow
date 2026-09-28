import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/payu_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';
import '../../../l10n/l10n.dart';
import '../../payment_result/payment_result_args.dart';
import '../../payment_result/payment_result_nav.dart';
import '../../payment_result/payu_checkout.dart';

/// A fund a member can give to. Icon and colour are part of the definition so
/// the same fund always looks the same wherever it appears.
class _Fund {
  /// Sent to the server as the fund id — never translated.
  final String name;
  final IconData icon;
  final AppTone tone;

  const _Fund(this.name, this.icon, this.tone);

  /// Display title in the app language.
  String title(AppLocalizations l) => switch (name) {
        'Zakat Fund' => l.contributionFundZakat,
        'General Fund' => l.contributionFundGeneral,
        'Masjid Renovation' => l.contributionFundMasjid,
        'Education Help' => l.contributionFundEducation,
        'Medical Aid' => l.contributionFundMedical,
        _ => name,
      };

  String blurb(AppLocalizations l) => switch (name) {
        'Zakat Fund' => l.contributionFundZakatBlurb,
        'General Fund' => l.contributionFundGeneralBlurb,
        'Masjid Renovation' => l.contributionFundMasjidBlurb,
        'Education Help' => l.contributionFundEducationBlurb,
        'Medical Aid' => l.contributionFundMedicalBlurb,
        _ => '',
      };
}

class ContributionScreen extends StatefulWidget {
  const ContributionScreen({super.key});

  /// Smallest contribution accepted.
  static const int minAmount = 10;

  /// Largest single contribution accepted in the app.
  static const int maxAmount = 500000;

  /// Contributions above this ask for a confirmation first.
  static const int confirmAbove = 10000;

  @override
  State<ContributionScreen> createState() => _ContributionScreenState();
}

class _ContributionScreenState extends State<ContributionScreen>
    implements PayUCheckoutProProtocol {
  final ApiService _apiService = ApiService();
  late final PayUCheckoutProFlutter _checkoutPro;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Held across the PayU checkout lifecycle so the callbacks can confirm the
  // right transaction and describe the right payment.
  String? _activeTxnId;
  Map<String, dynamic>? _activePayUData;
  num? _activeAmount;
  String? _activeFund;

  /// [_activeFund] as shown to the member (result screens).
  String? _activeFundTitle;
  DateTime? _activeStartedAt;

  static const List<_Fund> _funds = [
    _Fund('Zakat Fund', Icons.volunteer_activism_outlined, AppTone.warning),
    _Fund('General Fund', Icons.account_balance_wallet_outlined,
        AppTone.primary),
    _Fund('Masjid Renovation', Icons.mosque_outlined, AppTone.info),
    _Fund('Education Help', Icons.school_outlined, AppTone.success),
    _Fund('Medical Aid', Icons.medical_services_outlined, AppTone.error),
  ];

  /// Display title for a fund id (the server-facing name).
  String _fundTitle(String name) {
    final l = context.l10n;
    for (final f in _funds) {
      if (f.name == name) return f.title(l);
    }
    return name;
  }

  static const List<int> _quickAmounts = [500, 1000, 2000, 5000];

  String _selectedFund = _funds.first.name;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkoutPro = PayUCheckoutProFlutter(this);
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int get _amount => int.tryParse(_amountController.text.trim()) ?? 0;

  /// Inline validation shown under the amount while typing.
  String? get _amountError {
    final text = _amountController.text.trim();
    if (text.isEmpty) return null;
    final amount = _amount;
    if (amount < ContributionScreen.minAmount) {
      return context.l10n
          .contributionMinError(Inr.format(ContributionScreen.minAmount));
    }
    if (amount > ContributionScreen.maxAmount) {
      return context.l10n
          .contributionMaxError(Inr.format(ContributionScreen.maxAmount));
    }
    return null;
  }

  bool get _amountValid =>
      _amountController.text.trim().isNotEmpty && _amountError == null;

  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleContribution() async {
    _unfocus();
    if (!_amountValid || _isProcessing) return;
    final amount = _amount;

    final memberId = ApiService.currentMemberId;
    if (memberId == null) {
      _snack(context.l10n.contributionSignInAgain);
      return;
    }

    if (amount > ContributionScreen.confirmAbove) {
      final ok = await AppBottomSheet.showConfirmation(
        context: context,
        title: context.l10n.contributionConfirmTitle(Inr.format(amount)),
        message: context.l10n.contributionConfirmMessage(
            Inr.format(amount), _fundTitle(_selectedFund)),
        confirmLabel: context.l10n.commonContinue,
        icon: Icons.volunteer_activism_outlined,
      );
      if (ok != true || !mounted) return;
    }

    setState(() => _isProcessing = true);
    _activeStartedAt = DateTime.now();
    _activeFund = _selectedFund;
    _activeFundTitle = _fundTitle(_selectedFund);

    final res = await _apiService.initializeContribution(
      memberId: memberId,
      amount: amount.toDouble(),
      fund: _selectedFund,
      idempotencyKey: "IDEMP_DON_${DateTime.now().millisecondsSinceEpoch}",
      note: _noteController.text,
    );
    if (!mounted) return;

    if (res == null) {
      setState(() => _isProcessing = false);
      _snack(context.l10n.payuStartFailed);
      return;
    }

    final txnId = res["transaction_id"]?.toString();
    _activeTxnId = txnId;
    _activeAmount = (res["amount"] as num?) ?? amount;

    // Backend auto-commits in test mode (PAYMENT_TEST_MODE=ON) and returns a
    // receipt directly — no gateway step.
    final directReceipt = res["receipt"];
    if (res["status"] == "SUCCESS" && directReceipt is Map) {
      setState(() => _isProcessing = false);
      _showSuccess(directReceipt.cast<String, dynamic>());
      return;
    }

    // Live path: a PENDING transaction was created. Take the member through
    // the real PayU gateway, same as monthly dues.
    if (txnId == null) {
      setState(() => _isProcessing = false);
      _snack(context.l10n.payuStartFailed);
      return;
    }
    final orderId = res["gateway_order_id"]?.toString() ?? "ORD$txnId";

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
        payUCheckoutProConfig: PayUCheckout.config(),
      );
    } catch (e) {
      debugPrint("[PAYU_SDK_ERROR] contribution checkout: $e");
      setState(() => _isProcessing = false);
      _snack(context.l10n.payuOpenFailed);
    }
  }

  void _showSuccess(Map<String, dynamic> receipt) {
    PaymentResultNav.success(
      context,
      PaymentResultArgs.fromReceipt(
        kind: PaymentKind.contribution,
        receipt: receipt,
        fallbackAmount: _activeAmount,
        // A receipt has no fund field, so the fund the member picked labels it.
        fallbackCoverage: _activeFundTitle ?? _activeFund,
        transactionId: _activeTxnId,
      ),
    );
  }

  PaymentResultArgs _args({
    String? reason,
    bool cancelled = false,
    bool gatewayReportedSuccess = false,
    String? gatewayPaymentId,
  }) =>
      PaymentResultArgs(
        kind: PaymentKind.contribution,
        at: _activeStartedAt ?? DateTime.now(),
        amount: _activeAmount,
        coverage: _activeFundTitle ?? _activeFund,
        transactionId: _activeTxnId,
        gatewayReportedSuccess: gatewayReportedSuccess,
        gatewayPaymentId: gatewayPaymentId,
        reason: reason,
        cancelled: cancelled,
      );

  // --- PayUCheckoutProProtocol ---

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
      _showSuccess(receipt.cast<String, dynamic>());
      return;
    }
    // Gateway took it, server hasn't confirmed: wait, don't retry.
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

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
      canPop: !_isProcessing,
      child: GestureDetector(
        // Tapping outside a field dismisses the keyboard.
        behavior: HitTestBehavior.translucent,
        onTap: _unfocus,
        child: AppPageScaffold(
          title: context.l10n.contributionTitle,
          eyebrow: context.l10n.contributionEyebrow,
          subtitle: context.l10n.contributionSubtitle,
          onBack: _isProcessing
              ? null
              : () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    AppNav.memberHome(context);
                  }
                },
          floatingChild: _amountCard(),
          content: [
            const SizedBox(height: AppSpacing.md),
            AppSectionHeader(title: context.l10n.contributionWhereTitle),
            for (final fund in _funds) ...[
              _fundRow(fund),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: _noteController,
                    label: context.l10n.contributionNoteLabel,
                    hint: context.l10n.contributionNoteHint,
                    maxLines: 2,
                    maxLength: 120,
                    enabled: !_isProcessing,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _unfocus(),
                  ),
                ],
              ),
            ),
          ],
          bottomBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBottomActionBar(
                applySafeArea: keyboardOpen,
                children: [
                  AppPrimaryButton(
                    label: _amountValid
                        ? context.l10n.contributionGiveAmount(Inr.format(_amount))
                        : context.l10n.contributionEnterAmount,
                    icon: Icons.favorite_rounded,
                    isLoading: _isProcessing,
                    onPressed: _amountValid ? _handleContribution : null,
                  ),
                ],
              ),
              // Contribute is not a tab: no item is highlighted. The tab bar
              // steps aside while typing so the Give button sits on the
              // keyboard.
              if (!keyboardOpen)
                IgnorePointer(
                  ignoring: _isProcessing,
                  child: const MemberBottomNavBar(currentIndex: -1),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountCard() {
    final error = _amountError;
    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionLabel(context.l10n.contributionAmountLabel),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Text(
                  '₹',
                  style:
                      context.text.amount.copyWith(color: context.colors.textMuted),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  label: context.l10n.contributionAmountSemantics,
                  textField: true,
                  child: TextField(
                    controller: _amountController,
                    enabled: !_isProcessing,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                    textInputAction: TextInputAction.done,
                    onTapOutside: (_) => _unfocus(),
                    onSubmitted: (_) => _unfocus(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(7),
                    ],
                    style: context.text.amount,
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: context.text.amount.copyWith(
                        color: context.colors.textMuted.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Divider(height: AppSpacing.lg, color: context.colors.border),
          if (error != null) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: context.text.small.copyWith(color: context.colors.error),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ] else ...[
            Text(
              context.l10n.contributionRange(
                Inr.format(ContributionScreen.minAmount),
                Inr.format(ContributionScreen.maxAmount),
              ),
              style: context.text.caption,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _quickAmounts.map(_quickChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(int amount) {
    final isActive = _amount == amount;
    return Semantics(
      button: true,
      selected: isActive,
      label: context.l10n.contributionGiveAmount(Inr.spoken(amount)),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isProcessing
              ? null
              : () {
                  _amountController.text = amount.toString();
                  _amountController.selection = TextSelection.collapsed(
                    offset: _amountController.text.length,
                  );
                },
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: isActive ? context.colors.primary : context.colors.background,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: isActive ? context.colors.primary : context.colors.border,
              ),
            ),
            child: Text(
              Inr.format(amount),
              style: context.text.buttonSmall.copyWith(
                color: isActive
                    ? context.colors.onPrimary
                    : context.colors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fundRow(_Fund fund) {
    final isSelected = fund.name == _selectedFund;
    final title = fund.title(context.l10n);
    final blurb = fund.blurb(context.l10n);

    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      label: '$title. $blurb',
      excludeSemantics: true,
      child: AppCard(
        onTap: _isProcessing
            ? null
            : () => setState(() => _selectedFund = fund.name),
        padding: const EdgeInsets.all(AppSpacing.ms),
        borderColor: isSelected ? context.colors.primary : context.colors.border,
        color: isSelected ? context.colors.primaryLight : context.colors.surface,
        child: Row(
          children: [
            AppIconChip(
              icon: fund.icon,
              color: context.colors.fg(fund.tone),
              background: isSelected
                  ? context.colors.surface
                  : context.colors.bg(fund.tone),
            ),
            const SizedBox(width: AppSpacing.ms),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.listTitle),
                  const SizedBox(height: 2),
                  Text(
                    blurb,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.small,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 21,
              color: isSelected ? context.colors.primary : context.colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

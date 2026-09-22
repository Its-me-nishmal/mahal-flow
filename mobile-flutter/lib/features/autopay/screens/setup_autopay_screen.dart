import 'package:flutter/material.dart';
import 'package:payu_checkoutpro_flutter/payu_checkoutpro_flutter.dart';
import 'package:payu_checkoutpro_flutter/PayUConstantKeys.dart';

import '../../../core/network/api_service.dart';
import '../../../core/network/payu_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';

class SetupAutoPayScreen extends StatefulWidget {
  const SetupAutoPayScreen({super.key});

  @override
  State<SetupAutoPayScreen> createState() => _SetupAutoPayScreenState();
}

class _SetupAutoPayScreenState extends State<SetupAutoPayScreen>
    implements PayUCheckoutProProtocol {
  final ApiService _apiService = ApiService();
  late final PayUCheckoutProFlutter _checkoutPro;
  bool _enabled = true;
  bool _isProcessing = false;
  // Test defaults: ₹10 per debit. Change freely; MaxAmount caps each debit.
  static const double _monthlyAmount = 10;
  static const double _maxAmount = 10;

  // Test cadences drive how often our scheduler debits. HOURLY/DAILY/MINUTELY
  // use a PayU ADHOC mandate (on-demand); MONTHLY is the real production cycle.
  static const List<String> _frequencies = ["MINUTELY", "HOURLY", "DAILY", "MONTHLY"];
  String _frequency = "MINUTELY";

  String? _activeMandateId;
  Map<String, dynamic>? _activePayUData;

  // Existing mandate state (loaded on open) — drives the Cancel button.
  bool _mandateActive = false;
  String? _existingMandateId;

  // PayU SI billingCycle for the mandate: sub-daily/daily test cadences use
  // ADHOC (no bank cycle below daily exists).
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

  @override
  void initState() {
    super.initState();
    _checkoutPro = PayUCheckoutProFlutter(this);
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await _apiService.getAutoPayStatus();
    if (!mounted || status == null) return;
    setState(() {
      _mandateActive = status["active"] == true || status["status"] == "ACTIVE";
      _existingMandateId = status["mandate_id"]?.toString();
    });
  }

  Future<void> _cancelAutoPay() async {
    setState(() => _isProcessing = true);
    final res = await _apiService.cancelAutoPayMandate(mandateId: _existingMandateId);
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (res != null && res["status"] == "CANCELLED") {
      setState(() => _mandateActive = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AutoPay cancelled. No further debits.")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't cancel AutoPay. Try again.")),
      );
    }
  }

  String _fmtDate(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _handleConfirmAutoPay() async {
    setState(() => _isProcessing = true);

    final res = await _apiService.createAutoPayMandate(
      maxAmount: _maxAmount,
      debitAmount: _monthlyAmount,
      frequency: _frequency,
    );
    if (!mounted) return;

    final mandateId = res?["mandate_id"]?.toString();
    final checkout = res?["payu_checkout"] as Map<String, dynamic>?;
    if (mandateId == null || checkout == null) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't start AutoPay setup. Try again.")),
      );
      return;
    }

    _activeMandateId = mandateId;
    _activePayUData = checkout;

    final now = DateTime.now();
    final params = (checkout["params"] as Map?)?.cast<String, dynamic>() ?? {};

    // Standing-instruction consent: a small penny-auth amount plus the SI rule
    // that authorizes future monthly debits up to the max amount.
    final payUPaymentParams = {
      PayUPaymentParamKey.key: checkout["key"],
      PayUPaymentParamKey.amount: checkout["amount"]?.toString() ?? "1.00",
      PayUPaymentParamKey.productInfo:
          checkout["productinfo"] ?? "MahalFlow AutoPay Mandate",
      PayUPaymentParamKey.firstName: checkout["firstname"] ?? "Member",
      PayUPaymentParamKey.email: checkout["email"] ?? "member@mahalflow.org",
      PayUPaymentParamKey.phone: checkout["phone"] ?? "9900990099",
      PayUPaymentParamKey.ios_surl:
          checkout["surl"] ?? "http://localhost:8080/api/v1/webhooks/pg",
      PayUPaymentParamKey.ios_furl:
          checkout["furl"] ?? "http://localhost:8080/api/v1/webhooks/pg",
      PayUPaymentParamKey.android_surl:
          checkout["surl"] ?? "http://localhost:8080/api/v1/webhooks/pg",
      PayUPaymentParamKey.android_furl:
          checkout["furl"] ?? "http://localhost:8080/api/v1/webhooks/pg",
      PayUPaymentParamKey.environment: "0", // 0 = PRODUCTION, 1 = TEST
      PayUPaymentParamKey.transactionId: checkout["txnid"] ?? mandateId,
      PayUPaymentParamKey.userCredential: "MEM_001_9910",
      PayUPaymentParamKey.additionalParam: {
        PayUAdditionalParamKeys.udf1: params["udf1"] ?? mandateId,
        PayUAdditionalParamKeys.udf2: params["udf2"] ?? "MH_001_CALICUT",
        PayUAdditionalParamKeys.udf3: params["udf3"] ?? "MEM_001_9910",
      },
      PayUPaymentParamKey.payUSIParams: {
        PayUSIParamsKeys.billingAmount: _maxAmount.toStringAsFixed(2),
        PayUSIParamsKeys.billingCurrency: "INR",
        PayUSIParamsKeys.billingCycle: _billingCycle,
        PayUSIParamsKeys.billingInterval: 1,
        PayUSIParamsKeys.paymentStartDate: _fmtDate(now),
        PayUSIParamsKeys.paymentEndDate:
            _fmtDate(DateTime(now.year + 3, now.month, now.day)),
        PayUSIParamsKeys.billingRule: "MAX",
        PayUSIParamsKeys.billingLimit: "ON",
        PayUSIParamsKeys.remarks: "MahalFlow monthly dues AutoPay",
      },
    };

    final payUCheckoutProConfig = {
      PayUCheckoutProConfigKeys.primaryColor: "#146C5B",
      PayUCheckoutProConfigKeys.secondaryColor: "#ffffff",
      PayUCheckoutProConfigKeys.merchantName: "MahalFlow Treasury",
      PayUCheckoutProConfigKeys.showExitConfirmationOnCheckoutScreen: false,
      PayUCheckoutProConfigKeys.showExitConfirmationOnPaymentScreen: false,
    };

    try {
      _checkoutPro.openCheckoutScreen(
        payUPaymentParams: payUPaymentParams,
        payUCheckoutProConfig: payUCheckoutProConfig,
      );
    } catch (e) {
      debugPrint("[PAYU_SI_ERROR] open mandate checkout: $e");
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open the mandate screen. Try again.")),
        );
      }
    }
  }

  // --- PayUCheckoutProProtocol ---

  @override
  void generateHash(Map response) async {
    final hashName = response[PayUHashConstantsKeys.hashName]?.toString() ?? "";
    final hashString =
        response[PayUHashConstantsKeys.hashString]?.toString() ?? "";
    final hashType = response[PayUHashConstantsKeys.hashType]?.toString();
    final postSalt = response[PayUHashConstantsKeys.postSalt]?.toString();

    if (hashString.isNotEmpty) {
      try {
        final generated = await _apiService.generatePayUHash(
          hashName: hashName,
          hashString: hashString,
          hashType: hashType,
          postSalt: postSalt,
        );
        if (generated != null && generated.isNotEmpty) {
          _checkoutPro.hashGenerated(hash: {hashName: generated});
          return;
        }
      } catch (e) {
        debugPrint("[PAYU_HASH_ERROR] $hashName: $e");
      }
    }

    if (_activePayUData != null &&
        _activePayUData!["hash"] != null &&
        hashName == "payment_hash") {
      _checkoutPro.hashGenerated(hash: {hashName: _activePayUData!["hash"].toString()});
    } else {
      _checkoutPro.hashGenerated(hash: {});
    }
  }

  @override
  void onPaymentSuccess(dynamic response) async {
    debugPrint("[PAYU_SI_SUCCESS] $response");
    if (_activeMandateId != null) {
      final confirmRes = await _apiService.confirmAutoPayMandate(
        mandateId: _activeMandateId!,
        gatewayPaymentId: extractMihpayid(response),
      );
      if (mounted) {
        setState(() => _isProcessing = false);
        if (confirmRes != null && confirmRes["status"] == "ACTIVE") {
          _showSuccessSheet(_activeMandateId!,
              confirmRes["next_debit"]?.toString());
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Mandate approved but activation is pending. It will confirm shortly.",
            ),
          ),
        );
        return;
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  void onPaymentFailure(dynamic response) {
    debugPrint("[PAYU_SI_FAILURE] $response");
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mandate setup failed or was cancelled.")),
      );
    }
  }

  @override
  void onPaymentCancel(Map? response) {
    debugPrint("[PAYU_SI_CANCEL] $response");
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mandate setup was cancelled.")),
      );
    }
  }

  @override
  void onError(Map? response) {
    debugPrint("[PAYU_SI_ERROR] $response");
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "AutoPay error: ${response?['errorMessage'] ?? 'Unknown error'}",
          ),
        ),
      );
    }
  }

  void _showSuccessSheet(String mandateId, String? nextDebit) {
    AppBottomSheet.show(
      context: context,
      title: 'AutoPay is on',
      subtitle: 'Your dues will be paid automatically',
      icon: Icons.check_circle_rounded,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your mandate is registered. ${Inr.format(_monthlyAmount)} will be '
            'debited on the 1st of each month, and a receipt is issued every '
            'time it runs.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.ms),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Mandate ID', style: AppTextStyles.small),
                ),
                Text(
                  mandateId,
                  style: AppTextStyles.button.copyWith(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'Done',
            onPressed: () {
              Navigator.of(ctx).pop();
              // true tells the member dashboard AutoPay setup completed
              // so it can persist the flag and hide its nudge card.
              Navigator.of(context).pop(true);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'AutoPay',
      eyebrow: 'Payments',
      subtitle: 'Never miss a month. Cancel any time from your profile.',
      floatingChild: AppCard.floating(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('MONTHLY DEBIT', style: AppTextStyles.label),
                ),
                StatusPill(
                  label: _enabled ? 'Will be on' : 'Off',
                  foreground:
                      _enabled ? AppColors.success : AppColors.textSecondary,
                  background:
                      _enabled ? AppColors.successBg : AppColors.neutralBg,
                  icon: _enabled
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_outline_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.ms),
            Text(
              Inr.format(_monthlyAmount),
              style: AppTextStyles.amount.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Debited on the 1st of every month by UPI e-Mandate.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable AutoPay',
                          style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Turn off to keep paying manually.',
                          style: AppTextStyles.small,
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                    activeTrackColor: AppColors.primary,
                    activeThumbColor: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: [
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionLabel('Test frequency'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _frequencies.map((f) {
                  final active = f == _frequency;
                  return GestureDetector(
                    onTap: () => setState(() => _frequency = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: active ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        f[0] + f.substring(1).toLowerCase(),
                        style: AppTextStyles.button.copyWith(
                          fontSize: 13,
                          color: active ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionLabel('Mandate details'),
              const SizedBox(height: AppSpacing.sm),
              const AppDetailRow(
                label: 'Payment method',
                value: 'UPI e-Mandate',
              ),
              const Divider(height: 1, color: AppColors.border),
              const AppDetailRow(
                label: 'Debit date',
                value: '1st of every month',
              ),
              const Divider(height: 1, color: AppColors.border),
              AppDetailRow(
                label: 'Amount per month',
                value: Inr.format(_monthlyAmount),
                emphasize: true,
              ),
              const Divider(height: 1, color: AppColors.border),
              const AppDetailRow(
                label: 'Cancel anytime',
                value: 'From Profile → AutoPay',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const AppNoticeCard(
          icon: Icons.info_outline_rounded,
          title: 'How it works',
          message:
              'Your bank asks you to approve the mandate once. After that each '
              'month runs on its own and issues a receipt.',
          color: AppColors.info,
          background: AppColors.infoBg,
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: _mandateActive
            ? [
                // A mandate is already active: offer to stop it (halts the
                // backend auto-debit scheduler for this member).
                AppPrimaryButton(
                  label: _isProcessing ? 'Cancelling…' : 'Cancel AutoPay',
                  icon: Icons.close_rounded,
                  isLoading: _isProcessing,
                  onPressed: _isProcessing ? null : _cancelAutoPay,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppSecondaryButton(
                  label: 'Back',
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ]
            : [
                AppPrimaryButton(
                  label: _isProcessing ? 'Setting up…' : 'Confirm AutoPay',
                  icon: Icons.check_rounded,
                  isLoading: _isProcessing,
                  onPressed: _enabled ? _handleConfirmAutoPay : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppSecondaryButton(
                  label: 'Not now',
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
      ),
    );
  }
}

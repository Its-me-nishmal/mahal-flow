import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/member_bottom_nav_bar.dart';

/// A fund a member can give to. Icon and colour are part of the definition so
/// the same fund always looks the same wherever it appears.
class _Fund {
  final String name;
  final String blurb;
  final IconData icon;
  final Color color;
  final Color background;

  const _Fund(this.name, this.blurb, this.icon, this.color, this.background);
}

class ContributionScreen extends StatefulWidget {
  const ContributionScreen({super.key});

  @override
  State<ContributionScreen> createState() => _ContributionScreenState();
}

class _ContributionScreenState extends State<ContributionScreen>
    implements PayUCheckoutProProtocol {
  final ApiService _apiService = ApiService();
  late final PayUCheckoutProFlutter _checkoutPro;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Held across the PayU checkout lifecycle so the success callback can confirm
  // the right transaction and show the correct receipt/amount.
  String? _activeTxnId;
  Map<String, dynamic>? _activePayUData;
  double _activeAmount = 0;

  static const List<_Fund> _funds = [
    _Fund('Zakat Fund', 'Obligatory charity, distributed by the committee',
        Icons.volunteer_activism_outlined, AppColors.warning, AppColors.warningBg),
    _Fund('General Fund', 'Day-to-day running of the Mahal',
        Icons.account_balance_wallet_outlined, AppColors.primary, AppColors.primaryLight),
    _Fund('Masjid Renovation', 'Building works and maintenance',
        Icons.mosque_outlined, AppColors.info, AppColors.infoBg),
    _Fund('Education Help', 'Madrasa and student support',
        Icons.school_outlined, AppColors.success, AppColors.successBg),
    _Fund('Medical Aid', 'Emergency help for families in need',
        Icons.medical_services_outlined, AppColors.error, AppColors.errorBg),
  ];

  static const List<int> _quickAmounts = [500, 1000, 2000, 5000];

  String _selectedFund = _funds.first.name;
  bool _isProcessing = false;
  String? _amountError;

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

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  Future<void> _handleContribution() async {
    final amount = _amount;
    if (amount <= 0) {
      setState(() => _amountError = 'Enter an amount to contribute');
      return;
    }

    setState(() {
      _amountError = null;
      _isProcessing = true;
    });

    final idempKey = "IDEMP_DON_${DateTime.now().millisecondsSinceEpoch}";
    final res = await _apiService.initializeContribution(
      memberId: "MEM_001_9910",
      amount: amount,
      fund: _selectedFund,
      idempotencyKey: idempKey,
    );

    if (!mounted) return;

    if (res == null) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't reach the server. Your card was not charged."),
        ),
      );
      return;
    }

    // Backend auto-commits in test mode (PAYMENT_TEST_MODE=ON) and returns a
    // receipt directly — no gateway step. Show the receipt as before.
    if (res["status"] == "SUCCESS") {
      setState(() => _isProcessing = false);
      final receipt = res["receipt"] as Map<String, dynamic>?;
      final receiptNum = receipt?["receipt_number"]?.toString() ??
          res["transaction_id"]?.toString() ??
          "Verified";
      _showSuccessSheet(amount, receiptNum);
      return;
    }

    // Live path: a PENDING transaction was created. Take the member through the
    // real PayU gateway, same as monthly dues.
    final txnId = res["transaction_id"] as String?;
    if (txnId == null) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't start the payment. Try again.")),
      );
      return;
    }

    _activeTxnId = txnId;
    _activeAmount = amount;
    final orderId = res["gateway_order_id"] as String? ?? "ORD$txnId";

    final payUData = await _apiService.getPayUCheckoutData(orderId);
    _activePayUData = payUData;
    if (!mounted) return;

    if (payUData == null) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the payment screen. Try again.")),
      );
      return;
    }

    final payUPaymentParams = {
      PayUPaymentParamKey.key: payUData["key"],
      PayUPaymentParamKey.amount:
          payUData["amount"]?.toString() ?? amount.toStringAsFixed(2),
      PayUPaymentParamKey.productInfo: payUData["productinfo"] ?? "Mahal Contribution",
      PayUPaymentParamKey.firstName: payUData["firstname"] ?? "Member",
      PayUPaymentParamKey.email: payUData["email"] ?? "member@mahalflow.org",
      PayUPaymentParamKey.phone: payUData["phone"] ?? "9900990099",
      PayUPaymentParamKey.ios_surl:
          payUData["surl"] ?? "http://localhost:8080/api/v1/webhooks/pg",
      PayUPaymentParamKey.ios_furl:
          payUData["furl"] ?? "http://localhost:8080/api/v1/webhooks/pg",
      PayUPaymentParamKey.android_surl:
          payUData["surl"] ?? "http://localhost:8080/api/v1/webhooks/pg",
      PayUPaymentParamKey.android_furl:
          payUData["furl"] ?? "http://localhost:8080/api/v1/webhooks/pg",
      PayUPaymentParamKey.environment: "0", // 0 = PRODUCTION, 1 = TEST
      PayUPaymentParamKey.transactionId: orderId,
      PayUPaymentParamKey.userCredential: "MEM_001_9910",
      PayUPaymentParamKey.additionalParam: {
        PayUAdditionalParamKeys.udf1: payUData["udf1"] ?? txnId,
        PayUAdditionalParamKeys.udf2: payUData["udf2"] ?? "MH_001_CALICUT",
        PayUAdditionalParamKeys.udf3: payUData["udf3"] ?? "MEM_001_9910",
      },
    };

    final payUCheckoutProConfig = {
      PayUCheckoutProConfigKeys.primaryColor: "#146C5B",
      PayUCheckoutProConfigKeys.secondaryColor: "#ffffff",
      PayUCheckoutProConfigKeys.merchantName: "MahalFlow Treasury",
      PayUCheckoutProConfigKeys.showExitConfirmationOnCheckoutScreen: false,
      PayUCheckoutProConfigKeys.showExitConfirmationOnPaymentScreen: false,
      PayUCheckoutProConfigKeys.upiAppsOrder: "gpay|phonepe|paytm",
    };

    try {
      _checkoutPro.openCheckoutScreen(
        payUPaymentParams: payUPaymentParams,
        payUCheckoutProConfig: payUCheckoutProConfig,
      );
    } catch (e) {
      debugPrint("[PAYU_SDK_ERROR] contribution checkout: $e");
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't open the payment screen. Try again.")),
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
    debugPrint("[PAYU_NATIVE_SUCCESS] $response");
    if (_activeTxnId != null) {
      final confirmRes = await _apiService.confirmPayment(
        _activeTxnId!,
        gatewayPaymentId: extractMihpayid(response),
      );
      if (mounted) {
        setState(() => _isProcessing = false);
        if (confirmRes != null && confirmRes["status"] == "SUCCESS") {
          final receipt = confirmRes["receipt"] as Map<String, dynamic>?;
          final receiptNum = receipt?["receipt_number"]?.toString() ?? "Verified";
          _showSuccessSheet(_activeAmount, receiptNum);
          return;
        }
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  void onPaymentFailure(dynamic response) {
    debugPrint("[PAYU_NATIVE_FAILURE] $response");
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment failed or was cancelled.")),
      );
    }
  }

  @override
  void onPaymentCancel(Map? response) {
    debugPrint("[PAYU_NATIVE_CANCEL] $response");
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment was cancelled.")),
      );
    }
  }

  @override
  void onError(Map? response) {
    debugPrint("[PAYU_NATIVE_ERROR] $response");
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Payment error: ${response?['errorMessage'] ?? 'Unknown error'}",
          ),
        ),
      );
    }
  }

  void _showSuccessSheet(double amount, String receiptNum) {
    AppBottomSheet.show(
      context: context,
      title: 'Contribution received',
      subtitle: 'Given to $_selectedFund',
      icon: Icons.check_circle_rounded,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Column(
                children: [
                  Text('AMOUNT GIVEN', style: AppTextStyles.label),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Inr.format(amount),
                    style: AppTextStyles.amount.copyWith(
                      fontSize: 30,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppDetailRow(label: 'Receipt number', value: receiptNum),
            const Divider(height: 1, color: AppColors.border),
            AppDetailRow(label: 'Fund', value: _selectedFund),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Back to Home',
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/member/dashboard',
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Contribute',
      eyebrow: 'Give',
      subtitle: 'Support the Mahal beyond your monthly dues.',
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/member/dashboard');
        }
      },
      floatingChild: _amountCard(),
      content: [
        const SizedBox(height: AppSpacing.md),
        const AppSectionHeader(title: 'Where should it go?'),
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
                label: 'Note (optional)',
                hint: 'e.g. In memory of family, Eid charity',
                maxLines: 2,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ],
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBottomActionBar(
            applySafeArea: false,
            children: [
              AppPrimaryButton(
                label: _amount > 0
                    ? 'Give ${Inr.format(_amount)}'
                    : 'Enter an amount',
                icon: Icons.favorite_rounded,
                isLoading: _isProcessing,
                onPressed: _amount > 0 ? _handleContribution : null,
              ),
            ],
          ),
          const MemberBottomNavBar(currentIndex: 1),
        ],
      ),
    );
  }

  Widget _amountCard() {
    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionLabel('Contribution amount'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '₹',
                style: AppTextStyles.amount.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(7),
                  ],
                  style: AppTextStyles.amount,
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: AppTextStyles.amount.copyWith(
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (_) {
                    if (_amountError != null) {
                      setState(() => _amountError = null);
                    }
                  },
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.border),
          if (_amountError != null) ...[
            Text(
              _amountError!,
              style: AppTextStyles.small.copyWith(color: AppColors.error),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _amountController.text = amount.toString(),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            Inr.format(amount),
            style: AppTextStyles.button.copyWith(
              fontSize: 13,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _fundRow(_Fund fund) {
    final isSelected = fund.name == _selectedFund;

    return AppCard(
      onTap: () => setState(() => _selectedFund = fund.name),
      padding: const EdgeInsets.all(AppSpacing.md - 2),
      borderColor: isSelected ? AppColors.primary : AppColors.border,
      color: isSelected ? AppColors.primaryLight : AppColors.surface,
      child: Row(
        children: [
          AppIconChip(
            icon: fund.icon,
            color: fund.color,
            background: isSelected ? AppColors.surface : fund.background,
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fund.name,
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  fund.blurb,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small,
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
            color: isSelected ? AppColors.primary : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

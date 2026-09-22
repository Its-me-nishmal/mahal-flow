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
import '../../../core/widgets/member_bottom_nav_bar.dart';
import '../../../core/widgets/shimmer_loading.dart';

class DueMonthItem {
  final String monthKey;
  final String displayName;
  final double amount;
  final String status;
  bool isSelected;

  DueMonthItem({
    required this.monthKey,
    required this.displayName,
    required this.amount,
    required this.status,
    this.isSelected = true,
  });
}

class MonthlyPaymentScreen extends StatefulWidget {
  const MonthlyPaymentScreen({super.key});

  @override
  State<MonthlyPaymentScreen> createState() => _MonthlyPaymentScreenState();
}

class _MonthlyPaymentScreenState extends State<MonthlyPaymentScreen>
    implements PayUCheckoutProProtocol {
  final ApiService _apiService = ApiService();
  late final PayUCheckoutProFlutter _checkoutPro;
  bool _isProcessing = false;
  bool _isLoading = true;
  List<DueMonthItem> _months = [];
  String? _activeTxnId;
  List<String> _activeSelectedKeys = [];
  Map<String, dynamic>? _activePayUData;

  @override
  void initState() {
    super.initState();
    _checkoutPro = PayUCheckoutProFlutter(this);
    _loadUnpaidMonths();
  }

  Future<void> _loadUnpaidMonths() async {
    final data = await _apiService.getMemberDashboard();
    String lastPaid = data?["last_paid_month"]?.toString() ?? "2026-07";

    DateTime nextMonthDate;
    try {
      final parts = lastPaid.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      nextMonthDate = DateTime(year, month + 1, 1);
    } catch (_) {
      nextMonthDate = DateTime(2026, 8, 1);
    }

    const monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];

    final now = DateTime.now();
    List<DueMonthItem> generated = [];
    for (int i = 0; i < 3; i++) {
      final d = DateTime(nextMonthDate.year, nextMonthDate.month + i, 1);
      final key = "${d.year}-${d.month.toString().padLeft(2, '0')}";
      final name = "${monthNames[d.month - 1]} ${d.year}";

      String status;
      if (d.year < now.year || (d.year == now.year && d.month < now.month)) {
        status = "OVERDUE";
      } else if (d.year == now.year && d.month == now.month) {
        status = "DUE_NOW";
      } else {
        status = "UPCOMING";
      }

      generated.add(
        DueMonthItem(
          monthKey: key,
          displayName: name,
          amount: 500.0,
          status: status,
          isSelected: i == 0,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _months = generated;
        _isLoading = false;
      });
    }
  }

  bool get _isAllSelected =>
      _months.isNotEmpty && _months.every((m) => m.isSelected);
  int get _selectedCount => _months.where((m) => m.isSelected).length;
  double get _totalAmount =>
      _months.where((m) => m.isSelected).fold(0, (sum, m) => sum + m.amount);

  void _toggleSelectAll(bool? val) {
    setState(() {
      final target = val ?? false;
      for (var m in _months) {
        m.isSelected = target;
      }
    });
  }

  void _toggleMonth(int index, bool? val) {
    setState(() {
      _months[index].isSelected = val ?? false;
    });
  }

  Future<void> _handlePayment() async {
    final selectedKeys =
        _months.where((m) => m.isSelected).map((m) => m.monthKey).toList();
    if (selectedKeys.isEmpty) return;

    setState(() => _isProcessing = true);

    final idempKey = "IDEMP_${DateTime.now().millisecondsSinceEpoch}";
    final initRes = await _apiService.initializeDuesPayment(
      memberId: "MEM_001_9910",
      selectedMonths: selectedKeys,
      idempotencyKey: idempKey,
      gateway: "PAYU",
    );

    if (initRes != null && initRes["transaction_id"] != null) {
      final txnId = initRes["transaction_id"] as String;
      final orderId = initRes["gateway_order_id"] as String? ?? "ORD_$txnId";

      _activeTxnId = txnId;
      _activeSelectedKeys = selectedKeys;

      // Fetch PayU parameters and hash
      final payUData = await _apiService.getPayUCheckoutData(orderId);
      _activePayUData = payUData;

      if (payUData != null) {
        final payUPaymentParams = {
          PayUPaymentParamKey.key: payUData["key"] ?? "XiiFzG",
          PayUPaymentParamKey.amount: payUData["amount"]?.toString() ??
              _totalAmount.toStringAsFixed(2),
          PayUPaymentParamKey.productInfo: payUData["productinfo"] ?? "Mahal Dues",
          PayUPaymentParamKey.firstName: payUData["firstname"] ?? "Member",
          PayUPaymentParamKey.email: payUData["email"] ?? "member@mahalflow.org",
          PayUPaymentParamKey.phone: payUData["phone"] ?? "+919847111222",
          PayUPaymentParamKey.ios_surl: payUData["surl"] ??
              "http://localhost:8080/api/v1/webhooks/pg",
          PayUPaymentParamKey.ios_furl: payUData["furl"] ??
              "http://localhost:8080/api/v1/webhooks/pg",
          PayUPaymentParamKey.android_surl: payUData["surl"] ??
              "http://localhost:8080/api/v1/webhooks/pg",
          PayUPaymentParamKey.android_furl: payUData["furl"] ??
              "http://localhost:8080/api/v1/webhooks/pg",
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
          PayUCheckoutProConfigKeys.enforcePaymentList: [
            {"payment_type": "UPI", "payment_option": "INTENT"},
          ],
        };

        try {
          _checkoutPro.openCheckoutScreen(
            payUPaymentParams: payUPaymentParams,
            payUCheckoutProConfig: payUCheckoutProConfig,
          );
          return;
        } catch (e) {
          debugPrint("[PAYU_SDK_ERROR] Failed to open native checkout: $e");
        }
      }
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the payment screen. Try again.")),
      );
    }
  }

  // --- PayUCheckoutProProtocol Implementation ---

  @override
  void generateHash(Map response) async {
    // PayU native SDK queries hash during payment lifecycle
    final hashName = response[PayUHashConstantsKeys.hashName]?.toString() ?? "";
    final hashString =
        response[PayUHashConstantsKeys.hashString]?.toString() ?? "";
    final hashType = response[PayUHashConstantsKeys.hashType]?.toString();
    final postSalt = response[PayUHashConstantsKeys.postSalt]?.toString();
    debugPrint(
        "[PAYU_HASH_REQ] Requesting hash: $hashName, string: $hashString, type: $hashType");

    if (hashString.isNotEmpty) {
      try {
        final generated = await _apiService.generatePayUHash(
          hashName: hashName,
          hashString: hashString,
          hashType: hashType,
          postSalt: postSalt,
        );
        if (generated != null && generated.isNotEmpty) {
          debugPrint("[PAYU_HASH_SUCCESS] Generated $hashName: $generated");
          _checkoutPro.hashGenerated(hash: {hashName: generated});
          return;
        }
      } catch (e) {
        debugPrint("[PAYU_HASH_ERROR] Error generating hash for $hashName: $e");
      }
    }

    // Fallback if hash calculation fails or primary hash present
    if (_activePayUData != null &&
        _activePayUData!["hash"] != null &&
        hashName == "payment_hash") {
      final hash = _activePayUData!["hash"].toString();
      _checkoutPro.hashGenerated(hash: {hashName: hash});
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
          final receiptNum = receipt?["receipt_number"] ?? "Verified";
          _showSuccessSheet(receiptNum);
          return;
        }
      }
    }
    if (mounted) {
      setState(() => _isProcessing = false);
    }
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

  void _showSuccessSheet(String receiptNum) {
    AppBottomSheet.show(
      context: context,
      title: "Payment successful",
      subtitle: "Issued by MahalFlow Treasury",
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
                  Text('AMOUNT PAID', style: AppTextStyles.label),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Inr.format(_totalAmount),
                    style: AppTextStyles.amount.copyWith(
                      fontSize: 30,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppDetailRow(label: 'Receipt number', value: receiptNum.toString()),
            const Divider(height: 1, color: AppColors.border),
            AppDetailRow(
              label: 'Months credited',
              value: _activeSelectedKeys.join(', '),
            ),
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

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dues are ₹500 per month. Contact the office for changes.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Monthly Dues',
      eyebrow: 'Payments',
      subtitle: 'Choose the months you want to clear.',
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed('/member/dashboard');
        }
      },
      actions: [
        AppHeaderIconButton(
          icon: Icons.help_outline_rounded,
          tooltip: 'Help',
          onTap: _showHelp,
        ),
      ],
      floatingChild: _summaryCard(),
      content: [
        const SizedBox(height: AppSpacing.md),
        if (_isLoading) _skeleton() else _monthsCard(),
        const SizedBox(height: AppSpacing.md),
        AppNoticeCard(
          icon: Icons.volunteer_activism_outlined,
          title: 'Make a contribution',
          message: 'Zakat, Masjid or the general fund.',
          color: AppColors.warning,
          background: AppColors.warningBg,
          actionLabel: 'Open',
          onAction: () =>
              Navigator.of(context).pushNamed('/member/contribution'),
        ),
      ],
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBottomActionBar(
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
                          _selectedCount == 1
                              ? '1 month selected'
                              : '$_selectedCount months selected',
                          style: AppTextStyles.small,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Inr.format(_totalAmount),
                          style: AppTextStyles.sectionTitle.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'No processing fee',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.ms),
              AppPrimaryButton(
                label: _isProcessing
                    ? 'Processing…'
                    : 'Pay ${Inr.format(_totalAmount)}',
                icon: Icons.lock_rounded,
                isLoading: _isProcessing,
                onPressed: _selectedCount == 0 ? null : _handlePayment,
              ),
            ],
          ),
          const MemberBottomNavBar(currentIndex: 1),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('TOTAL SELECTED', style: AppTextStyles.label)),
              if (_selectedCount > 0)
                StatusPill(
                  label: _selectedCount == 1
                      ? '1 month'
                      : '$_selectedCount months',
                  foreground: AppColors.primary,
                  background: AppColors.primaryLight,
                  icon: Icons.event_available_rounded,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.ms),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Inr.format(_totalAmount),
              semanticsLabel: 'Total ${Inr.spoken(_totalAmount)}',
              style: AppTextStyles.amount.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _selectedCount == 0
                ? 'Select at least one month below to continue.'
                : 'Dues are ₹500 per month. Paying ahead is credited forward.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _monthsCard() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.ms + 2,
              AppSpacing.sm,
              AppSpacing.ms - 2,
            ),
            child: Row(
              children: [
                Expanded(child: Text('UNPAID MONTHS', style: AppTextStyles.label)),
                Text('Select all', style: AppTextStyles.small),
                Checkbox(
                  value: _isAllSelected,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.xs + 1),
                  ),
                  onChanged: _toggleSelectAll,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...List.generate(_months.length, (index) {
            final item = _months[index];
            final isLast = index == _months.length - 1;

            return DecoratedBox(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
              ),
              child: InkWell(
                onTap: () => _toggleMonth(index, !item.isSelected),
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
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.xs + 1),
                        ),
                        onChanged: (v) => _toggleMonth(index, v),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayName,
                              style: AppTextStyles.cardTitle.copyWith(
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs + 1),
                            _statusPill(item.status),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        Inr.format(item.amount),
                        style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    switch (status) {
      case 'OVERDUE':
        return const StatusPill(
          label: 'Overdue',
          foreground: AppColors.error,
          background: AppColors.errorBg,
          icon: Icons.error_outline_rounded,
        );
      case 'DUE_NOW':
      case 'DUE_SOON':
        return const StatusPill(
          label: 'Due now',
          foreground: AppColors.warning,
          background: AppColors.warningBg,
          icon: Icons.schedule_rounded,
        );
      default:
        return const StatusPill(
          label: 'Upcoming',
          foreground: AppColors.textSecondary,
          background: AppColors.neutralBg,
          icon: Icons.event_outlined,
        );
    }
  }

  Widget _skeleton() {
    return ShimmerLoading(
      child: Column(
        children: [
          Container(
            height: 230,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
        ],
      ),
    );
  }
}

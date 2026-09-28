import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/app_card.dart';
import '../payment_result_args.dart';
import '../widgets/payment_result_view.dart';
import 'payment_failed_screen.dart';
import 'payment_success_screen.dart';

/// The gateway took the member's money (or may have) but the server has not
/// confirmed it yet. Polls `GET /payments/:id/status` — and, when PayU
/// reported success, retries the server confirmation — until the payment
/// settles, then moves on to the success or failed screen.
class PaymentPendingScreen extends StatefulWidget {
  final PaymentResultArgs args;

  /// Seconds between automatic checks.
  final Duration pollInterval;

  /// Stop polling automatically after this many checks; the member can still
  /// check again by hand.
  final int maxAutoChecks;

  const PaymentPendingScreen({
    super.key,
    required this.args,
    this.pollInterval = const Duration(seconds: 5),
    this.maxAutoChecks = 24,
  });

  @override
  State<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends State<PaymentPendingScreen> {
  final ApiService _api = ApiService();
  Timer? _timer;
  bool _checking = false;
  int _checks = 0;
  DateTime? _lastChecked;
  String? _lastError;

  PaymentResultArgs get _args => widget.args;

  @override
  void initState() {
    super.initState();
    if (_args.transactionId != null) {
      _scheduleNext(immediate: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleNext({bool immediate = false}) {
    _timer?.cancel();
    if (_checks >= widget.maxAutoChecks) return;
    _timer = Timer(immediate ? Duration.zero : widget.pollInterval, _check);
  }

  static Map<String, dynamic>? _receiptOf(Map<String, dynamic>? res) {
    final r = res?['receipt'];
    return r is Map ? r.cast<String, dynamic>() : null;
  }

  Future<void> _check() async {
    final txnId = _args.transactionId;
    if (txnId == null || _checking || !mounted) return;
    setState(() => _checking = true);
    _checks++;

    Map<String, dynamic>? receipt;
    String? status;
    try {
      // PayU said the payment succeeded: ask the server to commit it again
      // (idempotent — a committed transaction returns its receipt).
      if (_args.gatewayReportedSuccess) {
        final confirm = await _api.confirmPayment(
          txnId,
          gatewayPaymentId: _args.gatewayPaymentId,
        );
        if (confirm?['status'] == 'SUCCESS') receipt = _receiptOf(confirm);
      }
      if (receipt == null) {
        final res = await _api.checkPaymentStatusOrThrow(txnId);
        status = res['status']?.toString();
        if (status == 'SUCCESS') receipt = _receiptOf(res);
      }
      _lastError = null;
    } on ApiException catch (e) {
      _lastError = e.userMessage;
    }
    if (!mounted) return;

    if (receipt != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.memberPaymentSuccess),
        builder: (_) => PaymentSuccessScreen(
          args: PaymentResultArgs.fromReceipt(
            kind: _args.kind,
            receipt: receipt!,
            fallbackAmount: _args.amount,
            fallbackCoverage: _args.coverage,
            transactionId: txnId,
          ),
        ),
      ));
      return;
    }

    // Only an explicit gateway failure ends the wait; anything else (an
    // unknown message, a network error) keeps the payment pending.
    final upper = status?.toUpperCase() ?? '';
    if (!_args.gatewayReportedSuccess &&
        (upper.contains('FAIL') || upper.contains('DECLINED'))) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.memberPaymentFailed),
        builder: (_) => PaymentFailedScreen(
          args: PaymentResultArgs(
            kind: _args.kind,
            at: _args.at,
            amount: _args.amount,
            coverage: _args.coverage,
            transactionId: txnId,
            reason: status,
          ),
        ),
      ));
      return;
    }

    setState(() {
      _checking = false;
      _lastChecked = DateTime.now();
    });
    _scheduleNext();
  }

  void _checkNow() {
    _timer?.cancel();
    // A manual check restarts the automatic budget.
    _checks = 0;
    _check();
  }

  @override
  Widget build(BuildContext context) {
    final canCheck = _args.transactionId != null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) AppNav.memberHome(context);
      },
      child: PaymentResultView(
        headline: 'Payment pending',
        // Telling the member not to retry is the whole point of this screen:
        // a second attempt while the first settles creates a double charge.
        message: 'Your bank is still confirming this. Do not pay again — we '
            'will update your ${_args.kind == PaymentKind.dues ? 'dues' : 'receipts'} '
            'as soon as it clears.',
        amount: Inr.formatAny(_args.amount),
        icon: Icons.schedule_rounded,
        color: context.colors.warning,
        background: context.colors.warningBg,
        statusLabel: 'Pending',
        primaryLabel: canCheck ? 'Check Again' : 'Back to Home',
        primaryIcon: canCheck ? Icons.refresh_rounded : Icons.home_rounded,
        primaryLoading: _checking,
        onPrimary: canCheck ? _checkNow : () => AppNav.memberHome(context),
        secondaryLabel: canCheck ? 'Back to Home' : 'View Receipts',
        onSecondary: canCheck
            ? () => AppNav.memberHome(context)
            : () => AppNav.switchMemberTab(context, AppRoutes.memberReceipts),
        details: [
          if (_args.coverage != null) ...[
            AppDetailRow(
              label: _args.kind == PaymentKind.dues ? 'Covers' : 'Fund',
              value: _args.coverage!,
            ),
            Divider(height: 1, color: context.colors.border),
          ],
          AppDetailRow(
              label: 'Started', value: AppDate.formatDateTime(_args.at)),
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
            label: 'Last checked',
            value: _checking
                ? 'Checking…'
                : AppDate.formatTime(_lastChecked, fallback: '—'),
          ),
        ],
        footer: [
          if (_lastError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppNoticeCard(
                icon: Icons.cloud_off_rounded,
                title: "Couldn't check the status",
                message: _lastError!,
                color: context.colors.error,
                background: context.colors.errorBg,
              ),
            ),
          AppNoticeCard(
            icon: Icons.info_outline_rounded,
            title: 'What happens next',
            message: 'Most payments clear within a few minutes. If money left '
                'your account and this does not clear, your bank reverses it '
                'or the office can confirm it from the receipt list.',
            color: context.colors.info,
            background: context.colors.infoBg,
          ),
        ],
      ),
    );
  }
}

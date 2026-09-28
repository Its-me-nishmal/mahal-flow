import 'package:flutter/material.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/utils/dues_period.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../utils/admin_format.dart';

/// Receipt details for the committee, loaded from GET /receipts/:number, with
/// an on-demand ledger signature check (GET /receipts/:number/verify).
class ReceiptSheet {
  ReceiptSheet._();

  static Future<void> show(BuildContext context, String receiptNumber) {
    return AppBottomSheet.show(
      context: context,
      title: 'Receipt',
      subtitle: 'Signed entry in the Mahal ledger',
      icon: Icons.verified_outlined,
      builder: (ctx, _) => _ReceiptBody(receiptNumber: receiptNumber),
    );
  }
}

enum _VerifyState { idle, checking, valid, mismatch, failed }

class _ReceiptBody extends StatefulWidget {
  final String receiptNumber;
  const _ReceiptBody({required this.receiptNumber});

  @override
  State<_ReceiptBody> createState() => _ReceiptBodyState();
}

class _ReceiptBodyState extends State<_ReceiptBody> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _receipt;
  ApiException? _loadError;
  bool _loading = true;

  _VerifyState _verify = _VerifyState.idle;
  String? _verifyError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final r = await _api.getReceiptOrThrow(widget.receiptNumber);
      if (!mounted) return;
      setState(() {
        _receipt = r;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e;
        _loading = false;
      });
    }
  }

  Future<void> _runVerify() async {
    setState(() {
      _verify = _VerifyState.checking;
      _verifyError = null;
    });
    try {
      final res =
          await _api.verifyReceiptCryptographicOrThrow(widget.receiptNumber);
      if (!mounted) return;
      setState(() => _verify = res['cryptographic_valid'] == true
          ? _VerifyState.valid
          : _VerifyState.mismatch);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _verify = _VerifyState.failed;
        _verifyError = e.userMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ShimmerLoading(
        semanticsLabel: 'Loading receipt',
        child: Column(
          children: [
            ShimmerCardSkeleton(height: 44),
            ShimmerCardSkeleton(height: 44),
            ShimmerCardSkeleton(height: 44),
          ],
        ),
      );
    }
    if (_loadError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppNoticeCard(
            icon: Icons.cloud_off_rounded,
            title: "Couldn't load this receipt",
            message: _loadError!.userMessage,
            color: context.colors.error,
            background: context.colors.errorBg,
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            label: 'Try again',
            icon: Icons.refresh_rounded,
            onPressed: _load,
          ),
        ],
      );
    }

    final r = _receipt!;
    final months = (r['paid_months'] is List)
        ? (r['paid_months'] as List).map((e) => e.toString()).toList()
        : const <String>[];
    final coverage = DuesPeriod.paidMonthsLabel(months);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDetailRow(
          label: 'Receipt number',
          value: r['receipt_number']?.toString() ?? widget.receiptNumber,
          emphasize: true,
        ),
        Divider(height: 1, color: context.colors.border),
        AppDetailRow(
          label: 'Payer',
          value: _orDash(r['member_name']),
        ),
        Divider(height: 1, color: context.colors.border),
        AppDetailRow(label: 'Amount', value: Inr.formatAny(r['amount'])),
        Divider(height: 1, color: context.colors.border),
        AppDetailRow(
          label: 'Type',
          value: AdminFormat.paymentType(r['payment_type']?.toString()),
        ),
        if (coverage.isNotEmpty) ...[
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(label: 'Months', value: coverage),
        ],
        Divider(height: 1, color: context.colors.border),
        AppDetailRow(
          label: 'Date',
          value: AppDate.formatDateTime(r['created_at']),
        ),
        Divider(height: 1, color: context.colors.border),
        AppDetailRow(
          label: 'Ledger hash',
          value: AdminFormat.shortHash(r['receipt_hash']?.toString()),
        ),
        const SizedBox(height: AppSpacing.md),
        _verifyResult(),
        const SizedBox(height: AppSpacing.md),
        AppPrimaryButton(
          label: _verify == _VerifyState.idle
              ? 'Verify on ledger'
              : 'Verify again',
          icon: Icons.verified_rounded,
          isLoading: _verify == _VerifyState.checking,
          onPressed: _verify == _VerifyState.checking ? null : _runVerify,
        ),
      ],
    );
  }

  Widget _verifyResult() {
    switch (_verify) {
      case _VerifyState.idle:
      case _VerifyState.checking:
        return const SizedBox.shrink();
      case _VerifyState.valid:
        return AppNoticeCard(
          icon: Icons.verified_rounded,
          title: 'Signature valid',
          message: 'The recomputed hash matches — this receipt has not been '
              'altered.',
          color: context.colors.success,
          background: context.colors.successBg,
        );
      case _VerifyState.mismatch:
        return AppNoticeCard(
          icon: Icons.gpp_bad_rounded,
          title: 'Signature mismatch',
          message: 'The stored hash does not match the receipt contents. '
              'Report this to the committee before relying on it.',
          color: context.colors.error,
          background: context.colors.errorBg,
        );
      case _VerifyState.failed:
        return AppNoticeCard(
          icon: Icons.cloud_off_rounded,
          title: "Couldn't verify",
          message: _verifyError ?? 'Try again.',
          color: context.colors.warning,
          background: context.colors.warningBg,
        );
    }
  }

  static String _orDash(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? '—' : s;
  }
}

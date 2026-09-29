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
import '../../../l10n/l10n.dart';
import '../../receipts/receipt_view.dart';
import '../utils/admin_format.dart';

/// Receipt details for the committee, loaded from GET /receipts/:number, with
/// an on-demand ledger signature check (GET /receipts/:number/verify).
class ReceiptSheet {
  ReceiptSheet._();

  static Future<void> show(BuildContext context, String receiptNumber) {
    return AppBottomSheet.show(
      context: context,
      title: context.l10n.receiptSheetTitle,
      subtitle: context.l10n.receiptSheetSubtitle,
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
    final l10n = context.l10n;
    if (_loading) {
      return ShimmerLoading(
        semanticsLabel: l10n.receiptSheetLoading,
        child: const Column(
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
            title: l10n.receiptSheetLoadError,
            message: _loadError!.userMessage,
            color: context.colors.error,
            background: context.colors.errorBg,
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            label: l10n.receiptSheetTryAgain,
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
    // Status / gateway / method / fund / note, with fallbacks for receipts
    // issued before the server stored them.
    final view = ReceiptView.fromJson(r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDetailRow(
          label: l10n.receiptSheetNumber,
          value: r['receipt_number']?.toString() ?? widget.receiptNumber,
          emphasize: true,
        ),
        Divider(height: 1, color: context.colors.border),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.receiptSheetStatus,
                    style: context.text.small),
              ),
              StatusPill.forStatus(context, view.status),
            ],
          ),
        ),
        if (view.isRefunded && view.refundedAt != null) ...[
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(
            label: l10n.receiptRefundedOnLabel,
            value: AppDate.formatDateTime(view.refundedAt),
          ),
        ],
        Divider(height: 1, color: context.colors.border),
        AppDetailRow(
          label: l10n.receiptSheetPayer,
          value: _orDash(r['member_name']),
        ),
        Divider(height: 1, color: context.colors.border),
        AppDetailRow(label: l10n.receiptSheetAmount, value: Inr.formatAny(r['amount'])),
        Divider(height: 1, color: context.colors.border),
        AppDetailRow(
          label: l10n.receiptSheetType,
          value: AdminFormat.paymentType(r['payment_type']?.toString()),
        ),
        if (coverage.isNotEmpty) ...[
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(label: l10n.receiptSheetMonths, value: coverage),
        ],
        if (!view.isDues && view.fund != null) ...[
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(label: l10n.receiptFundLabel, value: view.fund!),
        ],
        Divider(height: 1, color: context.colors.border),
        AppDetailRow(label: l10n.receiptPaidViaLabel, value: view.methodLabel),
        if (view.note != null) ...[
          Divider(height: 1, color: context.colors.border),
          AppDetailRow(label: l10n.receiptNoteLabel, value: view.note!),
        ],
        Divider(height: 1, color: context.colors.border),
        AppDetailRow(
          label: l10n.receiptSheetDate,
          value: AppDate.formatDateTime(r['created_at']),
        ),
        Divider(height: 1, color: context.colors.border),
        AppDetailRow(
          label: l10n.receiptSheetHash,
          value: AdminFormat.shortHash(r['receipt_hash']?.toString()),
        ),
        const SizedBox(height: AppSpacing.md),
        _verifyResult(),
        const SizedBox(height: AppSpacing.md),
        AppPrimaryButton(
          label: _verify == _VerifyState.idle
              ? l10n.receiptSheetVerify
              : l10n.receiptSheetVerifyAgain,
          icon: Icons.verified_rounded,
          isLoading: _verify == _VerifyState.checking,
          onPressed: _verify == _VerifyState.checking ? null : _runVerify,
        ),
      ],
    );
  }

  Widget _verifyResult() {
    final l10n = context.l10n;
    switch (_verify) {
      case _VerifyState.idle:
      case _VerifyState.checking:
        return const SizedBox.shrink();
      case _VerifyState.valid:
        return AppNoticeCard(
          icon: Icons.verified_rounded,
          title: l10n.receiptSheetValid,
          message: l10n.receiptSheetValidDesc,
          color: context.colors.success,
          background: context.colors.successBg,
        );
      case _VerifyState.mismatch:
        return AppNoticeCard(
          icon: Icons.gpp_bad_rounded,
          title: l10n.receiptSheetMismatch,
          message: l10n.receiptSheetMismatchDesc,
          color: context.colors.error,
          background: context.colors.errorBg,
        );
      case _VerifyState.failed:
        return AppNoticeCard(
          icon: Icons.cloud_off_rounded,
          title: l10n.receiptSheetVerifyFailed,
          message: _verifyError ?? l10n.receiptSheetTryAgainDot,
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

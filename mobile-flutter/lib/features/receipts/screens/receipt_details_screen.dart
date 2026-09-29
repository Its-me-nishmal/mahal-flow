import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/pdf_generator.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../l10n/l10n.dart';
import '../receipt_view.dart';

/// The proof of a payment. Styled as a ticket — a floating card with a dashed
/// tear line — so it reads as a document, not another app screen.
class ReceiptDetailsScreen extends StatefulWidget {
  final ReceiptView receipt;

  const ReceiptDetailsScreen({super.key, required this.receipt});

  /// Convenience for callers holding the raw API map.
  factory ReceiptDetailsScreen.fromJson(Map<String, dynamic> json,
          {Key? key}) =>
      ReceiptDetailsScreen(key: key, receipt: ReceiptView.fromJson(json));

  @override
  State<ReceiptDetailsScreen> createState() => _ReceiptDetailsScreenState();
}

enum _PdfAction { none, download, share }

class _ReceiptDetailsScreenState extends State<ReceiptDetailsScreen> {
  _PdfAction _busy = _PdfAction.none;

  ReceiptView get _r => widget.receipt;

  String get _fileName {
    final safe = _r.receiptNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
    return 'Receipt_$safe.pdf';
  }

  /// Writes the PDF to the app's documents directory (kept, unlike the temp
  /// dir, which the OS may purge) and returns the file.
  Future<File> _writePdf() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_fileName');
    // The PDF stays English: its built-in Helvetica font has no Malayalam
    // glyphs, and it is the record the office and banks read.
    final bytes = L10n.inEnglish(
      () => SimplePdfGenerator.generateReceiptPdf(
        receiptNumber: _r.receiptNumber,
        memberName: _r.memberName,
        amount: _r.amountLabel,
        paymentType: _r.title,
        subtitle: _r.subtitle,
        date: _r.dateTimeLabel,
        paymentMethod: _r.methodLabel,
        status: _r.statusLabel,
      ),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// [message] is resolved after the mounted check, so callers never touch
  /// the context across an async gap.
  void _snack(String Function(AppLocalizations l10n) message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message(context.l10n))));
  }

  Future<void> _download() async {
    if (_busy != _PdfAction.none) return;
    setState(() => _busy = _PdfAction.download);
    try {
      final file = await _writePdf();
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        // Saved, but no PDF viewer is installed: offer the share sheet so
        // the member can still send it to Files / WhatsApp / Drive.
        _snack((l) => l.receiptPdfSavedNoViewer);
      }
    } catch (e) {
      debugPrint('[RECEIPT_PDF] $e');
      _snack((l) => l.receiptPdfFailed);
    } finally {
      if (mounted) setState(() => _busy = _PdfAction.none);
    }
  }

  String get _shareText {
    final l10n = context.l10n;
    return [
      l10n.receiptShareHeading,
      l10n.receiptShareNumber(_r.receiptNumber),
      l10n.receiptShareMember(_r.memberName),
      l10n.receiptShareAmount(_r.amountLabel),
      l10n.receiptShareFor(_r.title, _r.subtitle),
      l10n.receiptShareDate(_r.dateTimeLabel),
      l10n.receiptSharePaidVia(_r.methodLabel),
      l10n.receiptShareStatus(_r.statusLabel),
      if (_r.note != null) l10n.receiptShareNote(_r.note!),
    ].join('\n');
  }

  Future<void> _share() async {
    if (_busy != _PdfAction.none) return;
    setState(() => _busy = _PdfAction.share);
    try {
      File? pdf;
      try {
        pdf = await _writePdf();
      } catch (e) {
        // The text summary still shares without the attachment.
        debugPrint('[RECEIPT_PDF] $e');
      }
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text: _shareText,
          subject: context.l10n.receiptShareSubject(_r.receiptNumber),
          files: pdf == null
              ? null
              : [XFile(pdf.path, mimeType: 'application/pdf')],
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      debugPrint('[RECEIPT_SHARE] $e');
      _snack((l) => l.receiptShareFailed);
    } finally {
      if (mounted) setState(() => _busy = _PdfAction.none);
    }
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _shareText));
    if (!mounted) return;
    _snack((l) => l.receiptDetailsCopied);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPageScaffold(
      title: l10n.receiptTitle,
      eyebrow: _r.title,
      floatingChild: _receiptCard(context),
      content: [
        const SizedBox(height: AppSpacing.md),
        // Only a committed payment is a verified record worth sharing.
        if (_r.isRefunded)
          AppNoticeCard(
            icon: Icons.undo_rounded,
            title: l10n.receiptRefundedTitle,
            message: _r.refundedAt == null
                ? l10n.receiptRefundedBody
                : l10n.receiptRefundedOnBody(_r.refundedAtLabel),
            color: context.colors.info,
            background: context.colors.infoBg,
          )
        else if (_r.isSuccess)
          AppNoticeCard(
            icon: Icons.verified_user_outlined,
            title: l10n.receiptVerifiedTitle,
            message: l10n.receiptVerifiedBody,
            color: context.colors.success,
            background: context.colors.successBg,
          )
        else
          AppNoticeCard(
            icon: Icons.info_outline_rounded,
            title: l10n.receiptPaymentStatus(_r.statusLabel.toLowerCase()),
            message: l10n.receiptNotConfirmedBody,
            color: context.colors.warning,
            background: context.colors.warningBg,
          ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: AppTextActionButton(
            label: l10n.receiptCopyAsText,
            icon: Icons.copy_rounded,
            onPressed: _copyText,
          ),
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: l10n.receiptDownloadPdf,
            icon: Icons.download_rounded,
            isLoading: _busy == _PdfAction.download,
            onPressed: _busy == _PdfAction.none ? _download : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: _busy == _PdfAction.share
                ? l10n.receiptPreparing
                : l10n.receiptShareReceipt,
            icon: Icons.ios_share_rounded,
            onPressed: _busy == _PdfAction.none ? _share : null,
          ),
        ],
      ),
    );
  }

  Widget _receiptCard(BuildContext context) {
    final l10n = context.l10n;
    final ok = _r.isSuccess;
    final refunded = _r.isRefunded;
    final Color badgeFg = refunded
        ? context.colors.info
        : ok
            ? context.colors.success
            : context.colors.warning;
    final Color badgeBg = refunded
        ? context.colors.infoBg
        : ok
            ? context.colors.successBg
            : context.colors.warningBg;
    return AppCard.floating(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    refunded
                        ? Icons.undo_rounded
                        : ok
                            ? Icons.check_rounded
                            : Icons.schedule_rounded,
                    size: 30,
                    color: badgeFg,
                  ),
                ),
                const SizedBox(height: AppSpacing.ms),
                Text(
                  ok
                      ? l10n.receiptPaymentSuccessful
                      : l10n.receiptPaymentStatus(_r.statusLabel),
                  textAlign: TextAlign.center,
                  style: context.text.body.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(_r.amountLabel, style: context.text.amount),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(_r.dateTimeLabel, style: context.text.small),
              ],
            ),
          ),
          const _DashedLine(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              children: [
                AppDetailRow(
                  label: l10n.receiptNumberLabel,
                  value: _r.receiptNumber,
                  emphasize: true,
                  copyable: _r.receiptNumber != '—',
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: _r.receiptNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.receiptNumberCopied),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                AppDetailRow(
                    label: l10n.receiptMemberLabel, value: _r.memberName),
                AppDetailRow(
                    label: l10n.receiptPaymentTypeLabel, value: _r.title),
                AppDetailRow(
                  label: _r.isDues
                      ? l10n.receiptCoversLabel
                      : l10n.receiptFundLabel,
                  value: _r.subtitle,
                ),
                AppDetailRow(
                    label: l10n.receiptPaidViaLabel, value: _r.methodLabel),
                if (_r.note != null)
                  AppDetailRow(label: l10n.receiptNoteLabel, value: _r.note!),
                if (refunded)
                  AppDetailRow(
                    label: l10n.receiptRefundedOnLabel,
                    value: _r.refundedAtLabel,
                  ),
              ],
            ),
          ),
          const _DashedLine(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                Text(
                  'MahalFlow',
                  style: context.text.cardTitle.copyWith(
                    color: context.colors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.receiptFooter,
                  textAlign: TextAlign.center,
                  style: context.text.small.copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tear line across the receipt card.
class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final count =
            (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
        return ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              count,
              (_) => Container(
                width: dashWidth,
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: dashSpace / 2),
                color: context.colors.border,
              ),
            ),
          ),
        );
      },
    );
  }
}

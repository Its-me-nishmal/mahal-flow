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
    await file.writeAsBytes(
      SimplePdfGenerator.generateReceiptPdf(
        receiptNumber: _r.receiptNumber,
        memberName: _r.memberName,
        amount: _r.amountLabel,
        paymentType: _r.title,
        subtitle: _r.subtitle,
        date: _r.dateTimeLabel,
        paymentMethod: _r.methodLabel,
        status: _r.statusLabel,
      ),
      flush: true,
    );
    return file;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
        _snack('Receipt saved. No PDF viewer found — use Share to send it.');
      }
    } catch (e) {
      debugPrint('[RECEIPT_PDF] $e');
      _snack("Couldn't create the receipt PDF. Try again.");
    } finally {
      if (mounted) setState(() => _busy = _PdfAction.none);
    }
  }

  String get _shareText => [
        'MahalFlow payment receipt',
        'Receipt no: ${_r.receiptNumber}',
        'Member: ${_r.memberName}',
        'Amount: ${_r.amountLabel}',
        'For: ${_r.title} (${_r.subtitle})',
        'Date: ${_r.dateTimeLabel}',
        'Paid via: ${_r.methodLabel}',
        'Status: ${_r.statusLabel}',
      ].join('\n');

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
          subject: 'Receipt ${_r.receiptNumber}',
          files: pdf == null
              ? null
              : [XFile(pdf.path, mimeType: 'application/pdf')],
          sharePositionOrigin:
              box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      debugPrint('[RECEIPT_SHARE] $e');
      _snack("Couldn't open the share sheet. Try again.");
    } finally {
      if (mounted) setState(() => _busy = _PdfAction.none);
    }
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _shareText));
    _snack('Receipt details copied');
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Receipt',
      eyebrow: _r.title,
      floatingChild: _receiptCard(context),
      content: [
        const SizedBox(height: AppSpacing.md),
        // Only a committed payment is a verified record worth sharing.
        if (_r.isSuccess)
          AppNoticeCard(
            icon: Icons.verified_user_outlined,
            title: 'Verified record',
            message: 'Issued by your Mahal through MahalFlow. Safe to share.',
            color: context.colors.success,
            background: context.colors.successBg,
          )
        else
          AppNoticeCard(
            icon: Icons.info_outline_rounded,
            title: 'Payment ${_r.statusLabel.toLowerCase()}',
            message: 'This record is not a confirmed payment receipt.',
            color: context.colors.warning,
            background: context.colors.warningBg,
          ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: AppTextActionButton(
            label: 'Copy details as text',
            icon: Icons.copy_rounded,
            onPressed: _copyText,
          ),
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: 'Download PDF',
            icon: Icons.download_rounded,
            isLoading: _busy == _PdfAction.download,
            onPressed: _busy == _PdfAction.none ? _download : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: _busy == _PdfAction.share ? 'Preparing…' : 'Share Receipt',
            icon: Icons.ios_share_rounded,
            onPressed: _busy == _PdfAction.none ? _share : null,
          ),
        ],
      ),
    );
  }

  Widget _receiptCard(BuildContext context) {
    final ok = _r.isSuccess;
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
                    color: ok ? context.colors.successBg : context.colors.warningBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    ok ? Icons.check_rounded : Icons.schedule_rounded,
                    size: 30,
                    color: ok ? context.colors.success : context.colors.warning,
                  ),
                ),
                const SizedBox(height: AppSpacing.ms),
                Text(
                  ok ? 'Payment successful' : 'Payment ${_r.statusLabel}',
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
                  label: 'Receipt number',
                  value: _r.receiptNumber,
                  emphasize: true,
                  copyable: _r.receiptNumber != '—',
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: _r.receiptNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Receipt number copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                AppDetailRow(label: 'Member', value: _r.memberName),
                AppDetailRow(label: 'Payment type', value: _r.title),
                AppDetailRow(
                  label: _r.isDues ? 'Covers' : 'Fund',
                  value: _r.subtitle,
                ),
                AppDetailRow(label: 'Paid via', value: _r.methodLabel),
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
                  'Computer-generated receipt. No signature required.',
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/pdf_generator.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';

/// The proof of a payment. Styled as a ticket — a floating card with a dashed
/// tear line — so it reads as a document, not another app screen.
class ReceiptDetailsScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final String receiptNumber;
  final String memberName;
  final String date;
  final String paymentMethod;

  const ReceiptDetailsScreen({
    super.key,
    this.title = "Monthly Dues",
    this.subtitle = "Jun-Aug 2026",
    this.amount = "₹1,500",
    this.status = "SUCCESS",
    this.receiptNumber = "GV1MH00120260803R00002",
    this.memberName = "Muhammed Ameen",
    this.date = "15 Aug 2026 • 10:24 AM",
    this.paymentMethod = "UPI",
  });

  bool get _isSuccess => status.toUpperCase() == 'SUCCESS';

  String get _fileSafeNumber => receiptNumber.replaceAll(RegExp(r'[^\w\-]'), '_');

  List<int> _pdfBytes() => SimplePdfGenerator.generateReceiptPdf(
        receiptNumber: receiptNumber,
        memberName: memberName,
        amount: amount,
        paymentType: title,
        subtitle: subtitle,
        date: date,
        paymentMethod: paymentMethod,
        status: status,
      );

  Future<void> _downloadAndOpenReceipt(BuildContext context) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Receipt_$_fileSafeNumber.pdf');
      await file.writeAsBytes(_pdfBytes());
      await OpenFilex.open(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved Receipt_$_fileSafeNumber.pdf'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't generate the PDF: $e")),
        );
      }
    }
  }

  String get _shareText => '''
🕌 *MahalFlow Official Payment Receipt*
━━━━━━━━━━━━━━━━━━━━
🧾 *Receipt No:* `$receiptNumber`
👤 *Member:* $memberName
💰 *Amount:* $amount
📌 *Type:* $title ($subtitle)
📅 *Date:* $date
💳 *Payment Mode:* $paymentMethod
🔒 *Status:* $status (Cryptographically Signed)
━━━━━━━━━━━━━━━━━━━━
*MahalFlow Financial Integrity*
''';

  Future<void> _shareReceipt(BuildContext context) async {
    File? pdfFile;
    try {
      final tempDir = await getTemporaryDirectory();
      pdfFile = File('${tempDir.path}/Receipt_$_fileSafeNumber.pdf');
      await pdfFile.writeAsBytes(_pdfBytes());
    } catch (_) {
      // Sharing the text still works without the attachment.
    }

    await Clipboard.setData(ClipboardData(text: _shareText));
    if (!context.mounted) return;

    AppBottomSheet.show(
      context: context,
      title: 'Share this receipt',
      subtitle: 'The summary is already on your clipboard',
      icon: Icons.ios_share_rounded,
      builder: (ctx, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.ms),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Receipt_$_fileSafeNumber.pdf',
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.small.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _shareText.trim(),
                  style: AppTextStyles.small.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        AppSecondaryButton(
          label: 'Copy text',
          icon: Icons.copy_rounded,
          height: 46,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: _shareText));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Receipt copied to clipboard')),
            );
          },
        ),
        const SizedBox(width: AppSpacing.ms),
        AppPrimaryButton(
          label: 'Open PDF',
          icon: Icons.open_in_new_rounded,
          height: 46,
          onPressed: () {
            if (pdfFile != null) OpenFilex.open(pdfFile.path);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Receipt',
      eyebrow: title,
      floatingChild: _receiptCard(context),
      content: const [
        SizedBox(height: AppSpacing.md),
        AppNoticeCard(
          icon: Icons.verified_user_outlined,
          title: 'Verified record',
          message: 'Signed by MahalFlow Treasury. Safe to share.',
          color: AppColors.success,
          background: AppColors.successBg,
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: 'Download PDF',
            icon: Icons.download_rounded,
            onPressed: () => _downloadAndOpenReceipt(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: 'Share Receipt',
            icon: Icons.ios_share_rounded,
            onPressed: () => _shareReceipt(context),
          ),
        ],
      ),
    );
  }

  Widget _receiptCard(BuildContext context) {
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
                    color: _isSuccess ? AppColors.successBg : AppColors.warningBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isSuccess
                        ? Icons.check_rounded
                        : Icons.schedule_rounded,
                    size: 30,
                    color: _isSuccess ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: AppSpacing.ms),
                Text(
                  _isSuccess ? 'Payment successful' : 'Payment $status',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(amount, style: AppTextStyles.amount),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(date, style: AppTextStyles.small),
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
                  value: receiptNumber,
                  emphasize: true,
                  copyable: true,
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: receiptNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Receipt number copied'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                AppDetailRow(label: 'Member', value: memberName),
                AppDetailRow(label: 'Payment type', value: title),
                AppDetailRow(label: 'Covers', value: subtitle),
                AppDetailRow(label: 'Paid via', value: paymentMethod),
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
                  style: AppTextStyles.cardTitle.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Computer-generated receipt. No signature required.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textMuted,
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
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            count,
            (_) => Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: dashSpace / 2),
              color: AppColors.border,
            ),
          ),
        );
      },
    );
  }
}

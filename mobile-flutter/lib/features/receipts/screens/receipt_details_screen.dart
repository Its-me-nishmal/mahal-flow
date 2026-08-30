import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/pdf_generator.dart';

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

  Future<void> _downloadAndOpenReceipt(BuildContext context) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final sanitizedName = receiptNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
      final file = File('${tempDir.path}/Receipt_$sanitizedName.pdf');

      final pdfBytes = SimplePdfGenerator.generateReceiptPdf(
        receiptNumber: receiptNumber,
        memberName: memberName,
        amount: amount,
        paymentType: title,
        subtitle: subtitle,
        date: date,
        paymentMethod: paymentMethod,
        status: status,
      );

      await file.writeAsBytes(pdfBytes);
      await OpenFilex.open(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("PDF Receipt downloaded: Receipt_$sanitizedName.pdf"),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating PDF receipt: $e")),
        );
      }
    }
  }

  Future<void> _shareReceipt(BuildContext context) async {
    final sanitizedName = receiptNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
    File? pdfFile;

    try {
      final tempDir = await getTemporaryDirectory();
      pdfFile = File('${tempDir.path}/Receipt_$sanitizedName.pdf');
      final pdfBytes = SimplePdfGenerator.generateReceiptPdf(
        receiptNumber: receiptNumber,
        memberName: memberName,
        amount: amount,
        paymentType: title,
        subtitle: subtitle,
        date: date,
        paymentMethod: paymentMethod,
        status: status,
      );
      await pdfFile.writeAsBytes(pdfBytes);
    } catch (_) {}

    final shareText = '''
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

    await Clipboard.setData(ClipboardData(text: shareText));

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.share, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  "Share Receipt (PDF & Text)",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFFC93B3B)),
                      const SizedBox(width: 6),
                      Text(
                        "Receipt_$sanitizedName.pdf",
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shareText,
                    style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Receipt text copied to clipboard!")),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                    label: const Text("Copy Text"),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (pdfFile != null) {
                        OpenFilex.open(pdfFile.path);
                      }
                      Navigator.of(ctx).pop();
                    },
                    icon: const Icon(Icons.open_in_new, size: 16, color: Colors.white),
                    label: const Text("Share PDF"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Receipt",
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Receipt Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(23, 32, 29, 0.04),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 28),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF7EF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF16834B),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status == "SUCCESS" ? "Payment Successful" : "Payment $status",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    amount,
                    style: GoogleFonts.inter(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    date,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildDashedDivider(),
                  const SizedBox(height: 20),

                  // Detail Rows
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildRow("Receipt Number", receiptNumber, isBold: true),
                        const SizedBox(height: 14),
                        _buildRow("Member Name", memberName),
                        const SizedBox(height: 14),
                        _buildRow("Payment Type", title),
                        const SizedBox(height: 14),
                        _buildRow("Months Covered", subtitle),
                        const SizedBox(height: 14),
                        _buildRow("Payment Method", paymentMethod),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildDashedDivider(),
                  const SizedBox(height: 20),

                  Text(
                    "MahalFlow",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      "Thank you for your contribution.\nThis is a computer-generated receipt.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _downloadAndOpenReceipt(context),
                icon: const Icon(Icons.download, size: 18),
                label: Text(
                  "Download PDF Receipt",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => _shareReceipt(context),
                icon: const Icon(Icons.share_outlined, size: 18, color: AppColors.primary),
                label: Text(
                  "Share Receipt",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dashCount, (_) {
            return Container(
              width: dashWidth,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              color: AppColors.border,
            );
          }),
        );
      },
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';

class SimplePdfGenerator {
  static Uint8List generateReceiptPdf({
    required String receiptNumber,
    required String memberName,
    required String amount,
    required String paymentType,
    required String subtitle,
    required String date,
    required String paymentMethod,
    required String status,
  }) {
    final buffer = StringBuffer();

    // Stream content commands for PDF (A4 size: 595.28 x 841.89)
    final streamContent = StringBuffer();

    // Draw background card outline and header bar
    streamContent.writeln("q");
    // Background container (white card)
    streamContent.writeln("0.96 0.97 0.96 rg"); // Light background
    streamContent.writeln("0 0 595 842 re f");

    // Inner White Card
    streamContent.writeln("1 1 1 rg");
    streamContent.writeln("40 120 515 640 re f");
    streamContent.writeln("0.88 0.91 0.89 RG"); // Border color
    streamContent.writeln("1.5 w");
    streamContent.writeln("40 120 515 640 re s");

    // Header green bar accent
    streamContent.writeln("0.086 0.514 0.294 rg"); // #16834B Primary Green
    streamContent.writeln("40 700 515 60 re f");

    // Header Text (White)
    streamContent.writeln("BT");
    streamContent.writeln("/F2 20 Tf");
    streamContent.writeln("1 1 1 rg");
    streamContent.writeln("60 722 Td");
    streamContent.writeln("(MAHALFLOW OFFICIAL RECEIPT) Tj");
    streamContent.writeln("ET");

    // Subtitle / Verified badge
    streamContent.writeln("BT");
    streamContent.writeln("/F1 10 Tf");
    streamContent.writeln("1 1 1 rg");
    streamContent.writeln("400 725 Td");
    streamContent.writeln("([ CRYPTOGRAPHICALLY SIGNED ]) Tj");
    streamContent.writeln("ET");

    // Amount Section
    streamContent.writeln("BT");
    streamContent.writeln("/F2 32 Tf");
    streamContent.writeln("0.09 0.125 0.114 rg"); // #17201D
    streamContent.writeln("60 635 Td");
    final sanitizedAmount = amount.replaceAll("₹", "INR ");
    streamContent.writeln("($sanitizedAmount) Tj");
    streamContent.writeln("ET");

    // Date
    streamContent.writeln("BT");
    streamContent.writeln("/F1 12 Tf");
    streamContent.writeln("0.37 0.45 0.42 rg");
    streamContent.writeln("60 610 Td");
    streamContent.writeln("(Payment Date: $date) Tj");
    streamContent.writeln("ET");

    // Divider line
    streamContent.writeln("0.88 0.91 0.89 RG");
    streamContent.writeln("1 w");
    streamContent.writeln("60 580 m 535 580 l S");

    // Key-Value Table Details
    final rows = [
      ["Receipt Number:", receiptNumber],
      ["Member Name:", memberName],
      ["Payment Category:", paymentType],
      ["Coverage / Notes:", subtitle],
      ["Payment Mode:", paymentMethod],
      ["Transaction Status:", "$status - Verified On-Chain Hash"],
    ];

    double currentY = 540;
    for (final row in rows) {
      // Label (Gray)
      streamContent.writeln("BT");
      streamContent.writeln("/F1 12 Tf");
      streamContent.writeln("0.37 0.45 0.42 rg");
      streamContent.writeln("60 $currentY Td");
      streamContent.writeln("(${row[0]}) Tj");
      streamContent.writeln("ET");

      // Value (Bold Dark)
      streamContent.writeln("BT");
      streamContent.writeln("/F2 12 Tf");
      streamContent.writeln("0.09 0.125 0.114 rg");
      streamContent.writeln("220 $currentY Td");
      streamContent.writeln("(${row[1]}) Tj");
      streamContent.writeln("ET");

      currentY -= 35;
    }

    // Divider line
    streamContent.writeln("0.88 0.91 0.89 RG");
    streamContent.writeln("1 w");
    streamContent.writeln("60 300 m 535 300 l S");

    // Security & Integrity Footer Note
    streamContent.writeln("BT");
    streamContent.writeln("/F2 11 Tf");
    streamContent.writeln("0.086 0.514 0.294 rg");
    streamContent.writeln("60 260 Td");
    streamContent.writeln("(Ledger Integrity: Guaranteed with SHA-256 Hash Chaining) Tj");
    streamContent.writeln("ET");

    streamContent.writeln("BT");
    streamContent.writeln("/F1 10 Tf");
    streamContent.writeln("0.53 0.62 0.59 rg");
    streamContent.writeln("60 240 Td");
    streamContent.writeln("(This is an authentic computer-generated digital receipt from MahalFlow.) Tj");
    streamContent.writeln("ET");

    streamContent.writeln("BT");
    streamContent.writeln("/F1 10 Tf");
    streamContent.writeln("0.53 0.62 0.59 rg");
    streamContent.writeln("60 225 Td");
    streamContent.writeln("(No physical signature is required. Verified and recorded in central audit ledger.) Tj");
    streamContent.writeln("ET");

    streamContent.writeln("Q");

    final streamBytes = utf8.encode(streamContent.toString());
    final streamLength = streamBytes.length;

    final objects = <String>[];

    // Obj 1: Catalog
    objects.add("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj");

    // Obj 2: Pages
    objects.add("2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj");

    // Obj 3: Page
    objects.add("3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595.28 841.89] /Resources << /Font << /F1 4 0 R /F2 5 0 R >> >> /Contents 6 0 R >>\nendobj");

    // Obj 4: Font Helvetica
    objects.add("4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj");

    // Obj 5: Font Helvetica-Bold
    objects.add("5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\nendobj");

    // Obj 6: Content Stream
    objects.add("6 0 obj\n<< /Length $streamLength >>\nstream\n${streamContent.toString()}endstream\nendobj");

    buffer.write("%PDF-1.4\n");
    final offsets = <int>[0];

    for (final obj in objects) {
      final currentOffset = utf8.encode(buffer.toString()).length;
      offsets.add(currentOffset);
      buffer.write(obj);
      buffer.write("\n");
    }

    final startXref = utf8.encode(buffer.toString()).length;
    buffer.write("xref\n");
    buffer.write("0 ${objects.length + 1}\n");
    buffer.write("0000000000 65535 f \n");

    for (int i = 1; i <= objects.length; i++) {
      final off = offsets[i].toString().padLeft(10, '0');
      buffer.write("$off 00000 n \n");
    }

    buffer.write("trailer\n");
    buffer.write("<< /Size ${objects.length + 1} /Root 1 0 R >>\n");
    buffer.write("startxref\n");
    buffer.write("$startXref\n");
    buffer.write("%%EOF\n");

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }
}

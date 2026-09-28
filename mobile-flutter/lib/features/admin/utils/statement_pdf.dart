import 'dart:convert';
import 'dart:typed_data';

/// One line of a financial statement.
class StatementLine {
  final String date;
  final String member;
  final String type;
  final String reference;
  final String amount;

  const StatementLine({
    required this.date,
    required this.member,
    required this.type,
    required this.reference,
    required this.amount,
  });
}

/// Minimal multi-page A4 PDF for the committee's financial statement, built
/// on-device (no server endpoint exists). Uses the standard Helvetica fonts,
/// so text is reduced to printable ASCII ("₹" → "Rs.").
class StatementPdf {
  StatementPdf._();

  static const double _pageW = 595.28;
  static const double _pageH = 841.89;
  static const double _margin = 40;
  static const double _rowH = 16;

  /// Columns: x offset and max characters.
  static const List<(double, int)> _cols = [
    (40, 12), // date
    (112, 26), // member
    (262, 14), // type
    (344, 26), // reference
    (500, 14), // amount (right-aligned-ish)
  ];

  static String ascii(String s) {
    final replaced = s
        .replaceAll('₹', 'Rs. ')
        .replaceAll(RegExp('[–—]'), '-')
        .replaceAll('·', '-')
        .replaceAll('…', '...')
        .replaceAll(RegExp('[‘’]'), "'")
        .replaceAll(RegExp('[“”]'), '"');
    final buf = StringBuffer();
    for (final c in replaced.runes) {
      buf.writeCharCode(c >= 32 && c < 127 ? c : 0x3F /* ? */);
    }
    return buf.toString();
  }

  static String _esc(String s) => ascii(s)
      .replaceAll(r'\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');

  static String _fit(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max - 1)}.';

  static void _text(StringBuffer out, String font, double size, double x,
      double y, String text,
      {String color = '0.09 0.125 0.114'}) {
    out
      ..writeln('BT')
      ..writeln('/$font ${size.toStringAsFixed(1)} Tf')
      ..writeln('$color rg')
      ..writeln('${x.toStringAsFixed(2)} ${y.toStringAsFixed(2)} Td')
      ..writeln('(${_esc(text)}) Tj')
      ..writeln('ET');
  }

  static void _rule(StringBuffer out, double y) {
    out
      ..writeln('0.88 0.91 0.89 RG')
      ..writeln('0.8 w')
      ..writeln('$_margin ${y.toStringAsFixed(2)} m '
          '${(_pageW - _margin).toStringAsFixed(2)} ${y.toStringAsFixed(2)} l S');
  }

  static Uint8List build({
    required String mahalName,
    String? registrationNumber,
    required String periodLabel,
    required String typeLabel,
    required String generatedAt,
    required List<(String, String)> summary,
    required List<StatementLine> lines,
    String? footnote,
  }) {
    final pages = <String>[];
    var out = StringBuffer();
    var y = _pageH - _margin;
    var pageNo = 1;

    void header({required bool first}) {
      if (first) {
        out.writeln('0.078 0.424 0.357 rg'); // #146C5B
        out.writeln('0 ${(_pageH - 96).toStringAsFixed(2)} '
            '${_pageW.toStringAsFixed(2)} 96 re f');
        _text(out, 'F2', 18, _margin, _pageH - 44, 'Financial statement',
            color: '1 1 1');
        _text(
            out,
            'F1',
            10,
            _margin,
            _pageH - 62,
            registrationNumber == null || registrationNumber.isEmpty
                ? mahalName
                : '$mahalName - Reg. $registrationNumber',
            color: '1 1 1');
        _text(out, 'F1', 10, _margin, _pageH - 78,
            'Period: $periodLabel   Type: $typeLabel',
            color: '1 1 1');
        y = _pageH - 120;
        _text(out, 'F1', 9, _margin, y, 'Generated $generatedAt',
            color: '0.37 0.41 0.39');
        y -= 22;
        for (final (label, value) in summary) {
          _text(out, 'F1', 10, _margin, y, label, color: '0.37 0.41 0.39');
          _text(out, 'F2', 10, 220, y, value);
          y -= 15;
        }
        y -= 12;
      } else {
        y = _pageH - _margin;
        _text(out, 'F1', 9, _margin, y,
            '$mahalName - statement $periodLabel (continued)',
            color: '0.37 0.41 0.39');
        y -= 22;
      }
      const heads = ['Date', 'Member', 'Type', 'Reference', 'Amount'];
      for (var i = 0; i < heads.length; i++) {
        _text(out, 'F2', 9, _cols[i].$1, y, heads[i], color: '0.37 0.41 0.39');
      }
      y -= 6;
      _rule(out, y);
      y -= _rowH - 4;
    }

    void finishPage() {
      _text(out, 'F1', 8, _margin, 24, 'MahalFlow - page $pageNo',
          color: '0.54 0.58 0.56');
      pages.add(out.toString());
      out = StringBuffer();
      pageNo++;
    }

    header(first: true);
    if (lines.isEmpty) {
      _text(out, 'F1', 10, _margin, y, 'No transactions in this period.',
          color: '0.37 0.41 0.39');
      y -= _rowH;
    }
    for (final l in lines) {
      if (y < _margin + 40) {
        finishPage();
        header(first: false);
      }
      final cells = [l.date, l.member, l.type, l.reference, l.amount];
      for (var i = 0; i < cells.length; i++) {
        _text(out, i == 4 ? 'F2' : 'F1', 9, _cols[i].$1, y,
            _fit(ascii(cells[i]), _cols[i].$2));
      }
      y -= _rowH;
    }
    if (footnote != null && footnote.isNotEmpty) {
      if (y < _margin + 40) {
        finishPage();
        y = _pageH - _margin;
      }
      y -= 8;
      _text(out, 'F1', 8, _margin, y, footnote, color: '0.54 0.58 0.56');
    }
    finishPage();

    // --- Assemble the file -------------------------------------------------
    // 1 catalog, 2 pages, 3 F1, 4 F2, then (page, content) pairs.
    final objects = <String>[];
    final kids = <String>[];
    for (var i = 0; i < pages.length; i++) {
      kids.add('${5 + i * 2} 0 R');
    }
    objects.add('<< /Type /Catalog /Pages 2 0 R >>');
    objects.add(
        '<< /Type /Pages /Kids [${kids.join(' ')}] /Count ${pages.length} >>');
    objects.add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica '
        '/Encoding /WinAnsiEncoding >>');
    objects.add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold '
        '/Encoding /WinAnsiEncoding >>');
    for (var i = 0; i < pages.length; i++) {
      final contentId = 6 + i * 2;
      objects
          .add('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $_pageW $_pageH] '
              '/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> '
              '/Contents $contentId 0 R >>');
      final stream = pages[i];
      objects.add('<< /Length ${stream.length} >>\n'
          'stream\n${stream}endstream');
    }

    // Every byte is ASCII (see [ascii]), so string length == byte offset.
    final buf = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[];
    for (var i = 0; i < objects.length; i++) {
      offsets.add(buf.length);
      buf.write('${i + 1} 0 obj\n${objects[i]}\nendobj\n');
    }
    final xref = buf.length;
    buf.write('xref\n0 ${objects.length + 1}\n0000000000 65535 f \n');
    for (final o in offsets) {
      buf.write('${o.toString().padLeft(10, '0')} 00000 n \n');
    }
    buf.write('trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
        'startxref\n$xref\n%%EOF\n');
    return Uint8List.fromList(latin1.encode(buf.toString()));
  }
}

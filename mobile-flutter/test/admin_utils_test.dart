import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahalflow_mobile/features/admin/screens/bulk_excel_import_preview_screen.dart';
import 'package:mahalflow_mobile/features/admin/screens/bulk_excel_import_step1_screen.dart';
import 'package:mahalflow_mobile/features/admin/utils/admin_format.dart';
import 'package:mahalflow_mobile/features/admin/utils/statement_pdf.dart';

void main() {
  group('AdminFormat', () {
    test('next due months start right after last_paid_month', () {
      expect(
        AdminFormat.nextDueMonths({'last_paid_month': '2026-11'}, 3),
        ['2026-12', '2027-01', '2027-02'],
      );
      expect(AdminFormat.nextDueMonths({}, 2), isEmpty);
    });

    test('dues come from the record, never a default', () {
      expect(AdminFormat.monthlyDues({'monthly_dues_custom_amount': 750}), 750);
      expect(AdminFormat.monthlyDues({}), isNull);
      expect(
          AdminFormat.monthlyDues({'monthly_dues_custom_amount': 0}), isNull);
    });

    test('status buckets and humanize', () {
      expect(AdminFormat.memberStatus('GRACE_PERIOD').bucket, 'Grace Period');
      expect(AdminFormat.memberStatus('SUSPENDED').bucket, 'Suspended');
      expect(AdminFormat.memberStatus('PENDING').bucket, 'Pending');
      expect(AdminFormat.humanize('PAST_DUE'), 'Past due');
      expect(AdminFormat.months(1), '1 month');
      expect(AdminFormat.months(3), '3 months');
      expect(AdminFormat.shortHash(''), 'Unavailable');
    });
  });

  group('StatementPdf', () {
    test('builds a well-formed multi-page PDF', () {
      final bytes = StatementPdf.build(
        mahalName: 'Test (Mahal)',
        periodLabel: 'Sep 2026',
        typeLabel: 'All types',
        generatedAt: 'now',
        summary: const [('Collected', '₹1,000')],
        lines: [
          for (var i = 0; i < 120; i++)
            StatementLine(
              date: '1 Sep 2026',
              member: 'Member $i',
              type: 'Monthly dues',
              reference: 'R$i',
              amount: '₹500',
            ),
        ],
      );
      final text = latin1.decode(bytes);
      expect(text.startsWith('%PDF-1.4'), isTrue);
      expect(text.trimRight().endsWith('%%EOF'), isTrue);
      expect(RegExp(r'/Count (\d+)').firstMatch(text)!.group(1), isNot('1'));
      expect(text.contains(r'Test \(Mahal\)'), isTrue);
      expect(text.contains('₹'), isFalse);

      // xref offset points at the xref table.
      final start =
          int.parse(RegExp(r'startxref\n(\d+)').firstMatch(text)!.group(1)!);
      expect(text.substring(start, start + 4), 'xref');
    });
  });

  testWidgets('import preview renders only server rows and blocks 0 valid',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: BulkExcelImportPreviewScreen(
        args: ImportPreviewArgs(
          fileName: 'members.csv',
          preview: {
            'filename': 'members.csv',
            'total_rows': 1,
            'valid_rows': 0,
            'duplicate_rows': 0,
            'preview_rows': [
              {'name': 'Row One', 'phone': '', 'status': 'INVALID'},
            ],
          },
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('Row One'), findsOneWidget);
    expect(find.text('No valid rows to import'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.ancestor(
      of: find.text('No valid rows to import'),
      matching: find.byType(ElevatedButton),
    ));
    expect(button.onPressed, isNull);
  });
}

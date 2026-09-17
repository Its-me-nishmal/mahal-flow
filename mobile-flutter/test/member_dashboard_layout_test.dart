import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahalflow_mobile/core/theme/app_tokens.dart';
import 'package:mahalflow_mobile/core/utils/currency_format.dart';
import 'package:mahalflow_mobile/core/utils/dues_period.dart';
import 'package:mahalflow_mobile/features/dashboard/widgets/member_dashboard_widgets.dart';

/// Renders [child] at a fixed logical size. A RenderFlex overflow inside makes
/// the test fail, which is what these cases are guarding against.
Future<void> pumpAt(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(360, 800),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenH,
              ),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget quickActionsRow() {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: QuickActionTile(
            icon: Icons.volunteer_activism_outlined,
            iconColor: Colors.orange,
            iconBackground: Colors.orange.shade50,
            label: 'Contribute',
            caption: 'Zakat and general fund',
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppSpacing.ms),
        Expanded(
          child: QuickActionTile(
            icon: Icons.receipt_long_outlined,
            iconColor: Colors.blue,
            iconBackground: Colors.blue.shade50,
            label: 'Receipts',
            caption: 'All past payments',
            onTap: () {},
          ),
        ),
      ],
    ),
  );
}

void main() {
  group('quick action tiles', () {
    testWidgets('do not overflow at 360dp', (tester) async {
      await pumpAt(tester, quickActionsRow());
      expect(tester.takeException(), isNull);
    });

    testWidgets('do not overflow at 360dp with 1.3x text', (tester) async {
      await pumpAt(tester, quickActionsRow(), textScale: 1.3);
      expect(tester.takeException(), isNull);
    });

    testWidgets('both tiles in a row share one height', (tester) async {
      await pumpAt(tester, quickActionsRow());
      final heights = tester
          .widgetList<QuickActionTile>(find.byType(QuickActionTile))
          .map((tile) => tester.getSize(find.byWidget(tile)).height)
          .toList();
      expect(heights, hasLength(2));
      expect(heights.first, heights.last);
    });
  });

  group('balance card', () {
    Widget card({required double outstanding, List<DueMonth> months = const []}) {
      return BalanceCard(
        outstanding: outstanding,
        advanceCredit: 0,
        pendingSummary: months.isEmpty ? null : '${months.length} pending months',
        months: months,
        paidUpToLabel: 'August 2026',
        onPayDues: () {},
        onContribute: () {},
      );
    }

    testWidgets('owing state shows the grouped amount in the CTA',
        (tester) async {
      await pumpAt(
        tester,
        card(
          outstanding: 1500,
          months: [
            DueMonth(DateTime(2026, 6), DueMonthStatus.overdue),
            DueMonth(DateTime(2026, 7), DueMonthStatus.overdue),
            DueMonth(DateTime(2026, 8), DueMonthStatus.dueNow),
          ],
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('₹1,500'), findsOneWidget);
      expect(find.text('Pay ₹1,500'), findsOneWidget);
      expect(find.text('Action Required'), findsOneWidget);
      expect(find.text('Jun'), findsOneWidget);
      expect(find.text('Aug'), findsOneWidget);
    });

    testWidgets('up to date state swaps the CTA and drops month chips',
        (tester) async {
      await pumpAt(tester, card(outstanding: 0));
      expect(tester.takeException(), isNull);
      expect(find.text('Up to Date'), findsOneWidget);
      expect(find.text('Make a Contribution'), findsOneWidget);
      expect(find.textContaining('Pay '), findsNothing);
      expect(find.textContaining('All dues paid up to'), findsOneWidget);
    });

    testWidgets('a large amount does not overflow at 360dp', (tester) async {
      await pumpAt(tester, card(outstanding: 1250000));
      expect(tester.takeException(), isNull);
      expect(find.text('₹12,50,000'), findsOneWidget);
    });
  });

  group('latest payment card', () {
    testWidgets('empty state replaces a blank card', (tester) async {
      await pumpAt(
        tester,
        LatestPaymentCard(
          receipt: null,
          isUpToDate: false,
          onViewReceipt: () {},
          onPrimaryAction: () {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('No payments yet'), findsOneWidget);
      expect(find.text('Pay Dues Now'), findsOneWidget);
    });

    testWidgets('a dues receipt is never labelled a contribution',
        (tester) async {
      await pumpAt(
        tester,
        LatestPaymentCard(
          receipt: const {
            'amount': 1500,
            'payment_type': 'MONTHLY_DUES',
            'paid_months': ['2026-06', '2026-07', '2026-08'],
            'receipt_number': 'GV1MH00120260803R00002',
            'created_at': '2026-08-15T10:24:00Z',
          },
          isUpToDate: false,
          onViewReceipt: () {},
          onPrimaryAction: () {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Jun–Aug 2026 Dues'), findsOneWidget);
      expect(find.textContaining('Contribution'), findsNothing);
      expect(find.text('Paid on Aug 15, 2026'), findsOneWidget);
    });
  });

  group('DuesPeriod', () {
    test('derives unpaid months after the last paid month', () {
      final months = DuesPeriod.unpaidMonths(
        '2026-05',
        now: DateTime(2026, 8, 20),
      );
      expect(months.map((m) => m.key), ['2026-06', '2026-07', '2026-08']);
      expect(months.last.status, DueMonthStatus.dueNow);
      expect(months.first.status, DueMonthStatus.overdue);
    });

    test('is empty when the member is up to date or paid in advance', () {
      expect(DuesPeriod.unpaidMonths('2026-08', now: DateTime(2026, 8, 20)),
          isEmpty);
      expect(DuesPeriod.unpaidMonths('2026-12', now: DateTime(2026, 8, 20)),
          isEmpty);
    });

    test('returns no period for malformed input rather than inventing one', () {
      expect(DuesPeriod.parseMonthKey(null), isNull);
      expect(DuesPeriod.parseMonthKey('not-a-month'), isNull);
      expect(DuesPeriod.parseMonthKey('2026-13'), isNull);
      expect(DuesPeriod.pendingSummary(null), isNull);
    });

    test('caps a years-stale last_paid_month at 24 months', () {
      final months = DuesPeriod.unpaidMonths(
        '2015-01',
        now: DateTime(2026, 8, 20),
      );
      expect(months, hasLength(24));
    });

    test('pluralises the pending summary', () {
      expect(DuesPeriod.pendingSummary('2026-07', now: DateTime(2026, 8, 20)),
          '1 pending month');
      expect(DuesPeriod.pendingSummary('2026-05', now: DateTime(2026, 8, 20)),
          '3 pending months');
    });
  });

  group('Inr', () {
    test('groups rupees the Indian way', () {
      expect(Inr.format(1500), '₹1,500');
      expect(Inr.format(1250000), '₹12,50,000');
      expect(Inr.format(0), '₹0');
    });

    test('spoken form omits the glyph', () {
      expect(Inr.spoken(1500), '1,500 rupees');
    });
  });
}

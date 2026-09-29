import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahalflow_mobile/features/alerts/screens/alert_details_screen.dart';
import 'package:mahalflow_mobile/features/payment_result/payment_result_args.dart';
import 'package:mahalflow_mobile/features/payment_result/payu_checkout.dart';
import 'package:mahalflow_mobile/features/payment_result/screens/payment_failed_screen.dart';
import 'package:mahalflow_mobile/features/payment_result/screens/payment_pending_screen.dart';
import 'package:mahalflow_mobile/features/payment_result/screens/payment_success_screen.dart';
import 'package:mahalflow_mobile/features/receipts/receipt_view.dart';
import 'package:mahalflow_mobile/features/receipts/screens/receipt_details_screen.dart';

Future<void> pumpScreen(WidgetTester tester, Widget screen,
    {double textScale = 1.0}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: const Size(360, 800),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
}

const _receipt = {
  'receipt_number': 'GV1MHTEST20260915R00007',
  'member_id': 'M1',
  'member_name': 'Test Member',
  'payment_type': 'MONTHLY_DUES',
  'paid_months': ['2026-07', '2026-08', '2026-09'],
  'amount': 1250000,
  'created_at': '2026-09-15T10:24:00Z',
};

void main() {
  group('ReceiptView', () {
    test('maps API fields and never invents values', () {
      final r = ReceiptView.fromJson(const {'payment_type': 'CONTRIBUTION'});
      expect(r.receiptNumber, '—');
      expect(r.amountLabel, '—');
      expect(r.dateLabel, '—');
      expect(r.methodLabel, '—');
      expect(r.subtitle, 'Contribution');
      expect(r.isSuccess, isTrue); // receipts exist only for committed payments
    });

    test('dues receipt labels months and lakh amount', () {
      final r = ReceiptView.fromJson(_receipt);
      expect(r.subtitle, 'Jul–Sep 2026');
      expect(r.amountLabel, '₹12,50,000');
      expect(r.title, 'Monthly Dues');
    });

    test('server status wins', () {
      final r = ReceiptView.fromJson({..._receipt, 'status': 'REFUNDED'});
      expect(r.isSuccess, isFalse);
      expect(r.statusLabel, 'Refunded');
    });

    test('reads gateway, method, note and refund date', () {
      final r = ReceiptView.fromJson({
        ..._receipt,
        'status': 'REFUNDED',
        'gateway': 'PAYU',
        'payment_method': 'UPI',
        'note': 'In memory of family',
        'refunded_at': '2026-09-20T10:00:00Z',
      });
      expect(r.isRefunded, isTrue);
      expect(r.methodLabel, 'Online (UPI)');
      expect(r.note, 'In memory of family');
      expect(r.refundedAt, isNotNull);
      expect(ReceiptView.fromJson({..._receipt, 'gateway': 'CASH'}).methodLabel,
          'Cash');
      expect(
          ReceiptView.fromJson({..._receipt, 'gateway': 'PAYU'}).methodLabel,
          'Online (PayU)');
    });
  });

  group('alertTypeFromApi', () {
    test('title words never create a pay prompt', () {
      expect(
        alertTypeFromApi(const {'title': 'Payment received', 'severity': 'INFO'}),
        AlertType.system,
      );
    });
    test('overdue audience and dues type are dues reminders', () {
      expect(alertTypeFromApi(const {'audience': 'OVERDUE_ONLY'}),
          AlertType.overdue);
      expect(alertTypeFromApi(const {'type': 'DUES_REMINDER'}),
          AlertType.overdue);
    });
    test('warnings are important, not overdue', () {
      expect(alertTypeFromApi(const {'severity': 'WARNING'}),
          AlertType.important);
    });
    test('server alert types', () {
      expect(alertTypeFromApi(const {'type': 'PAYMENT_RECEIVED'}),
          AlertType.success);
      expect(alertTypeFromApi(const {'type': 'EVENT'}), AlertType.event);
      expect(alertTypeFromApi(const {'type': 'GENERAL'}), AlertType.default_);
      // An explicit announcement to overdue members is not a pay prompt.
      expect(
          alertTypeFromApi(
              const {'type': 'ANNOUNCEMENT', 'audience': 'OVERDUE_ONLY'}),
          AlertType.system);
      // Push payloads carry the alert type as alert_type.
      expect(
          alertTypeFromApi(
              const {'type': 'ALERT', 'alert_type': 'DUES_REMINDER'}),
          AlertType.overdue);
    });
  });

  group('PayUCheckout.paymentParams', () {
    const checkout = {
      'key': 'KEY',
      'txnid': 'ORDTXN1',
      'amount': '1500.00',
      'productinfo': 'Dues',
      'firstname': 'A',
      'email': 'a@b.c',
      'phone': '9847000000',
      'surl': 'https://s',
      'furl': 'https://f',
      'params': {'udf1': 'TXN1', 'udf2': 'MAHAL_X', 'udf3': 'MEM_X'},
    };

    test('uses the udf values the server signed', () {
      final p = PayUCheckout.paymentParams(
        checkout: Map<String, dynamic>.from(checkout),
        transactionId: 'ORDTXN1',
        referenceId: 'TXN1',
        memberId: 'MEM_X',
      )!;
      final extra = p.values.whereType<Map>().first;
      expect(extra.values, containsAll(['TXN1', 'MAHAL_X', 'MEM_X']));
    });

    test('refuses an incomplete payload instead of filling demo values', () {
      expect(
        PayUCheckout.paymentParams(
          checkout: const {'key': 'KEY'},
          transactionId: 'T',
          referenceId: 'T',
          memberId: 'M',
        ),
        isNull,
      );
    });
  });

  group('payment result screens at 360dp', () {
    testWidgets('success shows the receipt amount and months', (tester) async {
      await pumpScreen(
        tester,
        PaymentSuccessScreen(
          args: PaymentResultArgs.fromReceipt(
            kind: PaymentKind.dues,
            receipt: Map<String, dynamic>.from(_receipt),
          ),
        ),
        textScale: 1.3,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('₹12,50,000'), findsOneWidget);
      expect(find.text('Jul–Sep 2026'), findsOneWidget);
      expect(find.text('GV1MHTEST20260915R00007'), findsOneWidget);
    });

    testWidgets('cancel says no money was taken', (tester) async {
      await pumpScreen(
        tester,
        PaymentFailedScreen(
          args: PaymentResultArgs(
            kind: PaymentKind.contribution,
            at: DateTime(2026, 9, 15),
            amount: 500,
            coverage: 'Zakat Fund',
            cancelled: true,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Payment cancelled'), findsOneWidget);
      expect(find.textContaining('No money was taken'), findsOneWidget);
    });

    testWidgets('pending without a transaction does not poll', (tester) async {
      await pumpScreen(
        tester,
        PaymentPendingScreen(
          args: PaymentResultArgs(
            kind: PaymentKind.dues,
            at: DateTime(2026, 9, 15),
            amount: 1500,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Payment pending'), findsOneWidget);
    });

    testWidgets('receipt details renders a lakh amount', (tester) async {
      await pumpScreen(
        tester,
        ReceiptDetailsScreen.fromJson(Map<String, dynamic>.from(_receipt)),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Verified record'), findsOneWidget);
    });
  });
}

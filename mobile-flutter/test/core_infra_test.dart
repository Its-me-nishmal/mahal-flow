import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahalflow_mobile/core/navigation/app_routes.dart';
import 'package:mahalflow_mobile/core/network/api_service.dart';
import 'package:mahalflow_mobile/core/utils/app_date.dart';
import 'package:mahalflow_mobile/core/utils/currency_format.dart';
import 'package:mahalflow_mobile/core/utils/phone_format.dart';
import 'package:mahalflow_mobile/core/widgets/app_bottom_nav_bar.dart';
import 'package:mahalflow_mobile/core/widgets/app_page_scaffold.dart';
import 'package:mahalflow_mobile/core/widgets/app_text_field.dart';
import 'package:mahalflow_mobile/core/widgets/empty_state_view.dart';

void main() {
  group('AppDate', () {
    final now = DateTime(2026, 9, 28, 12, 0);

    test('formats date and date-time', () {
      final d = DateTime(2026, 8, 5, 10, 24);
      expect(AppDate.formatDate(d), '5 Aug 2026');
      expect(AppDate.formatDateTime(d), '5 Aug 2026 · 10:24 AM');
    });

    test('parses Go timestamps and rejects junk / zero time', () {
      expect(AppDate.tryParse('2026-08-05T10:24:00.123456789Z'), isNotNull);
      expect(AppDate.tryParse('0001-01-01T00:00:00Z'), isNull);
      expect(AppDate.tryParse('not a date'), isNull);
      expect(AppDate.tryParse(null), isNull);
      expect(AppDate.formatDate('garbage'), '—');
      expect(AppDate.tryParse(1785925440)?.year, 2026); // epoch seconds
    });

    test('relative buckets', () {
      String rel(Duration ago) => AppDate.relative(now.subtract(ago), now: now);
      expect(rel(const Duration(seconds: 20)), 'Just now');
      expect(rel(const Duration(minutes: 5)), '5 min ago');
      expect(rel(const Duration(hours: 3)), '3 h ago');
      expect(
        AppDate.relative(DateTime(2026, 9, 27, 18), now: now),
        'Yesterday',
      );
      expect(rel(const Duration(days: 3)), '3 days ago');
      expect(rel(const Duration(days: 9)),
          AppDate.formatDate(now.subtract(const Duration(days: 9))));
    });
  });

  group('Inr', () {
    test('keeps paise instead of rounding them away', () {
      expect(Inr.format(1500), '₹1,500');
      expect(Inr.format(1500.5), '₹1,500.50');
      expect(Inr.format(1500, alwaysShowPaise: true), '₹1,500.00');
      expect(Inr.fromPaise(150050), '₹1,500.50');
      expect(Inr.spoken(1500.5), '1,500 rupees 50 paise');
    });
  });

  group('PhoneFormat', () {
    test('display and validation', () {
      expect(PhoneFormat.display('+919847123456'), '+91 98471 23456');
      expect(PhoneFormat.isValidIndianMobile('9847123456'), isTrue);
      expect(PhoneFormat.isValidIndianMobile('1234567890'), isFalse);
    });
  });

  group('ApiService session', () {
    tearDown(() => ApiService.sessionMemberId = null);

    test('no seed fallback for the member id', () {
      ApiService.sessionMemberId = null;
      expect(ApiService.currentMemberId, isNull);
      expect(
        ApiService.requireMemberId,
        throwsA(isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.noSession)),
      );
    });

    test('PayU user credential', () {
      ApiService.sessionMemberId = 'MEM_7';
      expect(ApiService.payuUserCredential('KEY'), 'KEY:MEM_7');
      expect(ApiService.payuUserCredential(''), isNull);
      ApiService.sessionMemberId = null;
      expect(ApiService.payuUserCredential('KEY'), isNull);
    });

    test('ack only decrements the badge for unread alerts', () async {
      ApiService.unreadAlertsCount.value = 2;
      // No server in tests: the request fails, the local count still moves.
      await ApiService().acknowledgeAlert('A1');
      expect(ApiService.unreadAlertsCount.value, 2);
      await ApiService().acknowledgeAlert('A1', wasUnread: true);
      expect(ApiService.unreadAlertsCount.value, 1);
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  testWidgets('member tabs keep the dashboard as the stack root',
      (tester) async {
    Widget tab(String name, int index) => Scaffold(
          body: Text(name),
          bottomNavigationBar: Builder(
            builder: (context) => AppBottomNavBar(
              currentIndex: index,
              onTap: (i) =>
                  AppNav.switchMemberTab(context, AppRoutes.memberTabs[i]),
              items: const [
                AppNavItem(
                    icon: Icons.home, activeIcon: Icons.home, label: 'Home'),
                AppNavItem(
                    icon: Icons.payments,
                    activeIcon: Icons.payments,
                    label: 'Pay'),
                AppNavItem(
                    icon: Icons.receipt,
                    activeIcon: Icons.receipt,
                    label: 'Receipts'),
                AppNavItem(
                    icon: Icons.campaign,
                    activeIcon: Icons.campaign,
                    label: 'Notices'),
                AppNavItem(
                    icon: Icons.person,
                    activeIcon: Icons.person,
                    label: 'Profile'),
              ],
            ),
          ),
        );

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [AppRouteTracker.instance],
      initialRoute: AppRoutes.memberDashboard,
      routes: {
        for (var i = 0; i < AppRoutes.memberTabs.length; i++)
          AppRoutes.memberTabs[i]: (_) => tab('tab$i', i),
      },
    ));

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Receipts'));
    await tester.pumpAndSettle();
    expect(find.text('tab2'), findsOneWidget);

    // Back from any tab lands on Home, not on the previous tab.
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.text('tab0'), findsOneWidget);
    expect(nav.canPop(), isFalse);
  });

  testWidgets('bottom action bar rides above the keyboard', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: AppPageScaffold(
        title: 'Form',
        content: const [SizedBox(height: 40)],
        bottomBar: AppBottomActionBar(
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('Save')),
          ],
        ),
      ),
    ));
    await tester.pump();

    final bottom = tester.getBottomLeft(find.text('Save')).dy;
    expect(bottom, lessThanOrEqualTo(800 - 300));
  });

  testWidgets('AppTextField obscure toggle and label semantics',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: AppTextField(label: 'PIN', obscureText: true),
      ),
    ));
    expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    await tester.tap(find.byTooltip('Show PIN'));
    await tester.pump();
    expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
    expect(find.bySemanticsLabel(RegExp('PIN')), findsWidgets);
    handle.dispose();
  });

  testWidgets('state views scroll inside bounded and unbounded parents',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: EmptyStateView(
          icon: Icons.inbox,
          title: 'Nothing',
          description: 'Empty',
        ),
      ),
    ));
    expect(find.byType(SingleChildScrollView), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(children: [
          AppErrorStateView(description: 'Failed', onRetry: () {}),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}

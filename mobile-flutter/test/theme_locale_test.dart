import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahalflow_mobile/core/network/api_exception.dart';
import 'package:mahalflow_mobile/core/settings/app_settings.dart';
import 'package:mahalflow_mobile/core/theme/app_theme.dart';
import 'package:mahalflow_mobile/core/utils/app_date.dart';
import 'package:mahalflow_mobile/core/utils/dues_period.dart';
import 'package:mahalflow_mobile/core/widgets/app_settings_sheet.dart';
import 'package:mahalflow_mobile/features/alerts/screens/alert_details_screen.dart';
import 'package:mahalflow_mobile/features/auth/screens/login_screen.dart';
import 'package:mahalflow_mobile/features/auth/screens/onboarding_screen.dart';
import 'package:mahalflow_mobile/features/dashboard/widgets/member_dashboard_widgets.dart';
import 'package:mahalflow_mobile/features/payment_result/payment_result_args.dart';
import 'package:mahalflow_mobile/features/payment_result/screens/payment_failed_screen.dart';
import 'package:mahalflow_mobile/features/payment_result/screens/payment_success_screen.dart';
import 'package:mahalflow_mobile/features/receipts/screens/receipt_details_screen.dart';
import 'package:mahalflow_mobile/l10n/l10n.dart';

const _ml = Locale('ml');
const _en = Locale('en');

/// Pumps [home] inside the real theme + localization setup at 360dp.
/// Any RenderFlex overflow makes `takeException()` non-null.
Future<void> pumpApp(
  WidgetTester tester,
  Widget home, {
  Locale locale = _ml,
  ThemeMode themeMode = ThemeMode.dark,
  double textScale = 1.3,
  Size size = const Size(360, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        L10n.setLocale(Localizations.localeOf(context));
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
      },
      home: home,
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
  // Every test leaves the context-free strings in English for the other
  // test files.
  tearDown(() => L10n.setLocale(_en));

  group('ARB catalogues', () {
    Map<String, dynamic> load(String loc) =>
        jsonDecode(File('lib/l10n/app_$loc.arb').readAsStringSync())
            as Map<String, dynamic>;

    test('every English message has a Malayalam translation', () {
      Set<String> keys(Map<String, dynamic> m) =>
          m.keys.where((k) => !k.startsWith('@')).toSet();
      final en = keys(load('en'));
      final ml = keys(load('ml'));
      expect(en.difference(ml), isEmpty, reason: 'missing in app_ml.arb');
      expect(ml.difference(en), isEmpty, reason: 'unknown keys in app_ml.arb');
    });

    test('Malayalam keeps every placeholder', () {
      final en = load('en');
      final ml = load('ml');
      for (final entry in en.entries) {
        if (!entry.key.startsWith('@')) continue;
        final placeholders =
            (entry.value as Map)['placeholders'] as Map<String, dynamic>?;
        if (placeholders == null) continue;
        final key = entry.key.substring(1);
        for (final name in placeholders.keys) {
          expect((ml[key] as String).contains('{$name'), isTrue,
              reason: '$key lost {$name} in Malayalam');
        }
      }
    });
  });

  group('context-free strings follow the app language', () {
    test('AppDate uses Malayalam month names and relative words', () async {
      await initializeMlDates();
      L10n.setLocale(_ml);
      final d = DateTime(2026, 8, 5, 10, 24);
      expect(AppDate.formatDate(d), isNot(contains('Aug')));
      expect(AppDate.formatDate(d), contains('2026'));
      final now = DateTime(2026, 9, 28, 12);
      expect(AppDate.relative(DateTime(2026, 9, 27, 18), now: now), 'ഇന്നലെ');

      L10n.setLocale(_en);
      expect(AppDate.formatDate(d), '5 Aug 2026');
      expect(AppDate.relative(DateTime(2026, 9, 27, 18), now: now),
          'Yesterday');
    });

    test('ApiException.userMessage is localized', () {
      const e = ApiException(ApiErrorKind.network);
      L10n.setLocale(_ml);
      expect(e.userMessage, isNot(contains('server')));
      L10n.setLocale(_en);
      expect(e.userMessage, contains('server'));
    });
  });

  group('dark mode + Malayalam at 360dp, text scale 1.3', () {
    testWidgets('theme resolves the dark palette', (tester) async {
      late AppPalette palette;
      await pumpApp(tester, Builder(builder: (context) {
        palette = context.colors;
        return const SizedBox();
      }));
      expect(palette.isDark, isTrue);
      expect(palette.background, AppPalette.dark.background);
    });

    testWidgets('login screen', (tester) async {
      await pumpApp(tester, const LoginScreen());
      expect(tester.takeException(), isNull);
      expect(find.byType(AppLanguageButton), findsOneWidget);
    });

    testWidgets('onboarding screen', (tester) async {
      await pumpApp(tester, const OnboardingScreen());
      expect(tester.takeException(), isNull);
    });

    testWidgets('payment success', (tester) async {
      await pumpApp(
        tester,
        PaymentSuccessScreen(
          args: PaymentResultArgs.fromReceipt(
            kind: PaymentKind.dues,
            receipt: Map<String, dynamic>.from(_receipt),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('₹12,50,000'), findsOneWidget);
    });

    testWidgets('payment cancelled', (tester) async {
      await pumpApp(
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
    });

    testWidgets('receipt details', (tester) async {
      await pumpApp(
        tester,
        ReceiptDetailsScreen.fromJson(Map<String, dynamic>.from(_receipt)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('alert details', (tester) async {
      await pumpApp(
        tester,
        const AlertDetailsScreen(
          title: 'Friday prayer timing',
          body: 'Jumu’ah prayer starts at 12:45 PM from this week.',
          time: 'Just now',
          type: AlertType.overdue,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('member home hero, balance and latest payment cards',
        (tester) async {
      for (final outstanding in [0.0, 1250000.0]) {
        await pumpApp(
          tester,
          Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    decoration:
                        const BoxDecoration(color: AppBrand.teal),
                    child: DashboardHero(
                      firstName: 'Abdul Rahman',
                      mahalName: 'Juma Masjid Mahal, Kozhikode',
                      onAvatarTap: () {},
                      onHelpTap: () {},
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        BalanceCard(
                          outstanding: outstanding,
                          advanceCredit: 0,
                          pendingSummary: outstanding > 0
                              ? L10n.current.duesPendingMonths(3)
                              : null,
                          months: outstanding > 0
                              ? [
                                  DueMonth(DateTime(2026, 6),
                                      DueMonthStatus.overdue),
                                  DueMonth(DateTime(2026, 7),
                                      DueMonthStatus.overdue),
                                  DueMonth(DateTime(2026, 8),
                                      DueMonthStatus.dueNow),
                                ]
                              : const [],
                          paidUpToLabel: 'ഓഗസ്റ്റ് 2026',
                          onPayDues: () {},
                          onContribute: () {},
                        ),
                        const SizedBox(height: 16),
                        LatestPaymentCard(
                          receipt: Map<String, dynamic>.from(_receipt),
                          isUpToDate: outstanding == 0,
                          onViewReceipt: () {},
                          onPrimaryAction: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('settings sheet switches theme and language', (tester) async {
      AppSettings.instance.debugReset();
      addTearDown(AppSettings.instance.debugReset);
      await tester.pumpWidget(ListenableBuilder(
        listenable: AppSettings.instance,
        builder: (context, _) => MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: AppSettings.instance.themeMode,
          locale: AppSettings.instance.locale ?? _en,
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => AppSettingsSheet.show(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(AppSettings.instance.themeMode, ThemeMode.dark);

      await tester.tap(find.text('മലയാളം'));
      await tester.pumpAndSettle();
      expect(AppSettings.instance.language, AppLanguage.malayalam);
      // The sheet re-renders in Malayalam in place.
      expect(find.text('ഭാഷ'.toUpperCase()), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Loads intl's Malayalam date symbols for plain (non-widget) tests.
Future<void> initializeMlDates() async {
  // GlobalMaterialLocalizations loads these for widget tests; unit tests
  // need the explicit call.
  await GlobalMaterialLocalizations.delegate.load(_ml);
}

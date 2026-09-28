import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/navigation/app_routes.dart';
import 'core/navigation/route_not_found_screen.dart';
import 'core/services/push_notification_service.dart';
import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'l10n/l10n.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/otp_verification_screen.dart';
import 'features/auth/screens/register_member_screen.dart';
import 'features/auth/screens/pending_approval_screen.dart';
import 'features/admin/screens/pending_approvals_screen.dart';
import 'features/dashboard/screens/member_dashboard_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/dues_payment/screens/monthly_payment_screen.dart';
import 'features/contribution/screens/contribution_screen.dart';
import 'features/payment_result/screens/payment_success_screen.dart';
import 'features/payment_result/payment_result_args.dart';
import 'features/payment_result/screens/payment_failed_screen.dart';
import 'features/payment_result/screens/payment_pending_screen.dart';
import 'features/receipts/screens/receipts_history_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/edit_personal_details_screen.dart';
import 'features/autopay/screens/setup_autopay_screen.dart';
import 'features/alerts/screens/alerts_screen.dart';
import 'features/alerts/screens/alert_details_screen.dart';
import 'features/admin/screens/member_management_screen.dart';
import 'features/admin/screens/member_details_screen.dart';
import 'features/admin/screens/edit_member_details_screen.dart';
import 'features/admin/screens/financial_reports_screen.dart';
import 'features/admin/screens/audit_logs_screen.dart';
import 'features/admin/screens/gateway_configuration_screen.dart';
import 'features/admin/screens/bulk_excel_import_step1_screen.dart';
import 'features/admin/screens/bulk_excel_import_preview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Saved theme + language, read before the first frame so the app never
  // flashes the wrong theme or language.
  await AppSettings.instance.load();
  await initializeDateFormatting();

  // Noto Sans Malayalam is bundled (OFL); show its licence in the licence page.
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['google_fonts'], text);
  });

  // Firebase (reads android/app/google-services.json). Guarded so a
  // misconfigured environment still opens the app.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    // Fire-and-forget: permissions + token registration must not delay start.
    PushNotificationService.instance.init();
  } catch (e) {
    debugPrint('[FIREBASE] init failed: $e');
  }

  // Every screen paints its own gradient behind the status bar, so the app
  // draws edge to edge with light status-bar icons by default.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(AppPalette.light.gradientHeaderOverlay);

  runApp(const MahalFlowApp());
}

class MahalFlowApp extends StatelessWidget {
  const MahalFlowApp({super.key});

  /// Routes that take no arguments.
  static final Map<String, WidgetBuilder> _routes = {
    AppRoutes.splash: (context) => const SplashScreen(),
    AppRoutes.onboarding: (context) => const OnboardingScreen(),
    AppRoutes.login: (context) => const LoginScreen(),
    AppRoutes.adminPendingApprovals: (context) =>
        const PendingApprovalsScreen(),
    AppRoutes.memberDashboard: (context) => const MemberDashboardScreen(),
    AppRoutes.adminDashboard: (context) => const AdminDashboardScreen(),
    AppRoutes.memberPay: (context) => const MonthlyPaymentScreen(),
    AppRoutes.memberContribution: (context) => const ContributionScreen(),
    AppRoutes.memberReceipts: (context) => const ReceiptsHistoryScreen(),
    AppRoutes.memberProfile: (context) => const ProfileScreen(),
    AppRoutes.memberEditProfile: (context) => const EditPersonalDetailsScreen(),
    AppRoutes.memberAutopay: (context) => const SetupAutoPayScreen(),
    AppRoutes.memberAlerts: (context) => const AlertsScreen(),
    AppRoutes.memberAlertDetails: (context) => const AlertDetailsScreen(),
    AppRoutes.adminMembers: (context) => const MemberManagementScreen(),
    AppRoutes.adminReports: (context) => const FinancialReportsScreen(),
    AppRoutes.adminAuditLogs: (context) => const AuditLogsScreen(),
    AppRoutes.adminGateways: (context) => const GatewayConfigurationScreen(),
    AppRoutes.adminImportStep1: (context) => const BulkExcelImportStep1Screen(),
    AppRoutes.adminImportPreview: (context) =>
        const BulkExcelImportPreviewScreen(),
  };

  /// Routes that need arguments. A missing or wrong-typed argument sends the
  /// user to a safe screen instead of throwing a cast error.
  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    MaterialPageRoute<dynamic> page(String name, WidgetBuilder builder,
            {Object? arguments}) =>
        MaterialPageRoute<dynamic>(
          settings: RouteSettings(name: name, arguments: arguments),
          builder: builder,
        );

    switch (settings.name) {
      case AppRoutes.otp:
        if (args is OtpArgs) {
          return page(AppRoutes.otp, (_) => OtpVerificationScreen(args: args),
              arguments: args);
        }
        return page(AppRoutes.login, (_) => const LoginScreen());

      case AppRoutes.register:
        if (args is String && args.isNotEmpty) {
          return page(
              AppRoutes.register, (_) => RegisterMemberScreen(phone: args),
              arguments: args);
        }
        return page(AppRoutes.login, (_) => const LoginScreen());

      case AppRoutes.pendingApproval:
        final name = args is String ? args : null;
        return page(
            AppRoutes.pendingApproval, (_) => PendingApprovalScreen(name: name),
            arguments: name);

      // Payment results describe a real payment, so they require
      // PaymentResultArgs; without them there is nothing true to show.
      case AppRoutes.memberPaymentSuccess:
      case AppRoutes.memberPaymentFailed:
      case AppRoutes.memberPaymentPending:
        if (args is! PaymentResultArgs) {
          return page(
              AppRoutes.memberDashboard, (_) => const MemberDashboardScreen());
        }
        return page(
          settings.name!,
          (_) => switch (settings.name) {
            AppRoutes.memberPaymentSuccess => PaymentSuccessScreen(args: args),
            AppRoutes.memberPaymentFailed => PaymentFailedScreen(args: args),
            _ => PaymentPendingScreen(args: args),
          },
          arguments: args,
        );

      case AppRoutes.adminMemberDetails:
      case AppRoutes.adminEditMember:
        final member = args is Map ? Map<String, dynamic>.from(args) : null;
        if (member == null) {
          return page(
              AppRoutes.adminMembers, (_) => const MemberManagementScreen());
        }
        return page(
          settings.name!,
          (_) => settings.name == AppRoutes.adminMemberDetails
              ? MemberDetailsScreen(member: member)
              : EditMemberDetailsScreen(member: member),
          arguments: member,
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final settings = AppSettings.instance;
        return MaterialApp(
          onGenerateTitle: (context) => context.l10n.appName,
          debugShowCheckedModeBanner: false,
          navigatorKey: rootNavigatorKey,
          navigatorObservers: [AppRouteTracker.instance],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          // Device language decides only when it is one we ship; anything
          // else falls back to English.
          localeResolutionCallback: (device, supported) {
            for (final l in supported) {
              if (l.languageCode == device?.languageCode) return l;
            }
            return const Locale('en');
          },
          builder: (context, child) {
            // Keep context-free code (formatters, API errors, notification
            // text) in step with the resolved locale.
            L10n.setLocale(Localizations.localeOf(context));
            final palette = context.colors;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: palette.gradientHeaderOverlay,
              child: child ?? const SizedBox.shrink(),
            );
          },
          initialRoute: AppRoutes.splash,
          routes: _routes,
          onGenerateRoute: _onGenerateRoute,
          onUnknownRoute: (settings) => MaterialPageRoute<dynamic>(
            settings: settings,
            builder: (_) => RouteNotFoundScreen(routeName: settings.name),
          ),
        );
      },
    );
  }
}

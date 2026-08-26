import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/member_dashboard_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/dues_payment/screens/monthly_payment_screen.dart';
import 'features/contribution/screens/contribution_screen.dart';
import 'features/payment_result/screens/payment_success_screen.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MahalFlowApp());
}

class MahalFlowApp extends StatelessWidget {
  const MahalFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MahalFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/member/dashboard': (context) => const MemberDashboardScreen(),
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        '/member/monthly-payment': (context) => const MonthlyPaymentScreen(),
        '/member/contribution': (context) => const ContributionScreen(),
        '/member/payment-success': (context) => const PaymentSuccessScreen(),
        '/member/payment-failed': (context) => const PaymentFailedScreen(),
        '/member/payment-pending': (context) => const PaymentPendingScreen(),
        '/member/receipts': (context) => const ReceiptsHistoryScreen(),
        '/member/profile': (context) => const ProfileScreen(),
        '/member/edit-profile': (context) => const EditPersonalDetailsScreen(),
        '/member/setup-autopay': (context) => const SetupAutoPayScreen(),
        '/member/alerts': (context) => const AlertsScreen(),
        '/member/alert-details': (context) => const AlertDetailsScreen(),
        '/admin/members': (context) => const MemberManagementScreen(),
        '/admin/member-details': (context) => const MemberDetailsScreen(
          member: {"name": "Muhammed", "phone": "98765 43210", "amount": "₹500", "status": "Active", "id": "MH-2023-4829"},
        ),
        '/admin/edit-member': (context) => const EditMemberDetailsScreen(
          member: {"name": "Muhammed", "phone": "98765 43210", "amount": "₹500", "status": "Active", "id": "MH-2023-4829"},
        ),
        '/admin/reports': (context) => const FinancialReportsScreen(),
        '/admin/audit-logs': (context) => const AuditLogsScreen(),
        '/admin/gateways': (context) => const GatewayConfigurationScreen(),
        '/admin/import-step1': (context) => const BulkExcelImportStep1Screen(),
        '/admin/import-preview': (context) => const BulkExcelImportPreviewScreen(),
      },
    );
  }
}

import 'package:flutter/material.dart';

/// Named routes. Use these constants instead of string literals.
///
/// Routes marked *(args)* are built by `onGenerateRoute` in main.dart and
/// require arguments; a missing or wrong-typed argument redirects instead of
/// crashing (see each constant).
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  /// *(args)* `OtpArgs` — missing → [login].
  static const String otp = '/otp';

  /// *(args)* `String` E.164 phone — missing → [login].
  static const String register = '/register';

  /// Optional `String` name.
  static const String pendingApproval = '/pending-approval';

  // Member
  static const String memberDashboard = '/member/dashboard';
  static const String memberPay = '/member/pay';
  static const String memberContribution = '/member/contribution';
  static const String memberPaymentSuccess = '/member/payment-success';
  static const String memberPaymentFailed = '/member/payment-failed';
  static const String memberPaymentPending = '/member/payment-pending';
  static const String memberReceipts = '/member/receipts';
  static const String memberProfile = '/member/profile';
  static const String memberEditProfile = '/member/edit-profile';
  static const String memberAutopay = '/member/setup-autopay';
  static const String memberAlerts = '/member/alerts';
  static const String memberAlertDetails = '/member/alert-details';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminPendingApprovals = '/admin/pending-approvals';
  static const String adminMembers = '/admin/members';

  /// *(args)* `Map<String, dynamic>` member — missing → [adminMembers].
  static const String adminMemberDetails = '/admin/member-details';

  /// *(args)* `Map<String, dynamic>` member — missing → [adminMembers].
  static const String adminEditMember = '/admin/edit-member';
  static const String adminReports = '/admin/reports';
  static const String adminAuditLogs = '/admin/audit-logs';
  static const String adminGateways = '/admin/gateways';
  static const String adminImportStep1 = '/admin/import-step1';
  static const String adminImportPreview = '/admin/import-preview';

  /// Bottom-nav tab order.
  static const List<String> memberTabs = [
    memberDashboard,
    memberPay,
    memberReceipts,
    memberAlerts,
    memberProfile,
  ];

  static const List<String> adminTabs = [
    adminDashboard,
    adminMembers,
    adminReports,
    adminAuditLogs,
  ];
}

/// Tracks the names of the routes currently on the root navigator so tab
/// navigation can tell whether the home tab is already underneath.
/// Registered once in `MaterialApp.navigatorObservers`.
class AppRouteTracker extends NavigatorObserver {
  AppRouteTracker._();
  static final AppRouteTracker instance = AppRouteTracker._();

  final List<Route<dynamic>> _stack = [];

  bool contains(String name) => _stack.any((r) => r.settings.name == name);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (i >= 0 && newRoute != null) {
      _stack[i] = newRoute;
    } else {
      if (oldRoute != null) _stack.remove(oldRoute);
      if (newRoute != null) _stack.add(newRoute);
    }
  }
}

/// Bottom-nav navigation. The home tab (dashboard) is always the root of the
/// stack and every other tab sits one level above it, so:
///   * system Back from any tab returns to the dashboard (never exits the app);
///   * Back on the dashboard leaves the app;
///   * switching tabs never piles up history.
class AppNav {
  AppNav._();

  /// Go to [route] as a tab whose home is [root].
  static void switchTab(BuildContext context, String route,
      {required String root}) {
    final nav = Navigator.of(context);
    final rootInStack = AppRouteTracker.instance.contains(root);

    if (route == root) {
      if (rootInStack) {
        nav.popUntil(ModalRoute.withName(root));
      } else {
        nav.pushNamedAndRemoveUntil(root, (_) => false);
      }
      return;
    }

    if (rootInStack) {
      nav.pushNamedAndRemoveUntil(route, ModalRoute.withName(root));
    } else {
      // Entered a tab without the dashboard below it (deep link, push tap):
      // rebuild the stack as [root, route] so Back still lands on home.
      nav.pushNamedAndRemoveUntil(root, (_) => false);
      nav.pushNamed(route);
    }
  }

  static void switchMemberTab(BuildContext context, String route) =>
      switchTab(context, route, root: AppRoutes.memberDashboard);

  static void switchAdminTab(BuildContext context, String route) =>
      switchTab(context, route, root: AppRoutes.adminDashboard);

  /// Header back button on a tab screen: return to the tab's home.
  static void memberHome(BuildContext context) =>
      switchMemberTab(context, AppRoutes.memberDashboard);

  static void adminHome(BuildContext context) =>
      switchAdminTab(context, AppRoutes.adminDashboard);
}

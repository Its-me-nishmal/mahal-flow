import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/network/api_service.dart';
import '../../core/storage/app_prefs.dart';
import '../../l10n/l10n.dart';

/// Outcome of resolving an OTP-verified phone against the backend.
///
/// [signedOut] means there is no usable Firebase sign-in (no current user, or
/// the server rejected its ID token): the user has to verify their phone
/// again. [rejected] means the committee declined the registration: the
/// server issues no token, so there is no session.
enum ResolveStatus {
  allowed,
  pending,
  rejected,
  unregistered,
  networkError,
  signedOut,
}

class ResolveResult {
  final ResolveStatus status;
  final bool isAdmin;
  final String? name;

  /// The phone that was resolved (E.164).
  final String phone;

  const ResolveResult({
    required this.status,
    required this.phone,
    this.isAdmin = false,
    this.name,
  });
}

/// The single place that decides where a signed-in phone goes. Used by the
/// OTP screen, Android instant verification on the login screen, the splash
/// (returning user) and the pending-approval re-check, so every entry point
/// routes — and records the last role — identically.
class AuthFlow {
  AuthFlow._();

  static final ApiService _api = ApiService();

  /// The signed-in Firebase user's ID token, or null when nobody is signed in
  /// (or Firebase is unavailable). The backend verifies it and takes the
  /// phone number from it — it is the only proof of phone ownership.
  static Future<String?> idToken({bool forceRefresh = false}) async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('[AUTH] getIdToken failed: $e');
      return null;
    }
  }

  /// Wire [ApiService]'s 401 recovery to Firebase: a fresh ID token is
  /// exchanged for a new session JWT. Called once from main().
  static void installSessionRefresh() {
    ApiService.reauthenticate = () async {
      final token = await idToken(forceRefresh: true);
      if (token == null) return false;
      try {
        final res = await _api.resolveLoginOrThrow(idToken: token);
        return res['status'] == 'ALLOWED' && ApiService.authToken != null;
      } on ApiException {
        return false;
      }
    };
  }

  /// Resolve the Firebase-signed-in user. [phone] is only echoed back for
  /// routing (registration prefill); the server uses the ID token's phone.
  static Future<ResolveResult> resolve(String phone) async {
    final token = await idToken();
    if (token == null) {
      return ResolveResult(status: ResolveStatus.signedOut, phone: phone);
    }
    return _resolveWith(phone, () => _api.resolveLoginOrThrow(idToken: token));
  }

  /// Debug builds only: sign in as a seeded phone without OTP. Works solely
  /// against a local server started with AUTH_DEV_BYPASS=true.
  static Future<ResolveResult> resolveDemo(String phone) {
    assert(kDebugMode);
    return _resolveWith(
        phone, () => _api.resolveLoginOrThrow(devPhone: phone));
  }

  static Future<ResolveResult> _resolveWith(
    String phone,
    Future<Map<String, dynamic>> Function() call,
  ) async {
    final Map<String, dynamic> resolved;
    try {
      resolved = await call();
    } on ApiException catch (e) {
      debugPrint('[AUTH] resolve failed: $e');
      // 401: the ID token was refused — the phone must be verified again.
      final status = e.kind == ApiErrorKind.unauthorized
          ? ResolveStatus.signedOut
          : ResolveStatus.networkError;
      return ResolveResult(status: status, phone: phone);
    }
    final name = resolved['name']?.toString();
    switch (resolved['status']?.toString()) {
      case 'ALLOWED':
        final role = resolved['role']?.toString();
        final isAdmin = role == 'MAHAL_ADMIN' || role == 'SUPER_ADMIN';
        await AppPrefs.setLastRole(isAdmin ? 'admin' : 'member');
        return ResolveResult(
          status: ResolveStatus.allowed,
          phone: phone,
          isAdmin: isAdmin,
          name: name,
        );
      case 'PENDING':
        return ResolveResult(
          status: ResolveStatus.pending,
          phone: phone,
          name: name,
        );
      case 'REJECTED':
        return ResolveResult(
          status: ResolveStatus.rejected,
          phone: phone,
          name: name,
        );
      default:
        return ResolveResult(status: ResolveStatus.unregistered, phone: phone);
    }
  }

  /// Replace the whole stack with the screen for [result]. Does nothing for
  /// [ResolveStatus.networkError] — the caller shows the error.
  static void route(NavigatorState nav, ResolveResult result) {
    switch (result.status) {
      case ResolveStatus.allowed:
        nav.pushNamedAndRemoveUntil(
          result.isAdmin ? AppRoutes.adminDashboard : AppRoutes.memberDashboard,
          (_) => false,
        );
      case ResolveStatus.pending:
        nav.pushNamedAndRemoveUntil(
          AppRoutes.pendingApproval,
          (_) => false,
          arguments: result.name,
        );
      case ResolveStatus.rejected:
        nav.pushNamedAndRemoveUntil(
          AppRoutes.registrationRejected,
          (_) => false,
          arguments: result.name,
        );
      case ResolveStatus.unregistered:
        nav.pushNamedAndRemoveUntil(
          AppRoutes.register,
          (_) => false,
          arguments: result.phone,
        );
      case ResolveStatus.signedOut:
        nav.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      case ResolveStatus.networkError:
        break;
    }
  }

  /// Leave the app for sign-in after an unrecoverable 401. Clears the local
  /// session (the Firebase user is kept so the next OTP-free resolve can
  /// still work if the server recovers).
  static Future<void> handleSessionExpired(NavigatorState? nav) async {
    // Several in-flight requests can fail together; navigate once.
    if (_expiring) return;
    _expiring = true;
    try {
      await ApiService.logout();
      if (nav == null || !nav.mounted) return;
      nav.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    } finally {
      _expiring = false;
    }
  }

  static bool _expiring = false;

  /// [resolve] then [route]. Returns the result so the caller can show an
  /// error on [ResolveStatus.networkError].
  static Future<ResolveResult> resolveAndRoute(
    NavigatorState nav,
    String phone,
  ) async {
    final result = await resolve(phone);
    if (nav.mounted) route(nav, result);
    return result;
  }

  /// Member-facing text for a Firebase phone-auth failure. Firebase's own
  /// `e.message` is English developer text, so it is never shown; unknown
  /// codes fall back to [fallback].
  static String firebaseErrorMessage(
    BuildContext context,
    FirebaseAuthException e, {
    required String fallback,
  }) {
    final l10n = context.l10n;
    return switch (e.code) {
      'invalid-phone-number' || 'missing-phone-number' => l10n.authInvalidPhone,
      'too-many-requests' => l10n.authTooManyRequests,
      'quota-exceeded' => l10n.authQuotaExceeded,
      'network-request-failed' => l10n.authNetworkFailed,
      'invalid-verification-code' => l10n.authInvalidCode,
      'session-expired' ||
      'code-expired' ||
      'invalid-verification-id' =>
        l10n.authSessionExpired,
      'app-not-authorized' ||
      'missing-client-identifier' ||
      'invalid-app-credential' ||
      'captcha-check-failed' =>
        l10n.authAppNotVerified,
      _ => fallback,
    };
  }

  /// True when [token] is a JWT whose `exp` is in the past (or within a
  /// minute of it). Unparseable tokens count as not expired — the server
  /// remains the authority and will 401.
  static bool isJwtExpired(String? token) {
    if (token == null || token.isEmpty) return true;
    final parts = token.split('.');
    if (parts.length != 3) return false;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload is Map ? payload['exp'] : null;
      if (exp is! num) return false;
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return DateTime.now()
          .isAfter(expiry.subtract(const Duration(minutes: 1)));
    } catch (_) {
      return false;
    }
  }
}

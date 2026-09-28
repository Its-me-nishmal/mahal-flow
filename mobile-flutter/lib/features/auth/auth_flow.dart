import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/navigation/app_routes.dart';
import '../../core/network/api_service.dart';
import '../../core/storage/app_prefs.dart';
import '../../l10n/l10n.dart';

/// Outcome of resolving an OTP-verified phone against the backend.
enum ResolveStatus { allowed, pending, unregistered, networkError }

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

  static Future<ResolveResult> resolve(String phone) async {
    final resolved = await _api.resolveLogin(phone);
    if (resolved == null) {
      return ResolveResult(status: ResolveStatus.networkError, phone: phone);
    }
    final name = resolved['name']?.toString();
    switch (resolved['status']?.toString()) {
      case 'ALLOWED':
        final isAdmin = resolved['role']?.toString() == 'MAHAL_ADMIN';
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
      case ResolveStatus.unregistered:
        nav.pushNamedAndRemoveUntil(
          AppRoutes.register,
          (_) => false,
          arguments: result.phone,
        );
      case ResolveStatus.networkError:
        break;
    }
  }

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

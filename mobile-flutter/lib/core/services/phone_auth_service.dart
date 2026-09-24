import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase phone-number (OTP) authentication.
///
/// Flow: [sendOtp] triggers an SMS and returns a verificationId via the
/// [codeSent] callback; the user types the code and the UI calls [verifyOtp]
/// with that verificationId. On success the caller gets a Firebase ID token,
/// which the backend can trust to issue its own session JWT.
class PhoneAuthService {
  PhoneAuthService._();
  static final PhoneAuthService instance = PhoneAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Normalize an Indian mobile number to E.164 (+91…). Accepts input with or
  /// without country code, spaces or punctuation.
  static String toE164(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (raw.trim().startsWith('+')) return '+$digits';
    if (digits.length == 10) return '+91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return '+$digits';
    return '+$digits';
  }

  /// Start phone verification. Returns immediately; results arrive via callbacks.
  /// - [autoVerified]: Android may auto-retrieve the SMS and sign in without a code.
  /// - [codeSent]: SMS dispatched; use the verificationId in [verifyOtp].
  /// - [failed]: verification could not start (bad number, quota, missing SHA-1…).
  Future<void> sendOtp({
    required String phone,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(FirebaseAuthException e) failed,
    void Function(UserCredential credential)? autoVerified,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: toE164(phone),
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final cred = await _auth.signInWithCredential(credential);
          autoVerified?.call(cred);
        } catch (e) {
          debugPrint('[PHONE_AUTH] auto-verify sign-in failed: $e');
        }
      },
      verificationFailed: failed,
      codeSent: (String verificationId, int? token) =>
          codeSent(verificationId, token),
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  /// Confirm the SMS code and sign in. Returns the Firebase ID token on success.
  Future<String?> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user?.getIdToken();
  }

  String? get currentUid => _auth.currentUser?.uid;
  String? get currentPhone => _auth.currentUser?.phoneNumber;

  Future<void> signOut() => _auth.signOut();
}

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/phone_auth_service.dart';
import '../../../core/storage/app_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../auth_flow.dart';
import 'otp_verification_screen.dart';
import '../../../core/widgets/app_settings_sheet.dart';
import '../../../l10n/l10n.dart';

/// Sign in. Same gradient header and floating card as the member home, so the
/// first screen after the welcome already looks like the app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// If Firebase never calls back (no network, Play Services stalled), give
  /// the button back rather than spinning forever.
  static const Duration _sendWatchdog = Duration(seconds: 45);

  final TextEditingController _phoneController = TextEditingController();
  late final TapGestureRecognizer _termsTap = TapGestureRecognizer()
    ..onTap = () => _openLink(AppConfig.termsUrl);
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => _openLink(AppConfig.privacyUrl);

  String? _error;
  bool _isSubmitting = false;
  Timer? _watchdog;

  @override
  void dispose() {
    _watchdog?.cancel();
    _phoneController.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _stopSubmitting({String? error}) {
    _watchdog?.cancel();
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _error = error;
    });
  }

  Future<void> _continue() async {
    if (_isSubmitting) return;
    final digits = PhoneFormat.nationalDigits(_phoneController.text);
    if (digits.isEmpty) {
      setState(() => _error = context.l10n.loginPhoneRequired);
      return;
    }
    if (!PhoneFormat.isValidIndianMobile(digits)) {
      setState(() => _error = context.l10n.loginPhoneInvalid);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    // Resolved now: the callbacks below may fire after the context is gone.
    final l10n = context.l10n;
    _watchdog?.cancel();
    _watchdog = Timer(_sendWatchdog, () {
      if (_isSubmitting) {
        _stopSubmitting(error: l10n.loginSendTimeout);
      }
    });

    final e164 = PhoneAuthService.toE164(digits);
    try {
      // Real sign-in: send a Firebase OTP, then verify on the next screen.
      await PhoneAuthService.instance.sendOtp(
        phone: digits,
        codeSent: (verificationId, resendToken) {
          _stopSubmitting();
          if (!mounted) return;
          Navigator.of(context).pushNamed(
            AppRoutes.otp,
            arguments: OtpArgs(
              phone: e164,
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        },
        autoVerified: (_) async {
          // Android instant verification: Firebase already signed in, so
          // skip the OTP screen but route exactly as it would.
          if (!mounted) return;
          final result =
              await AuthFlow.resolveAndRoute(Navigator.of(context), e164);
          if (result.status == ResolveStatus.networkError) {
            _stopSubmitting(error: l10n.authSignedInServerUnreachable);
          } else {
            _watchdog?.cancel();
          }
        },
        failed: (FirebaseAuthException e) {
          debugPrint(
              '[LOGIN] verifyPhoneNumber failed: ${e.code} ${e.message}');
          if (!mounted) return;
          _stopSubmitting(
            error: AuthFlow.firebaseErrorMessage(
              context,
              e,
              fallback: l10n.loginSendFailed,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('[LOGIN] sendOtp failed: $e');
      _stopSubmitting(error: l10n.loginSendFailed);
    }
  }

  /// Debug builds only: open a dashboard with seed data, skipping OTP.
  Future<void> _enterDemo(String role) async {
    assert(kDebugMode);
    if (_isSubmitting) return;
    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    final l10n = context.l10n;
    if (role == 'admin') {
      // Admin routes require a JWT; without it every /admin/* call 401s.
      final ok = await ApiService().login(phone: '9847123456');
      if (!ok) {
        _stopSubmitting(error: l10n.loginDemoServerError);
        return;
      }
    } else {
      // Seed member from the local backend's fixtures.
      ApiService.sessionMemberId ??= 'MEM_001_9910';
    }

    await AppPrefs.setLastRole(role);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.of(context).pushNamedAndRemoveUntil(
      role == 'admin' ? AppRoutes.adminDashboard : AppRoutes.memberDashboard,
      (_) => false,
    );
  }

  Future<void> _openLink(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.loginLinkOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: context.l10n.loginTitle,
      eyebrow: 'MahalFlow',
      subtitle: context.l10n.loginSubtitle,
      showBack: false,
      actions: const [AppLanguageButton()],
      floatingChild: _signInCard(),
      content: [
        if (kDebugMode) ...[
          const SizedBox(height: AppSpacing.md),
          _demoCard(),
        ],
        const SizedBox(height: AppSpacing.md),
        _terms(),
      ],
    );
  }

  Widget _signInCard() {
    return AppCard.floating(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionLabel(context.l10n.loginSignIn),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _phoneController,
            label: context.l10n.authMobileNumber,
            hint: '98471 23456',
            helperText: context.l10n.loginPhoneHelper,
            icon: Icons.phone_iphone_rounded,
            prefixText: '+91 ',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [
              AutofillHints.telephoneNumberNational,
              AutofillHints.telephoneNumber,
            ],
            inputFormatters: [_IndianMobileFormatter()],
            enabled: !_isSubmitting,
            errorText: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _continue(),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: context.l10n.commonContinue,
            icon: Icons.arrow_forward_rounded,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _continue,
          ),
        ],
      ),
    );
  }

  Widget _demoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionLabel(context.l10n.loginDemoTitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.loginDemoBody,
            style: context.text.small,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: context.l10n.commonMember,
                  icon: Icons.person_outline_rounded,
                  height: AppSizes.buttonHeightCompact,
                  onPressed: _isSubmitting ? null : () => _enterDemo('member'),
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: AppSecondaryButton(
                  label: context.l10n.loginDemoCommittee,
                  icon: Icons.admin_panel_settings_outlined,
                  height: AppSizes.buttonHeightCompact,
                  onPressed: _isSubmitting ? null : () => _enterDemo('admin'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _terms() {
    final linkStyle = context.text.small.copyWith(
      color: context.colors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: context.colors.primary,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text.rich(
        TextSpan(
          text: context.l10n.loginTermsPrefix,
          style:
              context.text.small.copyWith(color: context.colors.textSecondary),
          children: [
            TextSpan(
              text: context.l10n.loginTermsLink,
              style: linkStyle,
              recognizer: _termsTap,
              semanticsLabel:
                  context.l10n.loginLinkSemantics(context.l10n.loginTermsLink),
            ),
            TextSpan(text: context.l10n.loginTermsAnd),
            TextSpan(
              text: context.l10n.loginPrivacyLink,
              style: linkStyle,
              recognizer: _privacyTap,
              semanticsLabel: context.l10n
                  .loginLinkSemantics(context.l10n.loginPrivacyLink),
            ),
            TextSpan(text: context.l10n.loginTermsSuffix),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Digits only, max 10. A pasted or autofilled "+91 98471 23456" /
/// "098471 23456" is reduced to its 10-digit national number instead of being
/// truncated to "9198471234".
class _IndianMobileFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      if (digits.startsWith('91') && digits.length == 12) {
        digits = digits.substring(2);
      } else if (digits.startsWith('0') && digits.length == 11) {
        digits = digits.substring(1);
      } else {
        digits = digits.substring(0, 10);
      }
    }
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

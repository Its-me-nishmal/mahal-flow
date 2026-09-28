import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/phone_auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/l10n.dart';
import '../auth_flow.dart';

/// Arguments passed from the login screen after the first OTP is sent.
class OtpArgs {
  /// E.164, e.g. "+919847123456".
  final String phone;
  final String verificationId;
  final int? resendToken;
  const OtpArgs({
    required this.phone,
    required this.verificationId,
    this.resendToken,
  });
}

class OtpVerificationScreen extends StatefulWidget {
  final OtpArgs args;

  const OtpVerificationScreen({super.key, required this.args});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _codeLength = 6;

  final TextEditingController _codeController = TextEditingController();

  late OtpArgs _args = widget.args;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;

  Timer? _cooldownTimer;
  int _cooldown = 0;

  @override
  void initState() {
    super.initState();
    // The first code was just sent from the login screen.
    _startCooldown(rebuild: false);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown({bool rebuild = true}) {
    _cooldownTimer?.cancel();
    _cooldown = AppConfig.otpResendCooldownSeconds;
    if (rebuild) setState(() {});
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  void _onCodeChanged(String value) {
    if (_error != null) setState(() => _error = null);
    // Auto-submit once the full code is in (typed or SMS autofill).
    if (value.length == _codeLength && !_isVerifying) _verify();
  }

  Future<void> _verify() async {
    if (_isVerifying) return;
    final code = _codeController.text.trim();
    if (code.length < _codeLength) {
      setState(() => _error = context.l10n.otpCodeRequired);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _isVerifying = true;
    });

    try {
      await PhoneAuthService.instance.verifyOtp(
        verificationId: _args.verificationId,
        smsCode: code,
      );
      await _completeLogin();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _error = AuthFlow.firebaseErrorMessage(
          context,
          e,
          fallback: context.l10n.otpVerificationFailed,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _error = context.l10n.otpVerificationFailed;
      });
    }
  }

  /// OTP is confirmed by Firebase. Resolve the phone against the backend to
  /// learn who this is (admin / active member / pending / unregistered) and
  /// route accordingly.
  Future<void> _completeLogin() async {
    final result =
        await AuthFlow.resolveAndRoute(Navigator.of(context), _args.phone);
    if (!mounted) return;
    if (result.status == ResolveStatus.networkError) {
      setState(() {
        _isVerifying = false;
        _error = context.l10n.authSignedInServerUnreachable;
      });
    }
  }

  Future<void> _resend() async {
    if (_isResending || _cooldown > 0 || _isVerifying) return;
    setState(() {
      _isResending = true;
      _error = null;
    });
    try {
      await PhoneAuthService.instance.sendOtp(
        phone: _args.phone,
        resendToken: _args.resendToken,
        codeSent: (verificationId, token) {
          if (!mounted) return;
          setState(() {
            _args = OtpArgs(
              phone: _args.phone,
              verificationId: verificationId,
              resendToken: token,
            );
            _isResending = false;
          });
          _codeController.clear();
          _startCooldown();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.otpNewCodeSent)),
          );
        },
        failed: (e) {
          if (!mounted) return;
          setState(() {
            _isResending = false;
            _error = AuthFlow.firebaseErrorMessage(
              context,
              e,
              fallback: context.l10n.otpResendFailed,
            );
          });
        },
        autoVerified: (_) {
          if (!mounted) return;
          setState(() {
            _isResending = false;
            _isVerifying = true;
          });
          _completeLogin();
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isResending = false;
        _error = context.l10n.otpResendFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = PhoneFormat.display(_args.phone);
    final canResend = _cooldown <= 0 && !_isResending && !_isVerifying;
    final l10n = context.l10n;
    final resendLabel = _isResending
        ? l10n.otpSending
        : _cooldown > 0
            ? l10n.otpResendIn(_cooldown)
            : l10n.otpResend;

    return AppPageScaffold(
      title: l10n.otpTitle,
      eyebrow: 'MahalFlow',
      subtitle: l10n.otpSubtitle(phone),
      floatingChild: AppCard.floating(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionLabel(l10n.otpSectionLabel),
            const SizedBox(height: AppSpacing.sm),
            AutofillGroup(
              child: AppTextField(
                controller: _codeController,
                label: l10n.otpCodeLabel,
                hint: '••••••',
                keyboardType: TextInputType.number,
                autofocus: true,
                autofillHints: const [AutofillHints.oneTimeCode],
                textInputAction: TextInputAction.done,
                enabled: !_isVerifying,
                errorText: _error,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(_codeLength),
                ],
                onChanged: _onCodeChanged,
                onSubmitted: (_) => _verify(),
              ),
            ),
          ],
        ),
      ),
      content: [
        const SizedBox(height: AppSpacing.md),
        Semantics(
          liveRegion: _cooldown == 0,
          child: AppTextActionButton(
            label: resendLabel,
            icon: Icons.refresh_rounded,
            color:
                canResend ? context.colors.primary : context.colors.textMuted,
            onPressed: canResend ? _resend : null,
          ),
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: _isVerifying ? l10n.otpVerifying : l10n.otpVerifyContinue,
            icon: Icons.check_rounded,
            isLoading: _isVerifying,
            onPressed: _isVerifying ? null : _verify,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: l10n.otpChangeNumber,
            color: context.colors.textSecondary,
            onPressed: _isVerifying ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

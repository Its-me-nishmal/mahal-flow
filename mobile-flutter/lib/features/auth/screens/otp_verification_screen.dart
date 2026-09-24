import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_service.dart';
import '../../../core/services/phone_auth_service.dart';
import '../../../core/storage/app_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';

/// Arguments passed from the login screen after the first OTP is sent.
class OtpArgs {
  final String phone;
  final String verificationId;
  final int? resendToken;
  final bool isAdmin;
  const OtpArgs({
    required this.phone,
    required this.verificationId,
    required this.isAdmin,
    this.resendToken,
  });
}

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _codeController = TextEditingController();

  late OtpArgs _args;
  bool _argsLoaded = false;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      _args = ModalRoute.of(context)!.settings.arguments as OtpArgs;
      _argsLoaded = true;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
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
      setState(() {
        _isVerifying = false;
        _error = e.code == 'invalid-verification-code'
            ? 'That code is incorrect. Try again.'
            : (e.message ?? 'Verification failed');
      });
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _error = 'Verification failed. Try again.';
      });
    }
  }

  /// OTP is confirmed by Firebase. Resolve the phone against the backend to
  /// learn who this is (admin / active member / pending / unregistered) and
  /// route accordingly.
  Future<void> _completeLogin() async {
    final resolved = await _apiService.resolveLogin(_args.phone);
    if (!mounted) return;

    if (resolved == null) {
      setState(() {
        _isVerifying = false;
        _error = 'Signed in, but could not reach the server. Try again.';
      });
      return;
    }

    final status = resolved['status']?.toString();
    final role = resolved['role']?.toString();

    if (status == 'ALLOWED') {
      final isAdmin = role == 'MAHAL_ADMIN';
      await AppPrefs.setLastRole(isAdmin ? 'admin' : 'member');
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        isAdmin ? '/admin/dashboard' : '/member/dashboard',
        (route) => false,
      );
      return;
    }

    if (status == 'PENDING') {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/pending-approval',
        (route) => false,
        arguments: resolved['name']?.toString(),
      );
      return;
    }

    // UNREGISTERED — collect identity (Mahal ID + name) and register.
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/register',
      (route) => false,
      arguments: _args.phone,
    );
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _error = null;
    });
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
            isAdmin: _args.isAdmin,
          );
          _isResending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('A new code has been sent.')),
        );
      },
      failed: (e) {
        if (!mounted) return;
        setState(() {
          _isResending = false;
          _error = e.message ?? 'Could not resend the code';
        });
      },
      autoVerified: (_) => _completeLogin(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Verify your number',
      eyebrow: 'MahalFlow',
      subtitle: 'Enter the 6-digit code sent to ${_args.phone}.',
      floatingChild: AppCard.floating(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionLabel('One-time password'),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _codeController,
              label: '6-digit code',
              hint: '••••••',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTextStyles.small.copyWith(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
      content: [
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: _isResending ? null : _resend,
          child: Text(_isResending ? 'Sending…' : 'Resend code'),
        ),
      ],
      bottomBar: AppBottomActionBar(
        children: [
          AppPrimaryButton(
            label: _isVerifying ? 'Verifying…' : 'Verify & continue',
            icon: Icons.check_rounded,
            isLoading: _isVerifying,
            onPressed: _isVerifying ? null : _verify,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSecondaryButton(
            label: 'Change number',
            color: AppColors.textSecondary,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

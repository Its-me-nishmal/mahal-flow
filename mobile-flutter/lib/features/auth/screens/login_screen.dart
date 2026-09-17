import 'package:flutter/material.dart';

import '../../../core/storage/app_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';

/// Sign in. Same gradient header and floating card as the member home, so the
/// first screen after the welcome already looks like the app.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? _error;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final phone = _phoneController.text.trim();
    // The backend has no OTP endpoint yet; the field still has to reject
    // obvious nonsense rather than hand a broken session to the dashboard.
    if (phone.isEmpty) {
      setState(() => _error = 'Enter your registered mobile number');
      return;
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final isDemoAdmin = phone.toLowerCase().contains('admin');
    if (!isDemoAdmin && digits.length < 10) {
      setState(() => _error = 'That does not look like a 10-digit number');
      return;
    }

    setState(() {
      _error = null;
      _isSubmitting = true;
    });

    final isAdmin = isDemoAdmin || digits == '9847123456';
    await _enter(isAdmin ? 'admin' : 'member');
  }

  Future<void> _enter(String role) async {
    await AppPrefs.setLastRole(role);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.of(context).pushReplacementNamed(
      role == 'admin' ? '/admin/dashboard' : '/member/dashboard',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Welcome back',
      eyebrow: 'MahalFlow',
      subtitle: 'Sign in to see your dues, pay them and keep your receipts.',
      showBack: false,
      floatingChild: _signInCard(),
      content: [
        const SizedBox(height: AppSpacing.md),
        _demoCard(),
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
          const AppSectionLabel('Sign in'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _phoneController,
            label: 'Mobile number',
            hint: 'Registered mobile number',
            icon: Icons.phone_iphone_rounded,
            keyboardType: TextInputType.phone,
            errorText: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            isLoading: _isSubmitting,
            onPressed: _continue,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
                child: Text('or', style: AppTextStyles.small),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => _enter('member'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 20, height: 20, child: _GoogleIcon()),
                  const SizedBox(width: AppSpacing.ms),
                  Text(
                    'Continue with Google',
                    style: AppTextStyles.button.copyWith(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
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
          const AppSectionLabel('Demo access'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Open the app with sample data while sign-in is being wired up.',
            style: AppTextStyles.small,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: 'Member',
                  icon: Icons.person_outline_rounded,
                  height: 46,
                  onPressed: () => _enter('member'),
                ),
              ),
              const SizedBox(width: AppSpacing.ms),
              Expanded(
                child: AppSecondaryButton(
                  label: 'Committee',
                  icon: Icons.admin_panel_settings_outlined,
                  height: 46,
                  onPressed: () => _enter('admin'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _terms() {
    return Text.rich(
      TextSpan(
        text: 'By continuing you agree to our ',
        style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
        children: [
          TextSpan(
            text: 'Terms of Service',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: AppTextStyles.small.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GoogleIconPainter(),
      size: const Size(20, 20),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24;

    // Blue section (top-right quadrant of the G)
    final Path bluePath = Path()
      ..moveTo(22.56 * s, 12.25 * s)
      ..cubicTo(22.56 * s, 11.47 * s, 22.49 * s, 10.72 * s, 22.36 * s, 10.0 * s)
      ..lineTo(12.0 * s, 10.0 * s)
      ..lineTo(12.0 * s, 14.26 * s)
      ..lineTo(17.92 * s, 14.26 * s)
      ..cubicTo(17.66 * s, 15.63 * s, 16.88 * s, 16.79 * s, 15.71 * s, 17.57 * s)
      ..lineTo(15.71 * s, 20.34 * s)
      ..lineTo(19.28 * s, 20.34 * s)
      ..cubicTo(21.36 * s, 18.42 * s, 22.56 * s, 15.6 * s, 22.56 * s, 12.25 * s)
      ..close();

    // Green section (bottom of the G)
    final Path greenPath = Path()
      ..moveTo(12.0 * s, 23.0 * s)
      ..cubicTo(14.97 * s, 23.0 * s, 17.46 * s, 22.02 * s, 19.28 * s, 20.34 * s)
      ..lineTo(15.71 * s, 17.57 * s)
      ..cubicTo(14.73 * s, 18.23 * s, 13.48 * s, 18.63 * s, 12.0 * s, 18.63 * s)
      ..cubicTo(9.14 * s, 18.63 * s, 6.71 * s, 16.7 * s, 5.84 * s, 14.1 * s)
      ..lineTo(2.18 * s, 14.1 * s)
      ..lineTo(2.18 * s, 16.94 * s)
      ..cubicTo(3.99 * s, 20.54 * s, 7.7 * s, 23.0 * s, 12.0 * s, 23.0 * s)
      ..close();

    // Yellow section (left side of the G)
    final Path yellowPath = Path()
      ..moveTo(5.84 * s, 14.09 * s)
      ..cubicTo(5.62 * s, 13.43 * s, 5.49 * s, 12.73 * s, 5.49 * s, 12.0 * s)
      ..cubicTo(5.49 * s, 11.27 * s, 5.62 * s, 10.57 * s, 5.84 * s, 9.91 * s)
      ..lineTo(5.84 * s, 7.07 * s)
      ..lineTo(2.18 * s, 7.07 * s)
      ..cubicTo(1.43 * s, 8.55 * s, 1.0 * s, 10.22 * s, 1.0 * s, 12.0 * s)
      ..cubicTo(1.0 * s, 13.78 * s, 1.43 * s, 15.45 * s, 2.18 * s, 16.93 * s)
      ..lineTo(5.03 * s, 14.71 * s)
      ..lineTo(5.84 * s, 14.09 * s)
      ..close();

    // Red section (top-left quadrant of the G)
    final Path redPath = Path()
      ..moveTo(12.0 * s, 5.38 * s)
      ..cubicTo(13.62 * s, 5.38 * s, 15.06 * s, 5.94 * s, 16.21 * s, 7.02 * s)
      ..lineTo(19.36 * s, 3.87 * s)
      ..cubicTo(17.45 * s, 2.09 * s, 14.97 * s, 1.0 * s, 12.0 * s, 1.0 * s)
      ..cubicTo(7.7 * s, 1.0 * s, 3.99 * s, 3.47 * s, 2.18 * s, 7.07 * s)
      ..lineTo(5.84 * s, 9.91 * s)
      ..cubicTo(6.71 * s, 7.31 * s, 9.14 * s, 5.38 * s, 12.0 * s, 5.38 * s)
      ..close();

    canvas.drawPath(redPath, Paint()..color = const Color(0xFFEA4335));
    canvas.drawPath(yellowPath, Paint()..color = const Color(0xFFFBBC05));
    canvas.drawPath(greenPath, Paint()..color = const Color(0xFF34A853));
    canvas.drawPath(bluePath, Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

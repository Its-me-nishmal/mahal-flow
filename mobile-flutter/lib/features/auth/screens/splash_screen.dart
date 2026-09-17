import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/storage/app_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Brand splash. Holds for a fixed minimum so the logo does not flash, and
/// resolves the first-run gate while it waits — the welcome carousel is shown
/// only until it has been completed once.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _minimumHold = Duration(milliseconds: 1700);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _rise;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _rise = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Read the flag and hold the splash at the same time, so a slow keystore
    // never adds to the wait a member sees.
    final results = await Future.wait([
      AppPrefs.hasSeenOnboarding(),
      Future.delayed(_minimumHold).then((_) => false),
    ]);
    if (!mounted) return;

    final seenOnboarding = results.first;
    Navigator.of(context).pushReplacementNamed(
      seenOnboarding ? '/login' : '/onboarding',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.hero),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: AnimatedBuilder(
                animation: _rise,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _rise.value),
                  child: child,
                ),
                child: Column(
                  children: [
                    const Spacer(flex: 4),
                    _mark(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'MahalFlow',
                      style: AppTextStyles.display.copyWith(
                        color: Colors.white,
                        fontSize: 34,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Dues, contributions and receipts\nfor your Mahal',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.76),
                      ),
                    ),
                    const Spacer(flex: 4),
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(
                          Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Secure payments · Verified receipts',
                      style: AppTextStyles.small.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The brand mark. Deliberately the glyph rather than assets/images/logo.png:
  /// that asset is a wordmark, and squeezing a wordmark into a square next to
  /// the "MahalFlow" type below it reads as a mistake.
  Widget _mark() {
    return Container(
      width: 104,
      height: 104,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: const Icon(Icons.mosque_rounded, size: 50, color: Colors.white),
    );
  }
}

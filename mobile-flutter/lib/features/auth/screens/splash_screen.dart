import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/navigation/app_routes.dart';
import '../../../core/network/api_service.dart';
import '../../../core/services/phone_auth_service.dart';
import '../../../core/storage/app_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/l10n.dart';
import '../auth_flow.dart';

/// Brand splash. Holds for a fixed minimum so the logo does not flash, and
/// decides where to go while it waits: the welcome carousel (first run only),
/// the last dashboard for a returning signed-in user, or sign-in.
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
    // Read the flags and hold the splash at the same time, so a slow keystore
    // never adds to the wait a member sees.
    final results = await Future.wait<Object?>([
      AppPrefs.hasSeenOnboarding(),
      AppPrefs.lastRole(),
      Future<void>.delayed(_minimumHold),
      // Rehydrate the persisted JWT + member id into ApiService.
      ApiService.restoreSession(),
    ]);
    if (!mounted) return;

    final seenOnboarding = results[0] == true;
    final lastRole = results[1] as String?;
    final nav = Navigator.of(context);

    if (!seenOnboarding) {
      nav.pushReplacementNamed(AppRoutes.onboarding);
      return;
    }

    // Returning user with a live session: straight to their dashboard. Both
    // roles need an unexpired JWT — every API call carries it.
    final isAdmin = lastRole == 'admin';
    final hasLiveSession = !AuthFlow.isJwtExpired(ApiService.authToken) &&
        (isAdmin || ApiService.sessionMemberId != null);
    if (lastRole != null && hasLiveSession) {
      nav.pushReplacementNamed(
        isAdmin ? AppRoutes.adminDashboard : AppRoutes.memberDashboard,
      );
      return;
    }

    // Firebase still remembers the verified phone (session JWT expired, or
    // approval came through): re-resolve with a fresh Firebase ID token.
    final phone = PhoneAuthService.instance.currentPhone;
    if (phone != null) {
      final result = await AuthFlow.resolve(phone);
      if (!mounted) return;
      if (result.status != ResolveStatus.networkError) {
        AuthFlow.route(nav, result);
        return;
      }
      // Offline: a member with a stored session can still open the app; the
      // first call that reaches the server re-authenticates on 401.
      if (lastRole == 'member' && ApiService.sessionMemberId != null) {
        nav.pushReplacementNamed(AppRoutes.memberDashboard);
        return;
      }
    }

    nav.pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppOverlayStyles.fullBleed,
      child: Scaffold(
        backgroundColor: context.colors.primaryDark,
        // SizedBox.expand is load-bearing: Scaffold hands its body loose
        // constraints, and a Column sizes its cross axis to the widest child,
        // so without it the gradient would only be as wide as the tagline.
        body: SizedBox.expand(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: context.colors.heroGradient),
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
                        style: context.text.display.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        context.l10n.splashTagline,
                        textAlign: TextAlign.center,
                        style: context.text.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
                        ),
                      ),
                      const Spacer(flex: 4),
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          semanticsLabel: context.l10n.commonLoading,
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(
                            Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        context.l10n.splashFooter,
                        textAlign: TextAlign.center,
                        style: context.text.small.copyWith(
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
        borderRadius: BorderRadius.circular(AppRadius.brandMark),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: const Icon(Icons.mosque_rounded, size: 50, color: Colors.white),
    );
  }
}

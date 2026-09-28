import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/storage/app_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_settings_sheet.dart';
import '../../../l10n/l10n.dart';

/// First-run welcome. Shown once: both Skip and Get Started record the flag
/// before leaving, so a returning member goes straight from splash to sign in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _slideCount = 3;

  List<_WelcomeSlide> _slides(AppLocalizations l10n) => [
        _WelcomeSlide(
          icon: Icons.account_balance_wallet_outlined,
          title: l10n.onboardingSlide1Title,
          description: l10n.onboardingSlide1Body,
          highlights: [
            l10n.onboardingSlide1Point1,
            l10n.onboardingSlide1Point2
          ],
        ),
        _WelcomeSlide(
          icon: Icons.volunteer_activism_outlined,
          title: l10n.onboardingSlide2Title,
          description: l10n.onboardingSlide2Body,
          highlights: [
            l10n.onboardingSlide2Point1,
            l10n.onboardingSlide2Point2
          ],
        ),
        _WelcomeSlide(
          icon: Icons.verified_outlined,
          title: l10n.onboardingSlide3Title,
          description: l10n.onboardingSlide3Body,
          highlights: [
            l10n.onboardingSlide3Point1,
            l10n.onboardingSlide3Point2
          ],
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppPrefs.setOnboardingSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _next() {
    if (_currentPage == _slideCount - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slideCount - 1;
    final slides = _slides(context.l10n);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.colors.gradientHeaderOverlay,
      child: Scaffold(
        backgroundColor: context.colors.background,
        body: Column(
          children: [
            _buildHeader(isLast),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) => _buildSlide(slides[i]),
              ),
            ),
            _buildFooter(isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLast) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(gradient: context.colors.heroGradient),
      padding: EdgeInsets.only(
        left: AppSpacing.screenH,
        right: AppSpacing.sm,
        top: MediaQuery.paddingOf(context).top + AppSpacing.ms,
        bottom: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.sm + 2),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child:
                const Icon(Icons.mosque_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Text(
              'MahalFlow',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.sectionTitle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const AppLanguageButton(),
          // Hidden on the last slide, where "Get Started" does the same job.
          // The slot keeps its size so the header does not jump.
          Visibility(
            visible: !isLast,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            // Capped so a long translation ("ഒഴിവാക്കുക") never squeezes the
            // brand title to nothing at 360dp / large text.
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: TextButton(
                onPressed: _finish,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                ),
                child: Text(
                  context.l10n.commonSkip,
                  semanticsLabel: context.l10n.onboardingSkipSemantics,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.buttonMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_WelcomeSlide slide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 128,
              height: 128,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.illustration),
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(slide.icon, size: 56, color: context.colors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            slide.title,
            style: context.text.display.copyWith(fontSize: 26),
          ),
          const SizedBox(height: AppSpacing.ms),
          Text(
            slide.description,
            style: context.text.body.copyWith(
              color: context.colors.textSecondary,
              height: 22 / 14,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final highlight in slide.highlights)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.ms),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.colors.successBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: context.colors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.ms),
                  Expanded(
                    child: Text(
                      highlight,
                      style: context.text.body.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isLast) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.md,
            AppSpacing.screenH,
            AppSpacing.ms,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: context.l10n
                    .onboardingPageOf(_currentPage + 1, _slideCount),
                liveRegion: true,
                excludeSemantics: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slideCount, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 26 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? context.colors.primary
                            : context.colors.border,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: isLast
                    ? context.l10n.onboardingGetStarted
                    : context.l10n.commonNext,
                icon: Icons.arrow_forward_rounded,
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeSlide {
  final IconData icon;
  final String title;
  final String description;
  final List<String> highlights;

  const _WelcomeSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.highlights,
  });
}

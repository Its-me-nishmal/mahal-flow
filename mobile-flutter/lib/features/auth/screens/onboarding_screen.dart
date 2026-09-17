import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/storage/app_prefs.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';

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

  static const List<_WelcomeSlide> _slides = [
    _WelcomeSlide(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Know exactly what you owe',
      description:
          'Your monthly dues, pending months and advance credit — all on one '
          'screen, updated the moment a payment clears.',
      highlights: [
        'Outstanding balance at a glance',
        'Month-by-month breakdown',
      ],
    ),
    _WelcomeSlide(
      icon: Icons.volunteer_activism_outlined,
      title: 'Give in a few taps',
      description:
          'Pay dues or contribute to the Mahal fund with UPI, cards or net '
          'banking. AutoPay can handle the monthly dues for you.',
      highlights: [
        'UPI, card and net banking',
        'Optional AutoPay mandate',
      ],
    ),
    _WelcomeSlide(
      icon: Icons.verified_outlined,
      title: 'Every payment has a receipt',
      description:
          'Each transaction produces a receipt you can verify, download and '
          'share — so the committee and you always see the same record.',
      highlights: [
        'Cryptographically verifiable',
        'Download as PDF anytime',
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
    if (_currentPage == _slides.length - 1) {
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
    final isLast = _currentPage == _slides.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) => _buildSlide(_slides[i]),
              ),
            ),
            _buildFooter(isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppGradients.hero),
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
            child: const Icon(Icons.mosque_rounded,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.ms),
          Expanded(
            child: Text(
              'MahalFlow',
              style: AppTextStyles.pageTitle.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
          TextButton(
            onPressed: _finish,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 44),
            ),
            child: Text(
              'Skip',
              style: AppTextStyles.button.copyWith(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.86),
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
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(slide.icon, size: 56, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            slide.title,
            style: AppTextStyles.display.copyWith(fontSize: 26),
          ),
          const SizedBox(height: AppSpacing.ms),
          Text(
            slide.description,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
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
                    decoration: const BoxDecoration(
                      color: AppColors.successBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.ms),
                  Expanded(
                    child: Text(
                      highlight,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 26 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                label: isLast ? 'Get Started' : 'Next',
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

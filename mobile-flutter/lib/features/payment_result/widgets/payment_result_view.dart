import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';

/// Shared layout for the three payment outcomes. One widget means success,
/// failure and pending cannot drift apart visually — only the colour, the
/// wording and the primary action change.
class PaymentResultView extends StatelessWidget {
  final String headline;
  final String message;
  final String amount;
  final IconData icon;
  final Color color;
  final Color background;
  final String statusLabel;
  final String primaryLabel;
  final IconData? primaryIcon;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final List<Widget> details;

  const PaymentResultView({
    super.key,
    required this.headline,
    required this.message,
    required this.amount,
    required this.icon,
    required this.color,
    required this.background,
    required this.statusLabel,
    required this.primaryLabel,
    this.primaryIcon,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.details = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppOverlayStyles.gradientHeader,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppGradients.hero),
              padding: EdgeInsets.only(
                left: AppSpacing.screenH,
                right: AppSpacing.screenH,
                top: MediaQuery.paddingOf(context).top + AppSpacing.xl,
                bottom: AppSpacing.xl + AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.26),
                        width: 2,
                      ),
                    ),
                    child: Icon(icon, size: 42, color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    header: true,
                    child: Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.display.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 20 / 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  0,
                  AppSpacing.screenH,
                  AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    Container(
                      transform: Matrix4.translationValues(0, -AppSpacing.lg, 0),
                      child: AppCard.floating(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'AMOUNT',
                                    style: AppTextStyles.label,
                                  ),
                                ),
                                StatusPill(
                                  label: statusLabel,
                                  foreground: color,
                                  background: background,
                                  icon: icon,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.ms),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                amount,
                                style: AppTextStyles.amount.copyWith(
                                  color: color,
                                ),
                              ),
                            ),
                            if (details.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.md),
                              const Divider(height: 1, color: AppColors.border),
                              ...details,
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.ms,
                    AppSpacing.screenH,
                    AppSpacing.ms,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppPrimaryButton(
                        label: primaryLabel,
                        icon: primaryIcon,
                        onPressed: onPrimary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppSecondaryButton(
                        label: secondaryLabel,
                        onPressed: onSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

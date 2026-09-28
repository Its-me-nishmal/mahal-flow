import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../settings/app_settings.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'app_bottom_sheet.dart';
import 'app_page_scaffold.dart';

/// Theme (System / Light / Dark) and language (System / English / മലയാളം)
/// pickers. Shared by the member Profile screen, the admin drawer and the
/// sign-in screens, so the choice lives in exactly one place:
/// [AppSettings], persisted through AppPrefs.
class AppSettingsSheet {
  AppSettingsSheet._();

  /// Full sheet: appearance + language.
  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show<void>(
      context: context,
      title: context.l10n.settingsTitle,
      icon: Icons.tune_rounded,
      builder: (context, _) => const _SettingsBody(showTheme: true),
    );
  }

  /// Language only — the small toggle on the sign-in / welcome screens.
  static Future<void> showLanguage(BuildContext context) {
    return AppBottomSheet.show<void>(
      context: context,
      title: context.l10n.settingsLanguage,
      icon: Icons.translate_rounded,
      builder: (context, _) => const _SettingsBody(showTheme: false),
    );
  }

  static String themeLabel(BuildContext context, ThemeMode mode) =>
      switch (mode) {
        ThemeMode.light => context.l10n.themeLight,
        ThemeMode.dark => context.l10n.themeDark,
        ThemeMode.system => context.l10n.themeSystem,
      };

  static String languageLabel(BuildContext context, AppLanguage language) =>
      switch (language) {
        AppLanguage.english => context.l10n.languageEnglish,
        AppLanguage.malayalam => context.l10n.languageMalayalam,
        AppLanguage.system => context.l10n.languageSystem,
      };

  /// "Dark · മലയാളം" — the current choices, for a settings row subtitle.
  static String summary(BuildContext context) {
    final s = AppSettings.instance;
    return '${themeLabel(context, s.themeMode)} · '
        '${languageLabel(context, s.language)}';
  }
}

class _SettingsBody extends StatelessWidget {
  final bool showTheme;

  const _SettingsBody({required this.showTheme});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final l10n = context.l10n;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTheme) ...[
              _GroupLabel(l10n.settingsTheme),
              for (final (mode, icon) in const [
                (ThemeMode.system, Icons.brightness_auto_outlined),
                (ThemeMode.light, Icons.light_mode_outlined),
                (ThemeMode.dark, Icons.dark_mode_outlined),
              ])
                _ChoiceTile(
                  icon: icon,
                  label: AppSettingsSheet.themeLabel(context, mode),
                  selected: settings.themeMode == mode,
                  onTap: () => settings.setThemeMode(mode),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
            _GroupLabel(l10n.settingsLanguage),
            for (final language in AppLanguage.values)
              _ChoiceTile(
                icon: language == AppLanguage.system
                    ? Icons.phone_android_outlined
                    : Icons.translate_rounded,
                label: AppSettingsSheet.languageLabel(context, language),
                selected: settings.language == language,
                onTap: () => settings.setLanguage(language),
              ),
          ],
        );
      },
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(text.toUpperCase(), style: context.text.label),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        selected: selected,
        inMutuallyExclusiveGroup: true,
        button: true,
        child: Material(
          color: selected ? c.primaryLight : c.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.button),
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSizes.minTouch),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: selected ? c.primary : c.border),
              ),
              child: Row(
                children: [
                  Icon(icon,
                      size: 20, color: selected ? c.primary : c.textSecondary),
                  const SizedBox(width: AppSpacing.ms),
                  Expanded(
                    child: Text(
                      label,
                      style: context.text.body.copyWith(
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? c.primary : c.textPrimary,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded, size: 20, color: c.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact language toggle for the gradient header of the sign-in and
/// welcome screens: a translucent pill reading "EN" / "മല".
class AppLanguageButton extends StatelessWidget {
  const AppLanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    final short = code == 'ml' ? 'മല' : 'EN';
    return AppHeaderPillButton(
      icon: Icons.translate_rounded,
      label: short,
      tooltip: context.l10n.settingsLanguageTooltip,
      onTap: () => AppSettingsSheet.showLanguage(context),
    );
  }
}

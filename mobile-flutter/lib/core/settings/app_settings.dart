import 'package:flutter/material.dart';

import '../storage/app_prefs.dart';

/// Language choice. [system] follows the device language (Malayalam when the
/// phone is set to Malayalam, otherwise English).
enum AppLanguage {
  system(null),
  english(Locale('en')),
  malayalam(Locale('ml'));

  const AppLanguage(this.locale);

  /// The locale to force on MaterialApp; null means follow the device.
  final Locale? locale;

  static AppLanguage fromCode(String? code) => switch (code) {
        'en' => AppLanguage.english,
        'ml' => AppLanguage.malayalam,
        _ => AppLanguage.system,
      };

  String get code => locale?.languageCode ?? 'system';
}

/// User-level display settings (theme mode + language), persisted in
/// [AppPrefs] and listened to by the MaterialApp shell. Changing either one
/// rebuilds the whole app in place — no restart, no lost navigation state.
class AppSettings extends ChangeNotifier {
  AppSettings._();

  static final AppSettings instance = AppSettings._();

  ThemeMode _themeMode = ThemeMode.system;
  AppLanguage _language = AppLanguage.system;

  ThemeMode get themeMode => _themeMode;
  AppLanguage get language => _language;
  Locale? get locale => _language.locale;

  /// Reads the saved choices. Called once before runApp; failures keep the
  /// system defaults.
  Future<void> load() async {
    _themeMode = _themeFromCode(await AppPrefs.themeMode());
    _language = AppLanguage.fromCode(await AppPrefs.languageCode());
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await AppPrefs.setThemeMode(mode.name);
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();
    await AppPrefs.setLanguageCode(language.code);
  }

  static ThemeMode _themeFromCode(String? code) => switch (code) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  /// Test hook: reset to defaults without touching storage.
  @visibleForTesting
  void debugReset({
    ThemeMode themeMode = ThemeMode.system,
    AppLanguage language = AppLanguage.system,
  }) {
    _themeMode = themeMode;
    _language = language;
    notifyListeners();
  }
}

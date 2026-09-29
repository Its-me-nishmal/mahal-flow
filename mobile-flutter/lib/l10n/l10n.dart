import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// `context.l10n.someKey` — the app's strings for the ambient locale.
///
/// Falls back to [L10n.current] when no [AppLocalizations] delegate is
/// installed (bare MaterialApp in widget tests), so widgets never crash on a
/// missing delegate.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this) ?? L10n.current;
}

/// Strings for code that has no BuildContext: formatters ([AppDate], [Inr]),
/// [ApiException.userMessage], notification text. Updated by the app shell
/// whenever the resolved locale changes; English until then.
class L10n {
  L10n._();

  static AppLocalizations _current = lookupAppLocalizations(const Locale('en'));

  static AppLocalizations get current => _current;

  /// Locale for intl formatters: "ml", or "en_US" for English — the one
  /// locale intl can format without loading date symbols first, which keeps
  /// plain unit tests working.
  static String get localeName =>
      _current.localeName == 'ml' ? 'ml' : 'en_US';

  static void setLocale(Locale locale) {
    if (!AppLocalizations.delegate.isSupported(locale)) {
      locale = const Locale('en');
    }
    if (locale.languageCode == _current.localeName &&
        Intl.defaultLocale == localeName) {
      return;
    }
    _current = lookupAppLocalizations(locale);
    // DateFormat without an explicit locale follows the app language (month
    // names in Malayalam, etc.).
    Intl.defaultLocale = localeName;
  }

  /// Runs [body] with the context-free strings and intl formatters in
  /// English, then restores the app language. For output that must stay
  /// English whatever the UI language — the receipt PDF's built-in Helvetica
  /// font has no Malayalam glyphs. Synchronous, so no frame sees the switch.
  static T inEnglish<T>(T Function() body) {
    final saved = Locale(_current.localeName);
    setLocale(const Locale('en'));
    try {
      return body();
    } finally {
      setLocale(saved);
    }
  }

  static const List<Locale> supportedLocales =
      AppLocalizations.supportedLocales;
}

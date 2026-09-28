import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Brand colours that read the same in light and dark mode. They only ever
/// sit behind white copy (the gradient header, the splash, the brand mark),
/// so they never need a dark variant.
class AppBrand {
  AppBrand._();

  static const Color teal = Color(0xFF146C5B);
  static const Color tealDark = Color(0xFF0D4F43);
  static const Color tealBright = Color(0xFF17806B);

  /// Copy and icons on the gradient header / brand surfaces.
  static const Color onBrand = Colors.white;
}

/// The app's colour tokens, resolved from the ambient [Theme] with
/// `context.colors`. Every surface, text, border and status colour has a
/// light and a dark value; widgets never hardcode a light-only colour.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  /// Accent for text, icons, borders and filled buttons.
  final Color primary;

  /// Text / icons drawn on a solid [primary] (or any solid status) fill.
  final Color onPrimary;

  /// Deep brand teal; used on the hero (badge rings, active hero chips).
  final Color primaryDark;
  final Color primaryBright;

  /// Tinted background for accent chips / selected rows.
  final Color primaryLight;

  final Color background;
  final Color surface;

  /// Raised surfaces: bottom sheets, dialogs, menus.
  final Color surfaceRaised;

  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;

  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color error;
  final Color errorBg;
  final Color info;
  final Color infoBg;

  /// Neutral surface for non-status icon chips and badges.
  final Color neutralBg;

  final Color snackBackground;
  final Color snackText;

  /// Bright band of the loading shimmer.
  final Color shimmerHighlight;

  final LinearGradient heroGradient;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> floatingShadow;
  final List<BoxShadow> sheetShadow;

  final Brightness brightness;

  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.onPrimary,
    required this.primaryDark,
    required this.primaryBright,
    required this.primaryLight,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.error,
    required this.errorBg,
    required this.info,
    required this.infoBg,
    required this.neutralBg,
    required this.snackBackground,
    required this.snackText,
    required this.shimmerHighlight,
    required this.heroGradient,
    required this.cardShadow,
    required this.floatingShadow,
    required this.sheetShadow,
  });

  bool get isDark => brightness == Brightness.dark;

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    primary: AppBrand.teal,
    onPrimary: Colors.white,
    primaryDark: AppBrand.tealDark,
    primaryBright: AppBrand.tealBright,
    primaryLight: Color(0xFFE8F4F1),
    background: Color(0xFFF7F9F8),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF17201D),
    textSecondary: Color(0xFF5E6864),
    textMuted: Color(0xFF8A9390),
    border: Color(0xFFE3E8E6),
    success: Color(0xFF16834B),
    successBg: Color(0xFFEAF7EF),
    warning: Color(0xFFB77900),
    warningBg: Color(0xFFFFF5DC),
    error: Color(0xFFC93B3B),
    errorBg: Color(0xFFFDECEC),
    info: Color(0xFF3478B8),
    infoBg: Color(0xFFEAF3FB),
    neutralBg: Color(0xFFE6E9E6),
    snackBackground: Color(0xFF17201D),
    snackText: Colors.white,
    shimmerHighlight: Color(0xCCFFFFFF),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppBrand.tealBright, AppBrand.teal, AppBrand.tealDark],
      stops: [0.0, 0.45, 1.0],
    ),
    cardShadow: [
      BoxShadow(
        color: Color.fromRGBO(23, 32, 29, 0.03),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
    floatingShadow: [
      BoxShadow(
        color: Color.fromRGBO(13, 79, 67, 0.10),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
      BoxShadow(
        color: Color.fromRGBO(23, 32, 29, 0.04),
        blurRadius: 4,
        offset: Offset(0, 1),
      ),
    ],
    sheetShadow: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.15),
        blurRadius: 20,
        offset: Offset(0, -4),
      ),
    ],
  );

  /// Dark palette. Every text/background pair used by the app clears 4.5:1
  /// (textMuted on surfaceRaised is the tightest at ~5:1; status colours on
  /// their tinted backgrounds are 5.6–7:1; onPrimary on primary ~7:1).
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF4CC2A4),
    onPrimary: Color(0xFF06201A),
    primaryDark: AppBrand.tealDark,
    primaryBright: AppBrand.tealBright,
    primaryLight: Color(0xFF183B33),
    background: Color(0xFF0E1412),
    surface: Color(0xFF171F1C),
    surfaceRaised: Color(0xFF1D2622),
    textPrimary: Color(0xFFE6EDEA),
    textSecondary: Color(0xFFA8B3AF),
    textMuted: Color(0xFF8E9995),
    border: Color(0xFF2B3531),
    success: Color(0xFF57C98A),
    successBg: Color(0xFF16301F),
    warning: Color(0xFFE3B254),
    warningBg: Color(0xFF372B12),
    error: Color(0xFFF27A7A),
    errorBg: Color(0xFF3A1C1C),
    info: Color(0xFF74AEE6),
    infoBg: Color(0xFF152838),
    neutralBg: Color(0xFF28312E),
    snackBackground: Color(0xFFE6EDEA),
    snackText: Color(0xFF17201D),
    shimmerHighlight: Color(0x33FFFFFF),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF136A58), Color(0xFF0F5A4B), Color(0xFF0A4037)],
      stops: [0.0, 0.45, 1.0],
    ),
    cardShadow: [],
    floatingShadow: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.35),
        blurRadius: 24,
        offset: Offset(0, 8),
      ),
    ],
    sheetShadow: [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.5),
        blurRadius: 20,
        offset: Offset(0, -4),
      ),
    ],
  );

  /// System bars for screens with a gradient header over the page body:
  /// light status-bar icons over the header, a page-coloured navigation bar
  /// with icons that contrast with it.
  SystemUiOverlayStyle get gradientHeaderOverlay => SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: background,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      primaryDark: c(primaryDark, other.primaryDark),
      primaryBright: c(primaryBright, other.primaryBright),
      primaryLight: c(primaryLight, other.primaryLight),
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      border: c(border, other.border),
      success: c(success, other.success),
      successBg: c(successBg, other.successBg),
      warning: c(warning, other.warning),
      warningBg: c(warningBg, other.warningBg),
      error: c(error, other.error),
      errorBg: c(errorBg, other.errorBg),
      info: c(info, other.info),
      infoBg: c(infoBg, other.infoBg),
      neutralBg: c(neutralBg, other.neutralBg),
      snackBackground: c(snackBackground, other.snackBackground),
      snackText: c(snackText, other.snackText),
      shimmerHighlight: c(shimmerHighlight, other.shimmerHighlight),
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
      floatingShadow:
          BoxShadow.lerpList(floatingShadow, other.floatingShadow, t)!,
      sheetShadow: BoxShadow.lerpList(sheetShadow, other.sheetShadow, t)!,
    );
  }
}

/// Type scale (docs/design.md section 5), coloured for one [AppPalette].
/// Resolved with `context.text`; the theme's textTheme is built from the same
/// styles so Material widgets and custom text agree.
///
/// Every style carries a Noto Sans Malayalam fallback: Inter has no Malayalam
/// glyphs. The Malayalam files are bundled under assets/google_fonts so they
/// work offline.
class AppTypography {
  final AppPalette palette;

  AppTypography._(this.palette);

  static final AppTypography light = AppTypography._(AppPalette.light);
  static final AppTypography dark = AppTypography._(AppPalette.dark);

  static AppTypography of(AppPalette palette) =>
      palette.isDark ? dark : light;

  static TextStyle _inter({
    required double fontSize,
    required double height,
    required FontWeight fontWeight,
    double? letterSpacing,
    Color? color,
  }) {
    final base = GoogleFonts.inter(
      fontSize: fontSize,
      height: height,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );
    return base.copyWith(fontFamilyFallback: malayalamFallback(fontWeight));
  }

  /// Font family fallback that renders Malayalam at [weight].
  static List<String> malayalamFallback(FontWeight weight) {
    final family =
        GoogleFonts.notoSansMalayalam(fontWeight: weight).fontFamily;
    return [if (family != null) family];
  }

  late final TextStyle display = _inter(
    fontSize: 30,
    height: 36 / 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.7,
    color: palette.textPrimary,
  );

  late final TextStyle pageTitle = _inter(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: palette.textPrimary,
  );

  late final TextStyle amount = _inter(
    fontSize: 34,
    height: 40 / 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    color: palette.textPrimary,
  );

  late final TextStyle sectionTitle = _inter(
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w600,
    color: palette.textPrimary,
  );

  late final TextStyle cardTitle = _inter(
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
    color: palette.textPrimary,
  );

  late final TextStyle body = _inter(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: palette.textPrimary,
  );

  late final TextStyle small = _inter(
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w400,
    color: palette.textSecondary,
  );

  /// 15 / w600 — list-row and card titles one step below [cardTitle].
  late final TextStyle listTitle = _inter(
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
    color: palette.textPrimary,
  );

  /// 21 / w700 — dashboard stat values.
  late final TextStyle statValue = _inter(
    fontSize: 21,
    height: 28 / 21,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: palette.textPrimary,
  );

  /// 11.5 — helper/error text under fields, tile captions.
  late final TextStyle caption = _inter(
    fontSize: 11.5,
    height: 16 / 11.5,
    fontWeight: FontWeight.w400,
    color: palette.textSecondary,
  );

  late final TextStyle label = _inter(
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    color: palette.textSecondary,
  );

  late final TextStyle button = _inter(
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
  );

  /// 14 — secondary / outlined / text buttons.
  late final TextStyle buttonMedium = button.copyWith(fontSize: 14);

  /// 13 — compact text actions (section header "See all", filter chips).
  late final TextStyle buttonSmall = button.copyWith(fontSize: 13);
}

/// `context.colors` / `context.text` — the palette and type scale of the
/// ambient theme. Falls back to the light palette when no [AppTheme] is
/// installed (bare MaterialApp in tests).
extension AppThemeContext on BuildContext {
  AppPalette get colors =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  AppTypography get text => AppTypography.of(colors);

  bool get isDark => colors.isDark;
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _build(AppPalette.light);
  static ThemeData get darkTheme => _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final t = AppTypography.of(p);
    final isDark = p.isDark;
    final base = isDark
        ? ThemeData(brightness: Brightness.dark, useMaterial3: true)
        : ThemeData(brightness: Brightness.light, useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    final scheme = (isDark ? const ColorScheme.dark() : const ColorScheme.light())
        .copyWith(
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primaryLight,
      onPrimaryContainer: p.primary,
      secondary: p.primary,
      onSecondary: p.onPrimary,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surfaceRaised,
      surfaceContainerHigh: p.surfaceRaised,
      surfaceContainerHighest: p.surfaceRaised,
      outline: p.border,
      outlineVariant: p.border,
      error: p.error,
      onError: p.onPrimary,
      errorContainer: p.errorBg,
      onErrorContainer: p.error,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      colorScheme: scheme,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,

      // Every screen paints its own gradient header, so the platform
      // page transition is the only motion left to set.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // Built from AppTypography so Material widgets (dialogs, list tiles,
      // inputs) use the same scale as custom text. merge() keeps each base
      // entry's `inherit: false`, which Material needs to lerp styles.
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.merge(t.display),
        headlineSmall: textTheme.headlineSmall?.merge(t.pageTitle),
        titleLarge: textTheme.titleLarge?.merge(t.pageTitle),
        titleMedium: textTheme.titleMedium?.merge(t.sectionTitle),
        titleSmall: textTheme.titleSmall?.merge(t.cardTitle),
        bodyLarge: textTheme.bodyLarge
            ?.merge(t.body.copyWith(fontSize: 16, height: 24 / 16)),
        bodyMedium: textTheme.bodyMedium?.merge(t.body),
        bodySmall: textTheme.bodySmall?.merge(t.small),
        labelSmall: textTheme.labelSmall?.merge(t.label),
      ),

      // No `textStyle` on either button theme. A GoogleFonts style merged
      // into the theme's labelLarge comes out with inherit: false, and Material
      // cannot lerp that against the default style while a button animates —
      // it throws "Failed to interpolate TextStyles with different inherit
      // values". Every button in this app labels itself with an explicit
      // AppTypography.button anyway.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: p.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),

      iconTheme: IconThemeData(color: p.textSecondary),

      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 1,
        space: 1,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: p.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: t.sectionTitle,
        contentTextStyle: t.body.copyWith(color: p.textSecondary),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: p.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        textStyle: t.body,
      ),

      drawerTheme: DrawerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(p.onPrimary),
        side: BorderSide(color: p.textMuted, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.onPrimary
              : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.primary
              : p.neutralBg,
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.primary
              : p.textMuted,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.border,
      ),

      // Snackbars carry most of this app's confirmations, so they get the
      // same rounded, floating treatment as the cards they sit above.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.snackBackground,
        actionTextColor: isDark ? AppBrand.teal : const Color(0xFF7FD9C2),
        contentTextStyle: t.body.copyWith(
          fontWeight: FontWeight.w500,
          color: p.snackText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        insetPadding: const EdgeInsets.all(AppSpacing.md),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surfaceRaised,
        surfaceTintColor: Colors.transparent,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.primary,
        selectionColor: p.primary.withValues(alpha: 0.3),
        selectionHandleColor: p.primary,
      ),
    );
  }
}

/// A semantic colour role. Lets non-widget code (formatters, status maps)
/// pick a colour without a BuildContext; widgets resolve it with
/// `context.colors.fg(tone)` / `.bg(tone)`.
enum AppTone { primary, success, warning, error, info, neutral }

extension AppPaletteTones on AppPalette {
  Color fg(AppTone tone) => switch (tone) {
        AppTone.primary => primary,
        AppTone.success => success,
        AppTone.warning => warning,
        AppTone.error => error,
        AppTone.info => info,
        AppTone.neutral => textSecondary,
      };

  Color bg(AppTone tone) => switch (tone) {
        AppTone.primary => primaryLight,
        AppTone.success => successBg,
        AppTone.warning => warningBg,
        AppTone.error => errorBg,
        AppTone.info => infoBg,
        AppTone.neutral => neutralBg,
      };
}

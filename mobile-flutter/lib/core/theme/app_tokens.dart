import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

/// Spacing scale (docs/design.md section 6 — 8px grid).
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double ms = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double screenH = 16;
}

/// Corner radii (docs/design.md section 7).
class AppRadius {
  AppRadius._();
  static const double sm = 8;
  static const double button = 12;
  static const double card = 16;
  static const double hero = 20;
  static const double pill = 999;
}

/// Elevation (docs/design.md section 8 — border first, shadow sparingly).
class AppShadows {
  AppShadows._();

  /// Hairline lift for standard cards.
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color.fromRGBO(23, 32, 29, 0.03),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Stronger lift for the balance card that floats over the hero.
  static const List<BoxShadow> floating = [
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
  ];
}

/// Brand gradient for the member hero header.
class AppGradients {
  AppGradients._();

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF17806B), AppColors.primary, AppColors.primaryDark],
    stops: [0.0, 0.45, 1.0],
  );
}

/// System bar styling. [SystemUiOverlayStyle.light] is deliberately not used
/// anywhere: alongside the light status-bar icons it wants, it also forces an
/// opaque black navigation bar, which paints a black strip across the bottom
/// of every screen the app draws edge to edge.
class AppOverlayStyles {
  AppOverlayStyles._();

  /// Screens whose gradient runs the full height (the splash). Both bars are
  /// transparent so the gradient bleeds under them.
  static const SystemUiOverlayStyle fullBleed = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );

  /// Screens with a gradient header over a light body: light icons over the
  /// header, dark icons on a background-coloured navigation bar so they stay
  /// legible against the page underneath.
  static const SystemUiOverlayStyle gradientHeader = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
}

/// Opt-in type scale (docs/design.md section 5). Screens adopt this
/// incrementally; [AppTheme.lightTheme] is deliberately left untouched so
/// existing screens keep rendering exactly as they do today.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.inter(
        fontSize: 30,
        height: 36 / 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.7,
        color: AppColors.textPrimary,
      );

  static TextStyle get pageTitle => GoogleFonts.inter(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: AppColors.textPrimary,
      );

  static TextStyle get amount => GoogleFonts.inter(
        fontSize: 34,
        height: 40 / 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
      );

  static TextStyle get sectionTitle => GoogleFonts.inter(
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get cardTitle => GoogleFonts.inter(
        fontSize: 16,
        height: 22 / 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get small => GoogleFonts.inter(
        fontSize: 12,
        height: 18 / 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 11,
        height: 16 / 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.textSecondary,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 15,
        height: 20 / 15,
        fontWeight: FontWeight.w600,
      );
}

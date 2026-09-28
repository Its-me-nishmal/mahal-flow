import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  static const double xs = 5;
  static const double sm = 8;
  static const double md = 10;
  static const double button = 12;
  static const double card = 16;
  static const double hero = 20;

  /// Top corners of modal bottom sheets.
  static const double sheet = 24;

  /// The rounded-square brand mark on the splash.
  static const double brandMark = 30;

  /// Large illustration tiles (onboarding).
  static const double illustration = 36;
  static const double pill = 999;
}

/// Fixed component sizes.
class AppSizes {
  AppSizes._();

  /// Minimum touch target (Material / WCAG 2.5.5).
  static const double minTouch = 48;

  /// Visual diameter of the translucent header icon buttons; the hit area is
  /// always [minTouch].
  static const double headerIcon = 42;

  static const double searchBar = 48;
  static const double buttonHeight = 52;
  static const double buttonHeightCompact = 46;
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

  // Screens with a gradient header over the page body use
  // `context.colors.gradientHeaderOverlay`, which follows light/dark mode.
}


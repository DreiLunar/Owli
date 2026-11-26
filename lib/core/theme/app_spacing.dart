import 'package:material_ui/material_ui.dart';

/// Shared spacing and radius tokens so layouts stay consistent while the UI
/// is still a neutral wireframe-level shell.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Standard horizontal page padding (wireframes use ~16dp gutters).
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: lg,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  // Corner radii.
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusPill = 999;
}

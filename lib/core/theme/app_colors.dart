import 'package:material_ui/material_ui.dart';

/// Neutral placeholder palette for the MVP.
///
/// Nothing here is final styling: every screen must read colours from these
/// tokens (or from `Theme.of(context).colorScheme`) so the whole app can be
/// re-skinned later without touching business logic.
class AppColors {
  const AppColors._();

  /// Base seed used to generate the Material 3 colour scheme.
  static const Color seed = Color(0xFF4A6FA5);

  // Neutral surfaces (light).
  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E5EA);

  // Neutral surfaces (dark).
  static const Color darkBackground = Color(0xFF121417);
  static const Color darkSurface = Color(0xFF1B1E23);
  static const Color darkBorder = Color(0xFF2C3138);

  // Text.
  static const Color lightTextPrimary = Color(0xFF1B1E23);
  static const Color lightTextSecondary = Color(0xFF5C636E);
  static const Color darkTextPrimary = Color(0xFFF2F4F7);
  static const Color darkTextSecondary = Color(0xFFA5ADB8);

  // Semantic placeholders (error / success states).
  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB26A00);

  /// Subject colour-tag swatches offered in the "New Subject" dialog.
  /// Wireframe shows four selectable dots; values are neutral for now.
  static const List<Color> subjectTags = <Color>[
    Color(0xFF4A6FA5),
    Color(0xFF5B8C5A),
    Color(0xFFB26A00),
    Color(0xFF7B5EA7),
  ];
}

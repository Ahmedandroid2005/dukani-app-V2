import 'package:flutter/material.dart';

/// Dukani V2 brand palette — a single violet accent on white/near-white
/// neutrals, replacing the old navy+teal system. This is the single source
/// of truth for color across the app; screens should never hardcode a hex
/// value, they should reference [DukaniColors] or the themed [ColorScheme]
/// instead.
///
/// Token names are kept identical to the pre-redesign palette (forest*,
/// gold*, ink*) so every existing screen and widget — which reference these
/// names hundreds of times — repaints with the new system without touching
/// call sites. Both families now resolve to the same violet accent, since
/// the new system uses one accent color, not two.
class DukaniColors {
  DukaniColors._();

  // Brand — single violet accent (was navy `forest*`)
  static const Color forest900 = Color(0xFF120E2E); // deepest ink-violet (dark bg only)
  static const Color forest800 = Color(0xFF1D1640);
  static const Color forest700 = Color(0xFF5B3DF5); // primary accent — buttons, active states
  static const Color forest600 = Color(0xFF4C2FE0); // pressed/hover
  static const Color forest500 = Color(0xFF6D52F7);
  static const Color forest400 = Color(0xFF8873FF);
  static const Color forest100 = Color(0xFFE3DEFC);
  static const Color forest50 = Color(0xFFEFEBFF); // accent tint — icon/badge backgrounds

  // Brand — was a second teal accent (`gold*`); now an alias of the same
  // violet so nothing in the app reads as two-toned.
  static const Color gold700 = Color(0xFF4C2FE0);
  static const Color gold600 = Color(0xFF4C2FE0);
  static const Color gold500 = Color(0xFF5B3DF5);
  static const Color gold400 = Color(0xFF8873FF);
  static const Color gold300 = Color(0xFFB3A4FF);
  static const Color gold100 = Color(0xFFEFEBFF);

  // Neutrals — cool near-black ink on pure white paper
  static const Color ink900 = Color(0xFF17171F);
  static const Color ink700 = Color(0xFF3A3A46);
  static const Color ink500 = Color(0xFF6E6E82);
  static const Color ink300 = Color(0xFF9A9AAC);
  static const Color ink100 = Color(0xFFE7E6F0);
  static const Color paper = Color(0xFFFFFFFF); // pure white background
  static const Color paperDim = Color(0xFFFAFAFC);
  static const Color white = Color(0xFFFFFFFF);

  // Dark mode surfaces (kept functional; the product is designed white-first)
  static const Color darkBg = Color(0xFF0E0C1A);
  static const Color darkSurface = Color(0xFF171426);
  static const Color darkSurfaceAlt = Color(0xFF201B33);
  static const Color darkBorder = Color(0xFF322B4A);

  // Semantic — separate from the brand accent so meaning never blurs
  static const Color success = Color(0xFF1E9A5A);
  static const Color successBg = Color(0xFFE6F6ED);
  static const Color danger = Color(0xFFE5484D);
  static const Color dangerBg = Color(0xFFFDECEC);
  static const Color warning = Color(0xFFC97A17);
  static const Color warningBg = Color(0xFFFBF0DE);
  static const Color info = Color(0xFF2F6FE4);
  static const Color infoBg = Color(0xFFEAF1FD);

  // Chart palette (used across line/bar/pie/area charts for consistency) —
  // a data-viz exception to "one accent": each series still needs to be
  // told apart, so this stays a distinct multi-hue set.
  static const List<Color> chartSeries = [
    forest700,
    Color(0xFF2F6FE4),
    Color(0xFF1E9A5A),
    Color(0xFFC97A17),
    Color(0xFFD1479A),
    Color(0xFFE5484D),
  ];

  // Both gradients are now flat single-color washes — the new system avoids
  // multi-hue gradients, but call sites (home header, a couple of badges)
  // still expect a LinearGradient shape.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forest700, forest700],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forest700, forest700],
  );
}

import 'package:flutter/material.dart';
import 'dukani_colors.dart';

/// Soft, warm elevation shadows — flatter and more diffuse than Material's
/// default so cards read as "premium" rather than "default Android".
class DukaniShadows {
  DukaniShadows._();

  static List<BoxShadow> card({bool dark = false}) => [
        BoxShadow(
          color: dark ? Colors.black.withOpacity(0.35) : DukaniColors.ink900.withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
          spreadRadius: -6,
        ),
        BoxShadow(
          color: dark ? Colors.black.withOpacity(0.25) : DukaniColors.ink900.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> floating({bool dark = false}) => [
        BoxShadow(
          color: dark ? Colors.black.withOpacity(0.5) : DukaniColors.forest900.withOpacity(0.18),
          blurRadius: 32,
          offset: const Offset(0, 16),
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> gold({bool dark = false}) => [
        BoxShadow(
          color: DukaniColors.gold500.withOpacity(0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
      ];
}

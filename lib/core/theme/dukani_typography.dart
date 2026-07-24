import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dukani_colors.dart';

/// Cairo reads as premium in Arabic at both display and body sizes and has
/// the full weight range we need (400/500/600/700/800) without falling back
/// to the system font mid-hierarchy.
class DukaniTypography {
  DukaniTypography._();

  static TextTheme textTheme(Color base) {
    final cairo = GoogleFonts.cairoTextTheme();
    return cairo
        .copyWith(
          displayLarge: cairo.displayLarge?.copyWith(fontSize: 40, fontWeight: FontWeight.w800, height: 1.15, letterSpacing: -0.5),
          displayMedium: cairo.displayMedium?.copyWith(fontSize: 32, fontWeight: FontWeight.w800, height: 1.18),
          headlineLarge: cairo.headlineLarge?.copyWith(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2),
          headlineMedium: cairo.headlineMedium?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25),
          headlineSmall: cairo.headlineSmall?.copyWith(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3),
          titleLarge: cairo.titleLarge?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
          titleMedium: cairo.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
          titleSmall: cairo.titleSmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          bodyLarge: cairo.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
          bodyMedium: cairo.bodyMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
          bodySmall: cairo.bodySmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w400, height: 1.45),
          labelLarge: cairo.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: cairo.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          labelSmall: cairo.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
        )
        .apply(bodyColor: base, displayColor: base, decorationColor: base);
  }

  /// Large tabular figures used for money/stat headlines (invoices, profit
  /// totals) — tabular so digits don't jitter width as values update live.
  static TextStyle statFigure(Color color, {double size = 28}) => GoogleFonts.cairo(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
        height: 1.1,
      );

  static const Color mutedLight = DukaniColors.ink500;
  static const Color mutedDark = DukaniColors.ink300;
}

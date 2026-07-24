import 'package:flutter/material.dart';
import 'dukani_colors.dart';
import 'dukani_spacing.dart';
import 'dukani_typography.dart';

export 'dukani_colors.dart';
export 'dukani_spacing.dart';
export 'dukani_shadows.dart';
export 'dukani_typography.dart';

class DukaniTheme {
  DukaniTheme._();

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: DukaniColors.forest700,
      onPrimary: DukaniColors.white,
      secondary: DukaniColors.gold500,
      onSecondary: DukaniColors.white,
      surface: DukaniColors.white,
      onSurface: DukaniColors.ink900,
      error: DukaniColors.danger,
      onError: DukaniColors.white,
      outline: DukaniColors.ink100,
    );

    return _base(scheme, DukaniColors.paper, false);
  }

  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: DukaniColors.forest400,
      onPrimary: DukaniColors.forest900,
      secondary: DukaniColors.gold400,
      onSecondary: DukaniColors.forest900,
      surface: DukaniColors.darkSurface,
      onSurface: DukaniColors.white,
      error: DukaniColors.danger,
      onError: DukaniColors.white,
      outline: DukaniColors.darkBorder,
    );

    return _base(scheme, DukaniColors.darkBg, true);
  }

  static ThemeData _base(ColorScheme scheme, Color scaffoldBg, bool dark) {
    final textTheme = DukaniTypography.textTheme(scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: textTheme.bodyMedium?.fontFamily,
      textTheme: textTheme,
      // InkSparkle is fragment-shader based; Flutter's web HTML renderer
      // doesn't support shaders and throws on every ripple, which can
      // disrupt gesture handling entirely (observed: a button's onPressed
      // never firing after a shader exception during its own tap-down
      // ripple). Ripple is purely cosmetic tap feedback, so a classic
      // shader-free splash costs nothing and removes the whole failure class.
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DukaniRadii.lg)),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? DukaniColors.darkSurfaceAlt : DukaniColors.paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DukaniRadii.md),
          borderSide: BorderSide(color: dark ? DukaniColors.darkBorder : DukaniColors.ink100, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DukaniRadii.md),
          borderSide: BorderSide(color: dark ? DukaniColors.darkBorder : DukaniColors.ink100, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DukaniRadii.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DukaniRadii.md),
          borderSide: const BorderSide(color: DukaniColors.danger, width: 1.4),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: dark ? DukaniColors.ink300 : DukaniColors.ink500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DukaniRadii.md)),
          textStyle: textTheme.titleMedium,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DukaniRadii.md)),
          textStyle: textTheme.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.titleMedium,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DukaniRadii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DukaniRadii.lg)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? DukaniColors.darkSurfaceAlt : DukaniColors.ink900,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DukaniRadii.sm)),
      ),
    );
  }
}

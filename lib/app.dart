import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/theme/dukani_theme.dart';

class DukaniApp extends StatelessWidget {
  const DukaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'دُكاني',
      debugShowCheckedModeBanner: false,
      theme: DukaniTheme.light(),
      // Locked to the brand's white/clean look regardless of the device's
      // system theme — a merchant flipping their phone to dark mode
      // shouldn't turn the POS into an unrecognizable black screen with
      // no warning.
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: _ResponsiveFrame(child: child ?? const SizedBox()),
        );
      },
    );
  }
}

/// Every screen here was designed at phone proportions (fixed padding,
/// card sizes, grid columns). Left unconstrained, a wide browser/desktop
/// window just stretches that phone layout edge-to-edge — huge empty gaps
/// in cards, a bottom nav bar spanning the whole window. Above a tablet-ish
/// width, this centers the app in a fixed-width column instead, so it
/// reads as a deliberate app on any screen rather than a phone UI someone
/// forgot to constrain.
class _ResponsiveFrame extends StatelessWidget {
  const _ResponsiveFrame({required this.child});
  final Widget child;

  static const _maxAppWidth = 640.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= _maxAppWidth) return child;
        final mq = MediaQuery.of(context);
        return ColoredBox(
          color: DukaniColors.forest900,
          child: Center(
            child: SizedBox(
              width: _maxAppWidth,
              height: constraints.maxHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 40, spreadRadius: -8)],
                ),
                child: ClipRect(
                  // Screens size things off MediaQuery, not the actual render
                  // box, so without this override every width-aware layout
                  // (e.g. the POS grid's column count) still measures the
                  // full physical window and gets crammed into this frame
                  // instead of measuring the frame itself.
                  child: MediaQuery(
                    data: mq.copyWith(size: Size(_maxAppWidth, constraints.maxHeight)),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

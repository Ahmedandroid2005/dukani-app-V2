import 'package:flutter/material.dart';
import '../theme/dukani_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum DukaniButtonSize { large, medium, small }

/// Primary call-to-action button. Handles its own loading spinner state so
/// call sites just flip [loading] instead of swapping child widgets.
class DukaniButton extends StatelessWidget {
  const DukaniButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.size = DukaniButtonSize.large,
    this.expand = true,
    this.gold = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final DukaniButtonSize size;
  final bool expand;
  final bool gold;

  double get _height => switch (size) {
        DukaniButtonSize.large => 56,
        DukaniButtonSize.medium => 48,
        DukaniButtonSize.small => 40,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = gold ? DukaniColors.gold500 : scheme.primary;
    final fg = gold ? Colors.white : scheme.onPrimary;

    final child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: loading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 10)],
                Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: fg)),
              ],
            ),
    );

    final button = SizedBox(
      height: _height,
      width: expand ? double.infinity : null,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          disabledBackgroundColor: bg.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: child,
      ),
    );

    return button;
  }
}

/// Secondary / outline action button.
class DukaniOutlineButton extends StatelessWidget {
  const DukaniOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        // The theme's default minimumSize is Size.fromHeight(56), i.e. an
        // *infinite* minimum width — fine when the outer SizedBox stretches
        // to match, but fatal for a Row's non-flex child when it doesn't:
        // pin a finite minimum width here whenever expand is false.
        style: expand ? null : OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 10)],
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Social sign-in button (Apple / Google) with brand-correct mark + label.
class DukaniSocialButton extends StatelessWidget {
  const DukaniSocialButton({super.key, required this.provider, this.onPressed});

  final DukaniSocialProvider provider;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isApple = provider == DukaniSocialProvider.apple;
    final scheme = Theme.of(context).colorScheme;
    // Not implemented yet (no real Apple/Google Sign-In wired up) — a
    // disabled button still styled with the provider's real brand colors
    // would look tappable when it isn't, so it renders visibly greyed out
    // instead, same as any other not-yet-built action in this app.
    final disabled = onPressed == null;
    final bg = disabled ? scheme.surfaceContainerHighest : (isApple ? (scheme.brightness == Brightness.dark ? Colors.white : Colors.black) : scheme.surface);
    final fg = disabled ? scheme.onSurface.withOpacity(0.4) : (isApple ? (scheme.brightness == Brightness.dark ? Colors.black : Colors.white) : scheme.onSurface);

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          side: BorderSide(color: disabled ? scheme.outline.withOpacity(0.5) : scheme.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isApple ? LucideIcons.apple : LucideIcons.smartphone, color: fg, size: isApple ? 20 : 24),
            const SizedBox(width: 10),
            Text(
              '${isApple ? 'المتابعة عبر Apple' : 'المتابعة عبر Google'}${disabled ? ' (قريبًا)' : ''}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

enum DukaniSocialProvider { apple, google }

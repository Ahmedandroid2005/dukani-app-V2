import 'package:flutter/material.dart';
import '../theme/dukani_theme.dart';

enum DukaniBadgeTone { success, danger, warning, info, neutral, gold }

class DukaniBadge extends StatelessWidget {
  const DukaniBadge({super.key, required this.label, this.tone = DukaniBadgeTone.neutral, this.icon});

  final String label;
  final DukaniBadgeTone tone;
  final IconData? icon;

  (Color, Color) _colors(bool dark) => switch (tone) {
        DukaniBadgeTone.success => (DukaniColors.successBg, DukaniColors.success),
        DukaniBadgeTone.danger => (DukaniColors.dangerBg, DukaniColors.danger),
        DukaniBadgeTone.warning => (DukaniColors.warningBg, DukaniColors.gold700),
        DukaniBadgeTone.info => (DukaniColors.infoBg, DukaniColors.info),
        DukaniBadgeTone.gold => (DukaniColors.gold100, DukaniColors.gold700),
        DukaniBadgeTone.neutral => (dark ? DukaniColors.darkSurfaceAlt : DukaniColors.ink100, dark ? DukaniColors.ink300 : DukaniColors.ink700),
      };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg) = _colors(dark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: fg), const SizedBox(width: 4)],
          Text(
            label,
            // Badges frequently show times/counts (e.g. "7:20 م") — forcing
            // LTR keeps digit-separator sequences from being reordered by
            // the bidi algorithm under the app's ambient RTL directionality.
            textDirection: TextDirection.ltr,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// A small colored dot + label used for alert severity in lists.
class DukaniSeverityDot extends StatelessWidget {
  const DukaniSeverityDot({super.key, required this.tone});
  final DukaniBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      DukaniBadgeTone.success => DukaniColors.success,
      DukaniBadgeTone.danger => DukaniColors.danger,
      DukaniBadgeTone.warning => DukaniColors.gold500,
      DukaniBadgeTone.info => DukaniColors.info,
      _ => DukaniColors.ink300,
    };
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

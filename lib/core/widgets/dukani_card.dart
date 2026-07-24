import 'package:flutter/material.dart';
import '../theme/dukani_theme.dart';
import 'dukani_amount_text.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Base elevated surface used everywhere a card is needed — carries the
/// brand's soft-shadow language so every screen feels consistent.
class DukaniCard extends StatelessWidget {
  const DukaniCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DukaniSpacing.lg),
    this.onTap,
    this.color,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(DukaniRadii.lg);

    final content = Padding(padding: padding, child: child);

    // The fill color and any ink (this card's own tap ripple, or a
    // ListTile/InkWell nested inside `child` — every settings row uses
    // one) must live on the *same* Material so splashes paint above the
    // background instead of being hidden behind an opaque sibling
    // DecoratedBox. Border and shadow stay on a separate, colorless
    // Container wrapping it so they don't clip the ripple.
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: border ?? (dark ? DukaniColors.darkBorder : DukaniColors.ink100)),
        boxShadow: DukaniShadows.card(dark: dark),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          color: color ?? scheme.surface,
          child: onTap == null ? content : InkWell(onTap: onTap, child: content),
        ),
      ),
    );
  }
}

/// A compact KPI tile used on the dashboard grid (e.g. products / customers
/// / inventory counts) — icon, label, big value, optional trend chip.
class DukaniStatTile extends StatelessWidget {
  const DukaniStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.trend,
    this.trendUp,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? trend;
  final bool? trendUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = iconColor ?? scheme.primary;

    return DukaniCard(
      onTap: onTap,
      padding: const EdgeInsets.all(DukaniSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(DukaniRadii.sm)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: DukaniSpacing.md),
          DukaniAmountText(value, style: DukaniTypography.statFigure(scheme.onSurface, size: 20)),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(label, style: textTheme.bodySmall?.copyWith(color: DukaniColors.ink500), overflow: TextOverflow.ellipsis),
              ),
              if (trend != null) ...[
                Icon(
                  trendUp == false ? LucideIcons.arrowDown : LucideIcons.arrowUp,
                  size: 12,
                  color: trendUp == false ? DukaniColors.danger : DukaniColors.success,
                ),
                Flexible(
                  child: Text(
                    trend!,
                    style: textTheme.labelSmall?.copyWith(color: trendUp == false ? DukaniColors.danger : DukaniColors.success),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Section header used above list/grid sections — title + optional
/// "عرض الكل" (view all) action.
class DukaniSectionHeader extends StatelessWidget {
  const DukaniSectionHeader({super.key, required this.title, this.onViewAll, this.subtitle});

  final String title;
  final String? subtitle;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleLarge),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
                ),
            ],
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [Text('عرض الكل'), Icon(LucideIcons.chevronLeft, size: 18)],
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/dukani_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DukaniNavItem {
  const DukaniNavItem({required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating, pill-shaped bottom navigation — five destinations max, with a
/// raised gold POS button in the center as the primary action.
class DukaniBottomNav extends StatelessWidget {
  const DukaniBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.onCenterTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<DukaniNavItem> items;
  final VoidCallback? onCenterTap;

  /// Builds one slot per item, plus an extra blank slot in the middle to
  /// make room for the floating center button — the gap must be an *added*
  /// slot, not a substitute for a real item, or whichever item lands on
  /// the middle index would silently never render.
  List<Widget> _buildSlots() {
    final gapAt = onCenterTap != null ? items.length ~/ 2 : -1;
    final totalSlots = items.length + (onCenterTap != null ? 1 : 0);
    final slots = <Widget>[];
    var itemIndex = 0;
    for (var slot = 0; slot < totalSlots; slot++) {
      if (slot == gapAt) {
        slots.add(const Expanded(child: SizedBox()));
      } else {
        final idx = itemIndex++;
        slots.add(Expanded(child: _NavButton(item: items[idx], selected: currentIndex == idx, onTap: () => onTap(idx))));
      }
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            height: 68,
            decoration: BoxDecoration(
              color: dark ? DukaniColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(DukaniRadii.xl),
              boxShadow: DukaniShadows.floating(dark: dark),
            ),
            child: Row(children: _buildSlots()),
          ),
          if (onCenterTap != null)
            Positioned(
              top: -22,
              child: GestureDetector(
                onTap: onCenterTap,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: DukaniColors.goldGradient,
                    shape: BoxShape.circle,
                    boxShadow: DukaniShadows.gold(),
                    border: Border.all(color: dark ? DukaniColors.darkBg : DukaniColors.paper, width: 4),
                  ),
                  child: const Icon(LucideIcons.store, color: Colors.white, size: 26),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.selected, required this.onTap});
  final DukaniNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : DukaniColors.ink300;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DukaniRadii.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? item.activeIcon : item.icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(item.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}

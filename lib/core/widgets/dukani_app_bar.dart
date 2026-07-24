import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/dukani_theme.dart';

/// Shared top bar: back button (or menu), centered title, and up to two
/// trailing actions — matches every inner screen (reports, POS, settings…).
class DukaniAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DukaniAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.showBack = true,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: leading ?? (showBack ? const _CircleBack() : null),
      actions: actions,
    );
  }
}

class _CircleBack extends StatelessWidget {
  const _CircleBack();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Theme.of(context).brightness == Brightness.dark ? DukaniColors.darkSurfaceAlt : DukaniColors.forest50,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).maybePop(),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(LucideIcons.arrowRight, size: 18),
          ),
        ),
      ),
    );
  }
}

/// Small circular icon button (bell/menu) used at the edges of the app bar.
class DukaniIconAction extends StatelessWidget {
  const DukaniIconAction({super.key, required this.icon, this.onTap, this.dotted = false, this.count});

  final IconData icon;
  final VoidCallback? onTap;
  final bool dotted;
  /// When set (and > 0), shows the real number instead of a plain dot —
  /// pass this instead of [dotted] wherever a genuine count is available.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final showBadge = (count != null && count! > 0) || dotted;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: dark ? DukaniColors.darkSurfaceAlt : DukaniColors.forest50,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, size: 18)),
            ),
          ),
          if (showBadge)
            Positioned(
              top: count != null ? 2 : 6,
              right: count != null ? 2 : 6,
              child: count != null
                  ? Container(
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(color: DukaniColors.danger, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                      alignment: Alignment.center,
                      child: Text(
                        count! > 9 ? '9+' : '$count',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, height: 1),
                      ),
                    )
                  : Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: DukaniColors.danger, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                    ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/dukani_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Standard labeled text field with consistent spacing + optional
/// leading/trailing icon and error text slot.
class DukaniTextField extends StatelessWidget {
  const DukaniTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffix,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.textDirection,
    this.maxLines = 1,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? errorText;
  final bool enabled;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  /// Fires on Enter — HID barcode scanners emulate a keyboard and send
  /// Enter right after the code, so this lets a focused field auto-submit
  /// without the cashier touching anything.
  final ValueChanged<String>? onSubmitted;
  /// Forces LTR for numeric-only fields (amounts, phone numbers…) so digit
  /// groups don't get bidi-reordered by the app's ambient RTL direction.
  final TextDirection? textDirection;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: textTheme.titleSmall),
          const SizedBox(height: 8),
        ],
        _wrapDirection(
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            enabled: enabled,
            autofocus: autofocus,
            textInputAction: textInputAction,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textAlign: TextAlign.right,
            textDirection: textDirection,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              errorText: errorText,
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
              suffixIcon: suffix,
            ),
          ),
        ),
      ],
    );
  }

  /// The hint text inside [InputDecoration] follows the ambient
  /// [Directionality], not the [TextField.textDirection] param — so a
  /// forced-LTR numeric field would still show its placeholder
  /// bidi-reordered (e.g. "0.00" as "00.0") unless we override it here too.
  Widget _wrapDirection(Widget field) {
    if (textDirection == null) return field;
    return Directionality(textDirection: textDirection!, child: field);
  }
}

/// Segmented picker row (used for e.g. business-type or plan selection).
class DukaniChoiceChip extends StatelessWidget {
  const DukaniChoiceChip({super.key, required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    // Selected reads as a soft tinted pill (accent-tint fill, accent text),
    // not a solid brand-color fill — keeps the single accent color reserved
    // for primary actions rather than painting every active filter chip.
    final fg = selected ? DukaniColors.forest600 : scheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DukaniRadii.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? DukaniColors.forest50 : (dark ? DukaniColors.darkSurfaceAlt : DukaniColors.paper),
          borderRadius: BorderRadius.circular(DukaniRadii.pill),
          border: Border.all(color: selected ? Colors.transparent : scheme.outline, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// Search field used atop list screens (reports, products, invoices…).
class DukaniSearchField extends StatelessWidget {
  const DukaniSearchField({super.key, this.hint = 'بحث', this.onChanged, this.onSubmitted, this.controller, this.trailing});

  final String hint;
  final ValueChanged<String>? onChanged;
  /// Fires on the Enter/newline keystroke — a hardware barcode scanner
  /// (USB or Bluetooth "gun") behaves exactly like a keyboard typing the
  /// code fast and then pressing Enter, so wiring this is what makes such
  /// a scanner "just work" against a focused text field with zero
  /// per-device setup.
  final ValueChanged<String>? onSubmitted;
  final TextEditingController? controller;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: const Icon(LucideIcons.search, size: 20),
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/dukani_theme.dart';
import 'dukani_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Confirmation dialog for destructive/important actions (delete invoice,
/// cancel tax registration, end shift…).
class DukaniConfirmDialog extends StatelessWidget {
  const DukaniConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'تأكيد',
    this.cancelLabel = 'إلغاء',
    this.destructive = false,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final IconData? icon;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'تأكيد',
    String cancelLabel = 'إلغاء',
    bool destructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => DukaniConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(DukaniSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Container(
                width: 56,
                height: 56,
                margin: const EdgeInsets.only(bottom: DukaniSpacing.md),
                decoration: BoxDecoration(
                  color: (destructive ? DukaniColors.dangerBg : DukaniColors.forest50),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: destructive ? DukaniColors.danger : DukaniColors.forest600),
              ),
            Text(title, style: textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500), textAlign: TextAlign.center),
            const SizedBox(height: DukaniSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: DukaniOutlineButton(label: cancelLabel, onPressed: () => Navigator.of(context).pop(false)),
                ),
                const SizedBox(width: DukaniSpacing.md),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(backgroundColor: destructive ? DukaniColors.danger : Theme.of(context).colorScheme.primary),
                      child: Text(confirmLabel),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard bottom-sheet shell with a drag handle + title, used for filters,
/// action menus (share/print/download invoice), and quick pickers.
Future<T?> showDukaniSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DukaniSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: DukaniSpacing.lg),
                  decoration: BoxDecoration(color: DukaniColors.ink100, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: DukaniSpacing.lg),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}

/// A single row action inside an action sheet (share / print / download…).
class DukaniSheetAction extends StatelessWidget {
  const DukaniSheetAction({super.key, required this.icon, required this.label, this.onTap, this.color});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: (color ?? scheme.primary).withOpacity(0.1), borderRadius: BorderRadius.circular(DukaniRadii.sm)),
        child: Icon(icon, color: color ?? scheme.primary, size: 20),
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      trailing: const Icon(LucideIcons.chevronLeft, color: DukaniColors.ink300),
    );
  }
}

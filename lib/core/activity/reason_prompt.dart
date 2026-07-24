import 'package:flutter/material.dart';

import '../theme/dukani_theme.dart';
import '../widgets/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Blocks a delete/edit until the employee types a reason — required so the
/// audit log always has one, never optional. Returns null if they back out,
/// in which case the caller must not proceed with the action.
Future<String?> promptForReason(BuildContext context, {required String title}) {
  final controller = TextEditingController();
  return showDukaniSheet<String>(
    context,
    title: title,
    child: StatefulBuilder(
      builder: (context, setSheetState) {
        final trimmed = controller.text.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'هذا الإجراء حساس ويُسجَّل في سجل التدقيق — يرجى ذكر السبب قبل المتابعة',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500),
            ),
            const SizedBox(height: DukaniSpacing.lg),
            DukaniTextField(
              label: 'السبب',
              hint: 'مثال: طلب العميل إلغاء الفاتورة',
              controller: controller,
              maxLines: 2,
              autofocus: true,
              onChanged: (_) => setSheetState(() {}),
            ),
            const SizedBox(height: DukaniSpacing.xl),
            DukaniButton(
              label: 'تأكيد ومتابعة',
              icon: LucideIcons.checkCircle2,
              onPressed: trimmed.isEmpty ? null : () => Navigator.pop(context, trimmed),
            ),
          ],
        );
      },
    ),
  );
}

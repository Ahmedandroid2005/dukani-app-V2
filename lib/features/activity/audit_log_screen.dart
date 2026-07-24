import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'activity_log_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A focused view of the shared activity feed — only actions flagged
/// [sensitive] (deletions, discount overrides, permission/settings
/// changes) show up here, for compliance review.
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensitive = ref.watch(activityLogProvider).where((e) => e.sensitive).toList();

    return Scaffold(
      appBar: const DukaniAppBar(title: 'سجل التدقيق'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(DukaniSpacing.lg),
            child: DukaniCard(
              color: DukaniColors.dangerBg,
              child: Row(
                children: [
                  const Icon(LucideIcons.fingerprint, color: DukaniColors.danger),
                  const SizedBox(width: DukaniSpacing.md),
                  Expanded(
                    child: Text(
                      'يعرض هذا السجل العمليات الحساسة فقط: الحذف، الخصومات الاستثنائية، وتعديل الصلاحيات والإعدادات.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: sensitive.isEmpty
                ? const DukaniEmptyState(title: 'لا توجد عمليات حساسة مسجّلة', icon: LucideIcons.fingerprint)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, 0, DukaniSpacing.lg, DukaniSpacing.lg),
                    itemCount: sensitive.length,
                    separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
                    itemBuilder: (context, i) => ActivityRow(entry: sensitive[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

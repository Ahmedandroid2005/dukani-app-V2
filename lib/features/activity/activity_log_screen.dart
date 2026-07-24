import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _categoryIcons = <String, IconData>{
  'مبيعات': LucideIcons.store,
  'مخزون': LucideIcons.warehouse,
  'موظفون': LucideIcons.idCard,
  'إعدادات': LucideIcons.settings,
  'صلاحيات': LucideIcons.shieldCheck,
  'حذف': LucideIcons.trash2,
};

class ActivityLogScreen extends ConsumerStatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  String _category = 'الكل';

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(activityLogProvider);
    final visible = _category == 'الكل' ? entries : entries.where((e) => e.category == _category).toList();

    return Scaffold(
      appBar: const DukaniAppBar(title: 'سجل النشاط'),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.md, DukaniSpacing.lg, DukaniSpacing.md),
              children: [
                for (final c in ['الكل', ...mockActivityCategories]) ...[
                  DukaniChoiceChip(label: c, selected: c == _category, onTap: () => setState(() => _category = c)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const DukaniEmptyState(title: 'لا توجد أنشطة', icon: LucideIcons.history)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, 0, DukaniSpacing.lg, DukaniSpacing.lg),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
                    itemBuilder: (context, i) => ActivityRow(entry: visible[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.entry});
  final MockActivityEntry entry;

  bool get _hasAuditDetail =>
      entry.reason.isNotEmpty || entry.branch.isNotEmpty || entry.device.isNotEmpty || entry.ipStatus.isNotEmpty || entry.beforeSnapshot != null;

  @override
  Widget build(BuildContext context) {
    return DukaniCard(
      onTap: _hasAuditDetail ? () => _showAuditDetail(context) : null,
      child: Row(
        children: [
          entry.employeePhoto != null
              ? DukaniAvatarImage(photoBytes: entry.employeePhoto, size: 40)
              : Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: entry.sensitive ? DukaniColors.dangerBg : DukaniColors.forest50, borderRadius: BorderRadius.circular(DukaniRadii.sm)),
                  child: Icon(_categoryIcons[entry.category] ?? LucideIcons.history, size: 18, color: entry.sensitive ? DukaniColors.danger : DukaniColors.forest600),
                ),
          const SizedBox(width: DukaniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.action, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(entry.employeeName, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                    Text(' · ', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                    Text(entry.date, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                  ],
                ),
              ],
            ),
          ),
          DukaniAmountText(entry.time, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
        ],
      ),
    );
  }

  void _showAuditDetail(BuildContext context) {
    showDukaniSheet(
      context,
      title: 'تفاصيل العملية',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(entry.action, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: DukaniSpacing.lg),
          _AuditRow(icon: LucideIcons.user, label: 'الموظف', value: entry.employeeName),
          if (entry.branch.isNotEmpty) _AuditRow(icon: LucideIcons.store, label: 'الفرع', value: entry.branch),
          if (entry.device.isNotEmpty) _AuditRow(icon: LucideIcons.monitorSmartphone, label: 'الجهاز', value: entry.device),
          if (entry.ipStatus.isNotEmpty) _AuditRow(icon: LucideIcons.wifi, label: 'حالة الاتصال', value: entry.ipStatus),
          _AuditRow(icon: LucideIcons.clock, label: 'الوقت', value: entry.time),
          _AuditRow(icon: LucideIcons.calendar, label: 'التاريخ', value: entry.date),
          if (entry.reason.isNotEmpty) ...[
            const SizedBox(height: DukaniSpacing.md),
            Text('السبب المذكور', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(entry.reason, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
          ],
          if (entry.beforeSnapshot != null) ...[
            const SizedBox(height: DukaniSpacing.md),
            Text('قبل التعديل', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.danger)),
            const SizedBox(height: 4),
            Text(entry.beforeSnapshot!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
          ],
          if (entry.afterSnapshot != null) ...[
            const SizedBox(height: DukaniSpacing.md),
            Text('بعد التعديل', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.success)),
            const SizedBox(height: 4),
            Text(entry.afterSnapshot!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
          ],
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: DukaniColors.ink500),
          const SizedBox(width: DukaniSpacing.md),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
          const Spacer(),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: Theme.of(context).textTheme.titleSmall)),
        ],
      ),
    );
  }
}

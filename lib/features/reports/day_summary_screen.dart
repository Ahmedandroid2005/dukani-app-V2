import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/pos/sales_log_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../activity/activity_log_screen.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

class DaySummaryScreen extends ConsumerStatefulWidget {
  const DaySummaryScreen({super.key});

  @override
  ConsumerState<DaySummaryScreen> createState() => _DaySummaryScreenState();
}

class _DaySummaryScreenState extends ConsumerState<DaySummaryScreen> {
  DateTime _selectedDate = DateTime.now();

  bool get _isToday => _isSameDay(_selectedDate, DateTime.now());

  String get _dayLabel {
    final now = DateTime.now();
    if (_isSameDay(_selectedDate, now)) return 'اليوم';
    if (_isSameDay(_selectedDate, now.subtract(const Duration(days: 1)))) return 'أمس';
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = ref.watch(activityLogProvider);
    final entries = allEntries.where((e) => _isSameDay(e.timestamp, _selectedDate)).toList();
    final sensitiveCount = entries.where((e) => e.sensitive).length;

    final byEmployee = <String, int>{};
    for (final e in entries) {
      byEmployee[e.employeeName] = (byEmployee[e.employeeName] ?? 0) + 1;
    }
    final busiest = byEmployee.entries.isEmpty ? null : (byEmployee.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;

    final sales = ref.watch(salesLogProvider);
    final liveRevenue = _isToday ? sales.fold<double>(0, (s, r) => s + r.total) : 0.0;
    final liveInvoices = _isToday ? sales.length : 0;

    final byCategory = <String, int>{};
    for (final e in entries) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + 1;
    }

    return Scaffold(
      appBar: const DukaniAppBar(title: 'ملخص اليوم'),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          Row(
            children: [
              DukaniChoiceChip(label: 'اليوم', selected: _isToday, onTap: () => setState(() => _selectedDate = DateTime.now())),
              const SizedBox(width: 8),
              DukaniChoiceChip(
                label: 'أمس',
                selected: _isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1))),
                onTap: () => setState(() => _selectedDate = DateTime.now().subtract(const Duration(days: 1))),
              ),
              const SizedBox(width: 8),
              DukaniOutlineButton(label: 'تاريخ آخر', icon: LucideIcons.calendar, expand: false, onPressed: _pickDate),
            ],
          ),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniCard(
            color: DukaniColors.forest700,
            child: Column(
              children: [
                Text('كل شي حصل $_dayLabel بلمحة واحدة', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                const SizedBox(height: 6),
                DukaniAmountText('${entries.length} حدث', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.lg),
          Row(
            children: [
              Expanded(
                child: DukaniStatTile(
                  label: 'مبيعات الجلسة الحالية',
                  value: liveRevenue > 0 ? '${liveRevenue.toStringAsFixed(0)} ${currentCurrencySymbol()}' : '—',
                  icon: LucideIcons.store,
                  iconColor: DukaniColors.forest600,
                  trend: liveInvoices > 0 ? '$liveInvoices فاتورة' : null,
                  trendUp: true,
                ),
              ),
              const SizedBox(width: DukaniSpacing.md),
              Expanded(
                child: DukaniStatTile(
                  label: 'عمليات حساسة',
                  value: '$sensitiveCount',
                  icon: LucideIcons.alertTriangle,
                  iconColor: sensitiveCount > 0 ? DukaniColors.danger : DukaniColors.success,
                  trend: sensitiveCount > 0 ? 'راجعها' : 'كل شي طبيعي',
                  trendUp: sensitiveCount == 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: DukaniSpacing.md),
          if (busiest != null)
            DukaniCard(
              color: DukaniColors.gold100,
              child: Row(
                children: [
                  const Icon(LucideIcons.star, color: DukaniColors.gold700),
                  const SizedBox(width: DukaniSpacing.md),
                  Expanded(
                    child: Text(
                      'الأكثر نشاطًا $_dayLabel: ${busiest.key} (${busiest.value} عملية)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.gold700),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: DukaniSpacing.xl),
          if (byCategory.isNotEmpty) ...[
            Text('حسب النوع', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.ink500)),
            const SizedBox(height: DukaniSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in byCategory.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: DukaniColors.forest50, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
                    child: Text('${entry.key} (${entry.value})', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: DukaniColors.forest700)),
                  ),
              ],
            ),
            const SizedBox(height: DukaniSpacing.xl),
          ],
          Text('كل الأحداث بالترتيب', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: DukaniSpacing.md),
          if (entries.isEmpty)
            DukaniEmptyState(title: 'ما فيه أحداث $_dayLabel', icon: LucideIcons.history)
          else
            for (final e in entries) ...[
              ActivityRow(entry: e),
              const SizedBox(height: DukaniSpacing.md),
            ],
        ],
      ),
    );
  }
}

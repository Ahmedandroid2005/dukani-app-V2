import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pricing/pricing_controllers.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TaxesScreen extends ConsumerWidget {
  const TaxesScreen({super.key});

  void _openForm(BuildContext context, WidgetRef ref, {MockTaxRate? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final percentController = TextEditingController(text: existing != null ? existing.percentage.toStringAsFixed(0) : '');

    showDukaniSheet(
      context,
      title: existing == null ? 'ضريبة جديدة' : 'تعديل الضريبة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DukaniTextField(label: 'اسم الضريبة', hint: 'مثال: ضريبة القيمة المضافة', controller: nameController, autofocus: existing == null),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'النسبة %', hint: '0', controller: percentController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(
            label: existing == null ? 'إضافة' : 'حفظ التعديلات',
            onPressed: () {
              final name = nameController.text.trim();
              final percent = double.tryParse(percentController.text.trim());
              if (name.isEmpty || percent == null) return;
              if (existing == null) {
                ref.read(taxesProvider.notifier).add(MockTaxRate(id: ref.read(taxesProvider.notifier).nextId(), name: name, percentage: percent));
              } else {
                ref.read(taxesProvider.notifier).update(existing.id, existing.copyWith(name: name, percentage: percent));
              }
              Navigator.pop(context);
            },
          ),
          if (existing != null && !existing.isDefault) ...[
            const SizedBox(height: DukaniSpacing.md),
            DukaniOutlineButton(
              label: 'حذف',
              icon: LucideIcons.trash2,
              onPressed: () {
                ref.read(taxesProvider.notifier).remove(existing.id);
                Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rates = ref.watch(taxesProvider);

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'الضرائب',
        actions: [DukaniIconAction(icon: LucideIcons.plus, onTap: () => _openForm(context, ref))],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        itemCount: rates.length,
        separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
        itemBuilder: (context, i) {
          final t = rates[i];
          return DukaniCard(
            onTap: () => _openForm(context, ref, existing: t),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: DukaniColors.forest50, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.percent, color: DukaniColors.forest600),
                ),
                const SizedBox(width: DukaniSpacing.md),
                Expanded(
                  child: Row(
                    children: [
                      Text(t.name, style: Theme.of(context).textTheme.titleSmall),
                      if (t.isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: DukaniColors.gold100, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
                          child: Text('افتراضي', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.gold700)),
                        ),
                      ],
                    ],
                  ),
                ),
                DukaniAmountText('${t.percentage.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: DukaniColors.forest700)),
              ],
            ),
          );
        },
      ),
    );
  }
}

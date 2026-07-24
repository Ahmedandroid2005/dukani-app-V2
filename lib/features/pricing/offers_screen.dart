import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pricing/pricing_controllers.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  void _openForm(BuildContext context, WidgetRef ref, {MockOffer? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final percentController = TextEditingController(text: existing != null ? existing.discountPercent.toStringAsFixed(0) : '');
    String scope = existing?.scope ?? mockPosCategories.first;

    showDukaniSheet(
      context,
      title: existing == null ? 'عرض جديد' : 'تعديل العرض',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DukaniTextField(label: 'اسم العرض', hint: 'مثال: خصم نهاية الأسبوع', controller: titleController, autofocus: existing == null),
              const SizedBox(height: DukaniSpacing.lg),
              DukaniTextField(label: 'نسبة الخصم %', hint: '0', controller: percentController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr),
              const SizedBox(height: DukaniSpacing.lg),
              Text('الفئة المشمولة', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: DukaniSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in mockPosCategories) DukaniChoiceChip(label: c, selected: c == scope, onTap: () => setSheetState(() => scope = c)),
                ],
              ),
              const SizedBox(height: DukaniSpacing.xl),
              DukaniButton(
                label: existing == null ? 'إضافة' : 'حفظ التعديلات',
                onPressed: () {
                  final title = titleController.text.trim();
                  final percent = double.tryParse(percentController.text.trim());
                  if (title.isEmpty || percent == null) return;
                  if (existing == null) {
                    ref.read(offersProvider.notifier).add(MockOffer(id: ref.read(offersProvider.notifier).nextId(), title: title, discountPercent: percent, scope: scope));
                  } else {
                    ref.read(offersProvider.notifier).update(existing.id, existing.copyWith(title: title, discountPercent: percent, scope: scope));
                  }
                  Navigator.pop(context);
                },
              ),
              if (existing != null) ...[
                const SizedBox(height: DukaniSpacing.md),
                DukaniOutlineButton(
                  label: 'حذف',
                  icon: LucideIcons.trash2,
                  onPressed: () {
                    ref.read(offersProvider.notifier).remove(existing.id);
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(offersProvider);

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'العروض والخصومات',
        actions: [DukaniIconAction(icon: LucideIcons.plus, onTap: () => _openForm(context, ref))],
      ),
      body: offers.isEmpty
          ? const DukaniEmptyState(title: 'لا توجد عروض', icon: LucideIcons.tag)
          : ListView.separated(
              padding: const EdgeInsets.all(DukaniSpacing.lg),
              itemCount: offers.length,
              separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
              itemBuilder: (context, i) {
                final o = offers[i];
                return DukaniCard(
                  onTap: () => _openForm(context, ref, existing: o),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: o.active ? DukaniColors.forest50 : DukaniColors.ink100, borderRadius: BorderRadius.circular(DukaniRadii.sm)),
                        child: Icon(LucideIcons.tag, color: o.active ? DukaniColors.forest600 : DukaniColors.ink500),
                      ),
                      const SizedBox(width: DukaniSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.title, style: Theme.of(context).textTheme.titleSmall),
                            Text(o.scope, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                          ],
                        ),
                      ),
                      DukaniAmountText('${o.discountPercent.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: DukaniColors.forest700)),
                      const SizedBox(width: DukaniSpacing.sm),
                      Switch(value: o.active, onChanged: (_) => ref.read(offersProvider.notifier).toggleActive(o.id), activeColor: DukaniColors.forest600),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

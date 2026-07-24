import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pricing/pricing_controllers.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

String _randomCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rand = Random();
  return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
}

class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});

  void _openForm(BuildContext context, WidgetRef ref, {MockCoupon? existing}) {
    final codeController = TextEditingController(text: existing?.code ?? _randomCode());
    final percentController = TextEditingController(text: existing != null ? existing.discountPercent.toStringAsFixed(0) : '');
    final limitController = TextEditingController(text: existing != null ? existing.usageLimit.toString() : '100');

    showDukaniSheet(
      context,
      title: existing == null ? 'كوبون جديد' : 'تعديل الكوبون',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DukaniTextField(label: 'الكود', controller: codeController, textDirection: TextDirection.ltr),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'نسبة الخصم %', hint: '0', controller: percentController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'الحد الأقصى للاستخدام', hint: '100', controller: limitController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(
            label: existing == null ? 'إضافة' : 'حفظ التعديلات',
            onPressed: () {
              final code = codeController.text.trim().toUpperCase();
              final percent = double.tryParse(percentController.text.trim());
              final limit = int.tryParse(limitController.text.trim()) ?? 0;
              if (code.isEmpty || percent == null) return;
              if (existing == null) {
                ref.read(couponsProvider.notifier).add(MockCoupon(id: ref.read(couponsProvider.notifier).nextId(), code: code, discountPercent: percent, usageLimit: limit));
              } else {
                ref.read(couponsProvider.notifier).update(existing.id, existing.copyWith(code: code, discountPercent: percent, usageLimit: limit));
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
                ref.read(couponsProvider.notifier).remove(existing.id);
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
    final coupons = ref.watch(couponsProvider);

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'الكوبونات',
        actions: [DukaniIconAction(icon: LucideIcons.plus, onTap: () => _openForm(context, ref))],
      ),
      body: coupons.isEmpty
          ? const DukaniEmptyState(title: 'لا توجد كوبونات', icon: LucideIcons.ticket)
          : ListView.separated(
              padding: const EdgeInsets.all(DukaniSpacing.lg),
              itemCount: coupons.length,
              separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
              itemBuilder: (context, i) {
                final c = coupons[i];
                final exhausted = c.usageLimit > 0 && c.usedCount >= c.usageLimit;
                return DukaniCard(
                  onTap: () => _openForm(context, ref, existing: c),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.active && !exhausted ? DukaniColors.forest50 : DukaniColors.ink100, borderRadius: BorderRadius.circular(DukaniRadii.sm)),
                        child: Icon(LucideIcons.ticket, color: c.active && !exhausted ? DukaniColors.forest600 : DukaniColors.ink500),
                      ),
                      const SizedBox(width: DukaniSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DukaniAmountText(c.code, style: Theme.of(context).textTheme.titleSmall),
                            Text(
                              exhausted ? 'تم استنفاد الحد (${c.usedCount}/${c.usageLimit})' : 'استُخدم ${c.usedCount} من ${c.usageLimit}',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500),
                            ),
                          ],
                        ),
                      ),
                      DukaniAmountText('${c.discountPercent.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: DukaniColors.forest700)),
                      const SizedBox(width: DukaniSpacing.sm),
                      Switch(value: c.active, onChanged: (_) => ref.read(couponsProvider.notifier).toggleActive(c.id), activeColor: DukaniColors.forest600),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

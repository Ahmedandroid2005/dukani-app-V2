import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/inventory/stocktake_controller.dart';
import '../../core/products/products_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class StocktakeScreen extends ConsumerStatefulWidget {
  const StocktakeScreen({super.key});

  @override
  ConsumerState<StocktakeScreen> createState() => _StocktakeScreenState();
}

class _StocktakeScreenState extends ConsumerState<StocktakeScreen> {
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _controllerFor(String id, int systemStock) {
    return _controllers.putIfAbsent(id, () => TextEditingController(text: systemStock.toString()));
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _finish() {
    final catalog = ref.read(productsProvider);
    final variances = <StocktakeVariance>[];
    for (final p in catalog) {
      final counted = int.tryParse(_controllers[p.id]?.text.trim() ?? '');
      if (counted != null && counted != p.stock) {
        variances.add(StocktakeVariance(productName: p.name, systemStock: p.stock, countedStock: counted));
        ref.read(productsProvider.notifier).setStock(p.id, counted);
      }
    }
    ref.read(stocktakeProvider.notifier).record(variances);
    final changed = variances.length;
    showDukaniSheet(
      context,
      title: 'اكتمل الجرد',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(LucideIcons.clipboardCheck, size: 48, color: DukaniColors.success),
          const SizedBox(height: DukaniSpacing.md),
          Text(
            changed == 0 ? 'المخزون مطابق تمامًا لسجلات النظام' : 'تم تحديث $changed منتج بعد المطابقة',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(
            label: 'تم',
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Counting by whole units only makes sense for unit-sold products —
    // weighed/bulk/multi-pack items are adjusted from the product form
    // instead, where their real (fractional) quantity fields live.
    final catalog = ref.watch(productsProvider).where((p) => p.unitMode == ProductUnitMode.each).toList();

    return Scaffold(
      appBar: const DukaniAppBar(title: 'جرد المخزون'),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          Text(
            'أدخل الكمية الفعلية المعدودة لكل منتج — سيتم مقارنتها بكمية النظام وتحديث المخزون عند الإنهاء. (المنتجات التي تُباع بالوزن أو بالكرتون/الفرط تُعدَّل من صفحة تعديل المنتج)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500),
          ),
          const SizedBox(height: DukaniSpacing.lg),
          for (final p in catalog) ...[
            DukaniCard(
              child: Row(
                children: [
                  DukaniProductImage(icon: p.icon, photoBytes: p.photoBytes, size: 40),
                  const SizedBox(width: DukaniSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: Theme.of(context).textTheme.titleSmall),
                        Text('النظام: ${p.stock}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 84,
                    child: TextField(
                      controller: _controllerFor(p.id, p.stock),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                  const SizedBox(width: DukaniSpacing.sm),
                  _VarianceBadge(counted: int.tryParse(_controllerFor(p.id, p.stock).text), system: p.stock),
                ],
              ),
            ),
            const SizedBox(height: DukaniSpacing.md),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DukaniSpacing.lg),
          child: DukaniButton(label: 'إنهاء الجرد وتحديث المخزون', icon: LucideIcons.checkCircle2, onPressed: _finish),
        ),
      ),
    );
  }
}

class _VarianceBadge extends StatelessWidget {
  const _VarianceBadge({required this.counted, required this.system});
  final int? counted;
  final int system;

  @override
  Widget build(BuildContext context) {
    if (counted == null) return const SizedBox(width: 36);
    final diff = counted! - system;
    if (diff == 0) return const Icon(LucideIcons.checkCircle2, color: DukaniColors.success, size: 20);
    final color = diff > 0 ? DukaniColors.gold600 : DukaniColors.danger;
    return DukaniAmountText('${diff > 0 ? '+' : ''}$diff', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.bold));
  }
}

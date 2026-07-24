import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pos/sales_log_controller.dart';
import '../../core/products/products_controller.dart';
import '../../core/reports/live_reports.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:dukani_app/core/business/currency.dart';

class TopProductsScreen extends ConsumerWidget {
  const TopProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final aggregates = productSalesAggregates(ref.watch(salesLogProvider));

    final ranked = products.where((p) => aggregates.containsKey(p.id)).toList()
      ..sort((a, b) => aggregates[b.id]!.revenue.compareTo(aggregates[a.id]!.revenue));

    return Scaffold(
      appBar: const DukaniAppBar(title: 'أفضل المنتجات مبيعًا'),
      body: ranked.isEmpty
          ? const DukaniEmptyState(title: 'لا توجد مبيعات بعد', message: 'ستظهر هنا أفضل منتجاتك مبيعًا فور إتمام أول عملية بيع')
          : ListView.separated(
              padding: const EdgeInsets.all(DukaniSpacing.lg),
              itemCount: ranked.length,
              separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
              itemBuilder: (context, i) {
                final p = ranked[i];
                final agg = aggregates[p.id]!;
                return DukaniCard(
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: i < 3 ? DukaniColors.gold100 : DukaniColors.ink100,
                          shape: BoxShape.circle,
                        ),
                        child: Text('${i + 1}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: i < 3 ? DukaniColors.gold700 : DukaniColors.ink500)),
                      ),
                      const SizedBox(width: DukaniSpacing.md),
                      DukaniProductImage(icon: p.icon, photoBytes: p.photoBytes, size: 44),
                      const SizedBox(width: DukaniSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: Theme.of(context).textTheme.titleSmall),
                            Text('${p.category} — ${agg.qtySold} عملية بيع', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                          ],
                        ),
                      ),
                      DukaniAmountText('${agg.revenue.toStringAsFixed(0)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.forest700)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

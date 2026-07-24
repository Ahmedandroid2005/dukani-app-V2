import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/pos/sales_log_controller.dart';
import '../../../core/products/products_controller.dart';
import '../../../core/reports/live_reports.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/dukani_theme.dart';
import '../../../core/widgets/dukani_amount_text.dart';
import '../../../core/widgets/dukani_card.dart';
import '../../../core/widgets/dukani_product_image.dart';
import '../../../core/widgets/dukani_states.dart';
import '../../../data/mock/mock_models.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TopProductsSection extends ConsumerWidget {
  const TopProductsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final aggregates = productSalesAggregates(ref.watch(salesLogProvider));

    final ranked = products.where((p) => aggregates.containsKey(p.id)).toList()
      ..sort((a, b) => aggregates[b.id]!.revenue.compareTo(aggregates[a.id]!.revenue));
    final top = ranked.take(3).toList();

    return DukaniCard(
      padding: const EdgeInsets.all(DukaniSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DukaniSectionHeader(title: 'أفضل المنتجات مبيعًا', onViewAll: () => context.pushNamed(R.topProducts)),
          const SizedBox(height: DukaniSpacing.md),
          if (top.isEmpty)
            const DukaniEmptyState(title: 'لا توجد مبيعات بعد', icon: LucideIcons.packageSearch)
          else
            for (final p in top) ...[
              _ProductRow(product: p, aggregate: aggregates[p.id]!),
              if (p != top.last) const Divider(height: DukaniSpacing.xl),
            ],
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.aggregate});
  final MockProduct product;
  final ProductSalesAggregate aggregate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        DukaniProductImage(icon: product.icon, photoBytes: product.photoBytes, size: 40),
        const SizedBox(width: DukaniSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: textTheme.titleSmall),
              Text('${aggregate.qtySold} عملية بيع', style: textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
            ],
          ),
        ),
        DukaniAmountText('${aggregate.revenue.toStringAsFixed(0)} ${currentCurrencySymbol()}', style: textTheme.titleSmall?.copyWith(color: DukaniColors.forest700)),
      ],
    );
  }
}

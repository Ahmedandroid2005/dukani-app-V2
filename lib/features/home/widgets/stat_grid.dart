import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../core/customers/customers_controller.dart';
import '../../../core/products/products_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/dukani_theme.dart';
import '../../../core/widgets/dukani_card.dart';
import '../../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeStatGrid extends ConsumerWidget {
  const HomeStatGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final customers = ref.watch(customersProvider);
    final debtCount = customers.where((c) => c.debt > 0).length;
    final lowStockCount = products.where((p) => !p.isOutOfStock && p.isLowStock).length;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: DukaniSpacing.md,
      crossAxisSpacing: DukaniSpacing.md,
      childAspectRatio: 0.95,
      children: [
        DukaniStatTile(
          label: 'المنتجات',
          value: '${products.length}',
          icon: LucideIcons.package,
          iconColor: DukaniColors.forest600,
          onTap: () => context.pushNamed(R.products),
        ),
        DukaniStatTile(
          label: 'ديون العملاء',
          value: '$debtCount',
          icon: LucideIcons.fileText,
          iconColor: DukaniColors.danger,
          onTap: () => context.pushNamed(R.customers, queryParameters: {'debt': 'true'}),
        ),
        DukaniStatTile(
          label: 'المخزون',
          value: '$lowStockCount',
          icon: LucideIcons.warehouse,
          iconColor: DukaniColors.gold600,
          onTap: () => context.pushNamed(R.inventory),
        ),
      ],
    );
  }
}

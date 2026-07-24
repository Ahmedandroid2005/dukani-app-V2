import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/business/feature_flags.dart';
import '../../core/products/categories_controller.dart';
import '../../core/products/products_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'manage_categories_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _query = '';
  String _category = 'الكل';

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(productsProvider);
    final categories = ['الكل', ...ref.watch(categoriesProvider)];

    final products = catalog.where((p) {
      final matchesCategory = _category == 'الكل' || p.category == _category;
      final matchesQuery = _query.isEmpty || p.name.contains(_query) || p.barcode.contains(_query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'المنتجات',
        actions: [
          DukaniIconAction(icon: LucideIcons.slidersHorizontal, onTap: () => showManageCategoriesSheet(context, ref)),
          DukaniIconAction(icon: LucideIcons.fileUp, onTap: () => context.pushNamed(R.dataImport)),
          if (isFeatureEnabled('barcode_labels'))
            DukaniIconAction(icon: LucideIcons.tag, onTap: () => context.pushNamed(R.barcodeLabels)),
          DukaniIconAction(icon: LucideIcons.plus, onTap: () => context.pushNamed(R.productNew)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.md, DukaniSpacing.lg, DukaniSpacing.md),
            child: DukaniSearchField(hint: 'بحث بالاسم أو الباركود', onChanged: (v) => setState(() => _query = v)),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: DukaniSpacing.lg),
              children: [
                for (final c in categories) ...[
                  DukaniChoiceChip(label: c, selected: c == _category, onTap: () => setState(() => _category = c)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.md),
          Expanded(
            child: products.isEmpty
                ? DukaniEmptyState(
                    title: 'لا توجد منتجات',
                    message: 'جرّب كلمة بحث أخرى أو أضف منتجًا جديدًا',
                    icon: LucideIcons.package,
                    actionLabel: 'إضافة منتج',
                    onAction: () => context.pushNamed(R.productNew),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, 0, DukaniSpacing.lg, DukaniSpacing.lg),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
                    itemBuilder: (context, i) => _ProductRow(product: products[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});
  final MockProduct product;

  @override
  Widget build(BuildContext context) {
    final lowStock = product.isLowStock;
    return DukaniCard(
      onTap: () => context.pushNamed(R.productEdit, pathParameters: {'id': product.id}),
      child: Row(
        children: [
          DukaniProductImage(icon: product.icon, photoBytes: product.photoBytes),
          const SizedBox(width: DukaniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(product.category, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                if (product.warrantyMonths > 0) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.shieldCheck, size: 12, color: DukaniColors.info),
                      const SizedBox(width: 3),
                      Text('ضمان ${product.warrantyMonths} شهر', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.info)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DukaniAmountText(product.priceSummary, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.forest700)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: lowStock ? DukaniColors.dangerBg : DukaniColors.successBg, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
                child: DukaniAmountText(
                  product.stockSummary,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: lowStock ? DukaniColors.danger : DukaniColors.success),
                ),
              ),
            ],
          ),
          const Icon(LucideIcons.chevronLeft, color: DukaniColors.ink300),
        ],
      ),
    );
  }
}

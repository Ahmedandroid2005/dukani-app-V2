import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/products/products_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _adjustReasons = ['وارد جديد', 'تالف', 'تصحيح جرد', 'أخرى'];

double _tiedUpValue(MockProduct p) => switch (p.unitMode) {
      ProductUnitMode.each => p.stock * p.price,
      ProductUnitMode.weight => p.openStockKg * p.pricePerKg,
      ProductUnitMode.bulkContainer => (p.openStockKg + p.stock * p.containerSizeKg) * p.pricePerKg,
      ProductUnitMode.multiPack => p.stock * p.packPrice + p.looseUnits * p.piecePrice,
    };

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _query = '';
  String _filter = 'الكل';

  void _adjust(MockProduct product) {
    if (product.unitMode == ProductUnitMode.weight) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا منتج يُباع بالوزن — عدّل الكمية المتوفرة من صفحة تعديل المنتج')),
      );
      return;
    }
    int delta = 0;
    String reason = _adjustReasons.first;
    showDukaniSheet(
      context,
      title: 'تعديل المخزون — ${product.name}',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final preview = (product.stock + delta).clamp(0, 1 << 31);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundStepButton(icon: LucideIcons.minus, onTap: () => setSheetState(() => delta--)),
                  SizedBox(
                    width: 90,
                    child: Column(
                      children: [
                        DukaniAmountText('$preview', style: Theme.of(context).textTheme.headlineMedium),
                        Text('الكمية الجديدة', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                      ],
                    ),
                  ),
                  _RoundStepButton(icon: LucideIcons.plus, onTap: () => setSheetState(() => delta++)),
                ],
              ),
              const SizedBox(height: DukaniSpacing.xl),
              Text('السبب', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: DukaniSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in _adjustReasons) DukaniChoiceChip(label: r, selected: r == reason, onTap: () => setSheetState(() => reason = r)),
                ],
              ),
              const SizedBox(height: DukaniSpacing.xl),
              DukaniButton(
                label: 'تأكيد التعديل',
                icon: LucideIcons.checkCircle2,
                onPressed: delta == 0
                    ? null
                    : () {
                        ref.read(productsProvider.notifier).adjustStock(product.id, delta);
                        Navigator.pop(context);
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(productsProvider);

    final lowStockCount = catalog.where((p) => !p.isOutOfStock && p.isLowStock).length;
    final outOfStockCount = catalog.where((p) => p.isOutOfStock).length;
    final stockValue = catalog.fold<double>(0, (s, p) => s + _tiedUpValue(p));

    final visible = catalog.where((p) {
      final matchesQuery = _query.isEmpty || p.name.contains(_query) || p.barcode.contains(_query);
      final matchesFilter = switch (_filter) {
        'منخفض' => !p.isOutOfStock && p.isLowStock,
        'نفذ' => p.isOutOfStock,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'المخزون',
        actions: [DukaniIconAction(icon: LucideIcons.clipboardCheck, onTap: () => context.pushNamed(R.stocktake))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.md, DukaniSpacing.lg, 0),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: DukaniSpacing.md,
              crossAxisSpacing: DukaniSpacing.md,
              childAspectRatio: 0.95,
              children: [
                DukaniStatTile(label: 'قيمة المخزون', value: '${stockValue.toStringAsFixed(0)} ${currentCurrencySymbol()}', icon: LucideIcons.warehouse, iconColor: DukaniColors.forest600),
                DukaniStatTile(label: 'منخفض', value: '$lowStockCount', icon: LucideIcons.trendingDown, iconColor: DukaniColors.gold600),
                DukaniStatTile(label: 'نافد', value: '$outOfStockCount', icon: LucideIcons.shoppingCart, iconColor: DukaniColors.danger),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.lg, DukaniSpacing.lg, DukaniSpacing.md),
            child: DukaniSearchField(hint: 'بحث بالاسم أو الباركود', onChanged: (v) => setState(() => _query = v)),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: DukaniSpacing.lg),
              children: [
                for (final f in const ['الكل', 'منخفض', 'نفذ']) ...[
                  DukaniChoiceChip(label: f, selected: f == _filter, onTap: () => setState(() => _filter = f)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.md),
          Expanded(
            child: visible.isEmpty
                ? const DukaniEmptyState(title: 'لا توجد منتجات', icon: LucideIcons.package)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, 0, DukaniSpacing.lg, DukaniSpacing.lg),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
                    itemBuilder: (context, i) => _InventoryRow(product: visible[i], onTap: () => _adjust(visible[i])),
                  ),
          ),
        ],
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.product, required this.onTap});
  final MockProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outOfStock = product.isOutOfStock;
    final lowStock = !outOfStock && product.isLowStock;
    final badgeColor = outOfStock ? DukaniColors.danger : (lowStock ? DukaniColors.gold600 : DukaniColors.success);
    final badgeBg = outOfStock ? DukaniColors.dangerBg : (lowStock ? DukaniColors.gold100 : DukaniColors.successBg);

    return DukaniCard(
      onTap: onTap,
      child: Row(
        children: [
          DukaniProductImage(icon: product.icon, photoBytes: product.photoBytes, size: 44),
          const SizedBox(width: DukaniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(product.category, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
            child: DukaniAmountText(product.shortStockLabel, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: badgeColor)),
          ),
          const SizedBox(width: 6),
          const Icon(LucideIcons.slidersHorizontal, size: 18, color: DukaniColors.ink300),
        ],
      ),
    );
  }
}

class _RoundStepButton extends StatelessWidget {
  const _RoundStepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DukaniColors.forest50,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(14), child: Icon(icon, color: DukaniColors.forest700)),
      ),
    );
  }
}

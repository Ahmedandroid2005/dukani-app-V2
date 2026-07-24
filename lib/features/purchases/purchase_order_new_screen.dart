import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/products/products_controller.dart';
import '../../core/purchases/purchases_controller.dart';
import '../../core/suppliers/suppliers_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PurchaseOrderNewScreen extends ConsumerStatefulWidget {
  const PurchaseOrderNewScreen({super.key});

  @override
  ConsumerState<PurchaseOrderNewScreen> createState() => _PurchaseOrderNewScreenState();
}

class _PurchaseOrderNewScreenState extends ConsumerState<PurchaseOrderNewScreen> {
  MockSupplier? _supplier;
  bool _pickingProduct = false;
  final List<PurchaseItem> _items = [];

  double get _total => _items.fold(0.0, (s, i) => s + i.lineTotal);

  void _pickProduct(MockProduct product) {
    setState(() => _pickingProduct = false);
    final qtyController = TextEditingController(text: '1');
    final costController = TextEditingController();

    showDukaniSheet(
      context,
      title: product.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: DukaniTextField(label: 'الكمية', controller: qtyController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
              const SizedBox(width: DukaniSpacing.md),
              Expanded(child: DukaniTextField(label: 'تكلفة الوحدة', hint: '0.00', controller: costController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
            ],
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(
            label: 'إضافة',
            onPressed: () {
              final qty = int.tryParse(qtyController.text.trim());
              final cost = double.tryParse(costController.text.trim());
              if (qty == null || qty <= 0 || cost == null) return;
              setState(() => _items.add(PurchaseItem(productId: product.id, productName: product.name, qty: qty, cost: cost)));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirm() {
    if (_supplier == null || _items.isEmpty) return;
    ref.read(purchaseOrdersProvider.notifier).create(MockPurchaseOrder(
          id: 'po${DateTime.now().microsecondsSinceEpoch}',
          supplierId: _supplier!.id,
          supplierName: _supplier!.name,
          items: _items,
          date: 'اليوم',
        ));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_supplier == null) {
      return Scaffold(appBar: const DukaniAppBar(title: 'اختر المورد'), body: _buildSupplierPicker());
    }
    if (_pickingProduct) {
      return Scaffold(
        appBar: DukaniAppBar(title: 'اختر منتجًا', leading: DukaniIconAction(icon: LucideIcons.x, onTap: () => setState(() => _pickingProduct = false))),
        body: _buildProductPicker(),
      );
    }
    return Scaffold(
      appBar: DukaniAppBar(title: 'طلب شراء — ${_supplier!.name}'),
      body: _buildOrderForm(),
    );
  }

  Widget _buildSupplierPicker() {
    final suppliers = ref.watch(suppliersProvider);
    return ListView.separated(
      padding: const EdgeInsets.all(DukaniSpacing.lg),
      itemCount: suppliers.length,
      separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
      itemBuilder: (context, i) {
        final s = suppliers[i];
        return DukaniCard(
          onTap: () => setState(() => _supplier = s),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: Theme.of(context).textTheme.titleSmall),
                    Text(s.category, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronLeft, color: DukaniColors.ink300),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductPicker() {
    final catalog = ref.watch(productsProvider);
    return ListView.separated(
      padding: const EdgeInsets.all(DukaniSpacing.lg),
      itemCount: catalog.length,
      separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
      itemBuilder: (context, i) {
        final p = catalog[i];
        return DukaniCard(
          onTap: () => _pickProduct(p),
          child: Row(
            children: [
              DukaniProductImage(icon: p.icon, photoBytes: p.photoBytes, size: 32),
              const SizedBox(width: DukaniSpacing.md),
              Expanded(child: Text(p.name, style: Theme.of(context).textTheme.titleSmall)),
              Text('مخزون ${p.stock}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderForm() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(DukaniSpacing.lg),
            children: [
              if (_items.isEmpty)
                const DukaniEmptyState(title: 'لم تُضف منتجات بعد', icon: LucideIcons.package)
              else
                for (final item in _items) ...[
                  DukaniCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName, style: Theme.of(context).textTheme.titleSmall),
                              Text('${item.qty} × ${item.cost.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                            ],
                          ),
                        ),
                        DukaniAmountText('${item.lineTotal.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.forest700)),
                        IconButton(onPressed: () => setState(() => _items.remove(item)), icon: const Icon(LucideIcons.x, size: 16, color: DukaniColors.ink300)),
                      ],
                    ),
                  ),
                  const SizedBox(height: DukaniSpacing.md),
                ],
              DukaniOutlineButton(label: 'إضافة منتج', icon: LucideIcons.plus, onPressed: () => setState(() => _pickingProduct = true)),
              if (_items.isNotEmpty) ...[
                const SizedBox(height: DukaniSpacing.xl),
                DukaniCard(
                  color: DukaniColors.forest700,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('الإجمالي', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
                      DukaniAmountText('${_total.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DukaniSpacing.lg),
            child: DukaniButton(label: 'إنشاء طلب الشراء', icon: LucideIcons.checkCircle2, onPressed: _items.isEmpty ? null : _confirm),
          ),
        ),
      ],
    );
  }
}

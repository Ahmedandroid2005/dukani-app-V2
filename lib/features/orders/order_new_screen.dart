import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/orders/orders_controller.dart';
import '../../core/products/products_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OrderNewScreen extends ConsumerStatefulWidget {
  const OrderNewScreen({super.key});

  @override
  ConsumerState<OrderNewScreen> createState() => _OrderNewScreenState();
}

class _OrderNewScreenState extends ConsumerState<OrderNewScreen> {
  final _nameController = TextEditingController(text: 'عميل نقدي');
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _pickingProduct = false;
  final List<OrderItem> _items = [];

  double get _total => _items.fold(0.0, (s, i) => s + i.lineTotal);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addProduct(MockProduct product) {
    setState(() {
      _pickingProduct = false;
      _items.add(OrderItem(productId: product.id, productName: product.name, qty: 1, price: product.price));
    });
  }

  void _confirm() {
    if (_items.isEmpty) return;
    ref.read(ordersProvider.notifier).create(MockCustomerOrder(
          id: 'ord${DateTime.now().microsecondsSinceEpoch}',
          customerName: _nameController.text.trim().isEmpty ? 'عميل نقدي' : _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          items: _items,
          date: 'اليوم',
          notes: _notesController.text.trim(),
        ));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_pickingProduct) {
      return Scaffold(
        appBar: DukaniAppBar(title: 'اختر منتجًا', leading: DukaniIconAction(icon: LucideIcons.x, onTap: () => setState(() => _pickingProduct = false))),
        body: _buildProductPicker(),
      );
    }

    return Scaffold(
      appBar: const DukaniAppBar(title: 'طلب جديد'),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(DukaniSpacing.lg),
              children: [
                DukaniTextField(label: 'اسم العميل', controller: _nameController),
                const SizedBox(height: DukaniSpacing.lg),
                DukaniTextField(label: 'رقم الجوال (اختياري)', hint: '05xxxxxxxx', controller: _phoneController, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr),
                const SizedBox(height: DukaniSpacing.xl),
                Text('المنتجات', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: DukaniSpacing.md),
                if (_items.isEmpty)
                  const DukaniEmptyState(title: 'لم تُضف منتجات بعد', icon: LucideIcons.listChecks)
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
                                Text('${item.qty} × ${item.price.toStringAsFixed(0)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
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
                const SizedBox(height: DukaniSpacing.xl),
                DukaniTextField(label: 'ملاحظات (اختياري)', hint: 'مثال: بدون سكر', controller: _notesController),
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
              child: DukaniButton(label: 'إنشاء الطلب', icon: LucideIcons.checkCircle2, onPressed: _items.isEmpty ? null : _confirm),
            ),
          ),
        ],
      ),
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
          onTap: () => _addProduct(p),
          child: Row(
            children: [
              DukaniProductImage(icon: p.icon, photoBytes: p.photoBytes, size: 32),
              const SizedBox(width: DukaniSpacing.md),
              Expanded(child: Text(p.name, style: Theme.of(context).textTheme.titleSmall)),
              DukaniAmountText('${p.price.toStringAsFixed(0)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.forest700)),
            ],
          ),
        );
      },
    );
  }
}

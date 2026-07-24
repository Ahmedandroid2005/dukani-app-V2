import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/business/currency.dart';
import '../../core/printing/barcode_label_pdf_builder.dart';
import '../../core/products/products_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';

/// Lets a merchant print barcode stickers for their products — most useful
/// for anything that doesn't come with a manufacturer barcode already on
/// it (produce, repackaged deli items, house-brand goods), so this doubles
/// as the "assign this item a barcode" flow via [BarcodeLabelPdfBuilder.generateInternalCode].
class BarcodeLabelsScreen extends ConsumerStatefulWidget {
  const BarcodeLabelsScreen({super.key});

  @override
  ConsumerState<BarcodeLabelsScreen> createState() => _BarcodeLabelsScreenState();
}

class _BarcodeLabelsScreenState extends ConsumerState<BarcodeLabelsScreen> {
  final Map<String, int> _selected = {}; // productId -> copies
  bool _busy = false;

  void _toggle(MockProduct product) {
    setState(() {
      if (_selected.containsKey(product.id)) {
        _selected.remove(product.id);
      } else {
        _selected[product.id] = 1;
      }
    });
  }

  void _setCopies(String productId, int copies) {
    setState(() => _selected[productId] = copies.clamp(1, 99));
  }

  Future<void> _assignBarcode(MockProduct product) async {
    final code = BarcodeLabelPdfBuilder.generateInternalCode();
    // MockProduct.copyWith() doesn't cover every field (barcode included) —
    // build the updated product explicitly so the new code actually
    // persists instead of silently no-op'ing.
    final updated = MockProduct(
      id: product.id,
      name: product.name,
      category: product.category,
      price: product.price,
      stock: product.stock,
      icon: product.icon,
      barcode: code,
      soldQty: product.soldQty,
      revenue: product.revenue,
      cost: product.cost,
      photoBytes: product.photoBytes,
      expiryDate: product.expiryDate,
      unitMode: product.unitMode,
      pricePerKg: product.pricePerKg,
      openStockKg: product.openStockKg,
      containerSizeKg: product.containerSizeKg,
      packSize: product.packSize,
      packPrice: product.packPrice,
      piecePrice: product.piecePrice,
      looseUnits: product.looseUnits,
      variants: product.variants,
      serialNumber: product.serialNumber,
      warrantyMonths: product.warrantyMonths,
    );
    ref.read(productsProvider.notifier).update(product.id, updated);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم توليد باركود لـ ${product.name}: $code')));
  }

  Future<void> _printSelected() async {
    final products = ref.read(productsProvider);
    final requests = [
      for (final entry in _selected.entries)
        if (products.where((p) => p.id == entry.key).isNotEmpty)
          LabelRequest(
            name: products.firstWhere((p) => p.id == entry.key).name,
            barcode: products.firstWhere((p) => p.id == entry.key).barcode,
            price: products.firstWhere((p) => p.id == entry.key).price,
            currencySymbol: currentCurrencySymbol(),
            copies: entry.value,
          ),
    ];
    if (requests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر منتجًا واحدًا على الأقل')));
      return;
    }
    setState(() => _busy = true);
    try {
      final doc = await BarcodeLabelPdfBuilder.build(requests);
      await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'ملصقات باركود');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    return Scaffold(
      appBar: const DukaniAppBar(title: 'طباعة ملصقات الباركود'),
      body: products.isEmpty
          ? const DukaniEmptyState(title: 'لا توجد منتجات', message: 'أضف منتجات أولاً عشان تقدر تطبع ملصقاتها', icon: LucideIcons.tag)
          : ListView.separated(
              padding: const EdgeInsets.all(DukaniSpacing.lg),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.sm),
              itemBuilder: (context, i) {
                final p = products[i];
                final selected = _selected.containsKey(p.id);
                return DukaniCard(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Row(
                    children: [
                      Checkbox(value: selected, onChanged: (_) => _toggle(p), activeColor: DukaniColors.forest600),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: Theme.of(context).textTheme.titleSmall),
                            Text(
                              p.barcode.isEmpty ? 'بدون باركود' : p.barcode,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: p.barcode.isEmpty ? DukaniColors.warning : DukaniColors.ink500),
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                      if (p.barcode.isEmpty)
                        TextButton(onPressed: () => _assignBarcode(p), child: const Text('توليد باركود'))
                      else if (selected) ...[
                        IconButton(icon: const Icon(LucideIcons.minus, size: 16), onPressed: () => _setCopies(p.id, (_selected[p.id] ?? 1) - 1)),
                        Text('${_selected[p.id]}', style: Theme.of(context).textTheme.titleSmall),
                        IconButton(icon: const Icon(LucideIcons.plus, size: 16), onPressed: () => _setCopies(p.id, (_selected[p.id] ?? 1) + 1)),
                      ],
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(DukaniSpacing.lg),
                child: DukaniButton(
                  label: _busy ? 'جاري التجهيز...' : 'طباعة ${_selected.length} ملصق',
                  icon: LucideIcons.printer,
                  onPressed: _busy ? null : _printSelected,
                ),
              ),
            ),
    );
  }
}

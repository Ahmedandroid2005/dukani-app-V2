import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/products/products_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/suppliers/suppliers_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SupplierDetailScreen extends ConsumerWidget {
  const SupplierDetailScreen({super.key, required this.supplierId});
  final String supplierId;

  void _settlePayable(BuildContext context, WidgetRef ref, MockSupplier supplier) {
    final controller = TextEditingController(text: supplier.payable.toStringAsFixed(0));
    showDukaniSheet(
      context,
      title: 'تسديد مستحقات — ${supplier.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('المستحق الحالي: ${supplier.payable.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'المبلغ المسدّد', hint: '0.00', controller: controller, keyboardType: TextInputType.number, textDirection: TextDirection.ltr),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniButton(
            label: 'تأكيد التسديد',
            icon: LucideIcons.checkCircle2,
            onPressed: () {
              final amount = double.tryParse(controller.text.trim()) ?? 0;
              if (amount > 0) ref.read(suppliersProvider.notifier).settlePayable(supplier.id, amount);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supplier = ref.watch(suppliersProvider).where((s) => s.id == supplierId).toList();

    if (supplier.isEmpty) {
      return const Scaffold(
        appBar: DukaniAppBar(title: 'المورد'),
        body: DukaniEmptyState(title: 'المورد غير موجود', icon: LucideIcons.searchX),
      );
    }

    final s = supplier.first;
    final linkedProducts = ref.watch(productsProvider).where((p) => p.category == s.category).toList();

    return Scaffold(
      appBar: DukaniAppBar(
        title: s.name,
        actions: [DukaniIconAction(icon: LucideIcons.pencil, onTap: () => context.pushNamed(R.supplierEdit, pathParameters: {'id': s.id}))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          DukaniCard(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: DukaniColors.forest50, shape: BoxShape.circle),
                  child: const Icon(LucideIcons.truck, size: 30, color: DukaniColors.forest600),
                ),
                const SizedBox(height: DukaniSpacing.md),
                Text(s.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                DukaniAmountText(s.phone, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
                const SizedBox(height: 4),
                Text(s.category, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                if (s.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(s.notes, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500), textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniCard(
            color: s.payable > 0 ? DukaniColors.dangerBg : DukaniColors.successBg,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المستحقات', style: Theme.of(context).textTheme.titleSmall),
                    Text('آخر طلبية: ${s.lastOrder}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                  ],
                ),
                DukaniAmountText(
                  '${s.payable.toStringAsFixed(2)} ${currentCurrencySymbol()}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: s.payable > 0 ? DukaniColors.danger : DukaniColors.success),
                ),
              ],
            ),
          ),
          if (s.payable > 0) ...[
            const SizedBox(height: DukaniSpacing.md),
            DukaniButton(label: 'تسديد مستحقات', icon: LucideIcons.wallet, onPressed: () => _settlePayable(context, ref, s)),
          ],
          const SizedBox(height: DukaniSpacing.xl),
          Text('المنتجات المرتبطة (${s.category})', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: DukaniSpacing.md),
          if (linkedProducts.isEmpty)
            const DukaniEmptyState(title: 'لا توجد منتجات في هذه الفئة', icon: LucideIcons.package)
          else
            for (final p in linkedProducts) ...[
              DukaniCard(
                padding: const EdgeInsets.symmetric(horizontal: DukaniSpacing.lg, vertical: DukaniSpacing.md),
                child: Row(
                  children: [
                    DukaniProductImage(icon: p.icon, photoBytes: p.photoBytes, size: 32),
                    const SizedBox(width: DukaniSpacing.md),
                    Expanded(child: Text(p.name, style: Theme.of(context).textTheme.titleSmall)),
                    Text('مخزون ${p.stock}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                  ],
                ),
              ),
              const SizedBox(height: DukaniSpacing.sm),
            ],
        ],
      ),
    );
  }
}

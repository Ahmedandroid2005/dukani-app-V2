import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/suppliers/suppliers_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  String _query = '';
  bool _payableOnly = false;

  @override
  Widget build(BuildContext context) {
    final suppliers = ref.watch(suppliersProvider);

    final totalPayable = suppliers.fold<double>(0, (s, sup) => s + sup.payable);
    final owedCount = suppliers.where((s) => s.payable > 0).length;

    final visible = suppliers.where((s) {
      final matchesQuery = _query.isEmpty || s.name.contains(_query) || s.phone.contains(_query);
      final matchesPayable = !_payableOnly || s.payable > 0;
      return matchesQuery && matchesPayable;
    }).toList();

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'الموردون',
        actions: [
          DukaniIconAction(icon: LucideIcons.fileText, onTap: () => context.pushNamed(R.purchaseOrders)),
          DukaniIconAction(icon: LucideIcons.store, onTap: () => context.pushNamed(R.supplierNew)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.md, DukaniSpacing.lg, 0),
            child: Row(
              children: [
                Expanded(
                  child: DukaniStatTile(label: 'إجمالي الموردين', value: '${suppliers.length}', icon: LucideIcons.truck, iconColor: DukaniColors.forest600),
                ),
                const SizedBox(width: DukaniSpacing.md),
                Expanded(
                  child: DukaniStatTile(
                    label: 'مستحقات لهم',
                    value: '${totalPayable.toStringAsFixed(0)} ${currentCurrencySymbol()}',
                    icon: LucideIcons.fileText,
                    iconColor: DukaniColors.danger,
                    trend: owedCount > 0 ? '$owedCount مورد' : null,
                    trendUp: false,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.lg, DukaniSpacing.lg, DukaniSpacing.md),
            child: DukaniSearchField(hint: 'بحث بالاسم أو الجوال', onChanged: (v) => setState(() => _query = v)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DukaniSpacing.lg),
            child: Row(
              children: [
                DukaniChoiceChip(label: 'الكل', selected: !_payableOnly, onTap: () => setState(() => _payableOnly = false)),
                const SizedBox(width: 8),
                DukaniChoiceChip(label: 'لهم مستحقات', selected: _payableOnly, onTap: () => setState(() => _payableOnly = true)),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.md),
          Expanded(
            child: visible.isEmpty
                ? DukaniEmptyState(
                    title: 'لا يوجد موردون',
                    icon: LucideIcons.truck,
                    actionLabel: 'إضافة مورد',
                    onAction: () => context.pushNamed(R.supplierNew),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, 0, DukaniSpacing.lg, DukaniSpacing.lg),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
                    itemBuilder: (context, i) => _SupplierRow(supplier: visible[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SupplierRow extends StatelessWidget {
  const _SupplierRow({required this.supplier});
  final MockSupplier supplier;

  @override
  Widget build(BuildContext context) {
    final hasPayable = supplier.payable > 0;
    return DukaniCard(
      onTap: () => context.pushNamed(R.supplierDetail, pathParameters: {'id': supplier.id}),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: DukaniColors.forest50, shape: BoxShape.circle),
            child: const Icon(LucideIcons.truck, color: DukaniColors.forest600),
          ),
          const SizedBox(width: DukaniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supplier.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(supplier.category, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
              ],
            ),
          ),
          if (hasPayable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: DukaniColors.dangerBg, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
              child: DukaniAmountText('${supplier.payable.toStringAsFixed(0)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: DukaniColors.danger, fontWeight: FontWeight.bold)),
            )
          else
            Text('لا مستحقات', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.success)),
          const SizedBox(width: 6),
          const Icon(LucideIcons.chevronLeft, color: DukaniColors.ink300),
        ],
      ),
    );
  }
}

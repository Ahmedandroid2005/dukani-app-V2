import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/business/feature_flags.dart';
import '../../core/customers/customers_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key, this.initialDebtOnly = false});
  final bool initialDebtOnly;

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String _query = '';
  late bool _debtOnly = widget.initialDebtOnly;

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);

    final totalDebt = customers.fold<double>(0, (s, c) => s + c.debt);
    final debtorsCount = customers.where((c) => c.debt > 0).length;

    final visible = customers.where((c) {
      final matchesQuery = _query.isEmpty || c.name.contains(_query) || c.phone.contains(_query);
      final matchesDebt = !_debtOnly || c.debt > 0;
      return matchesQuery && matchesDebt;
    }).toList();

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'العملاء',
        actions: [
          if (isFeatureEnabled('loyalty_program'))
            DukaniIconAction(icon: LucideIcons.award, onTap: () => context.pushNamed(R.loyalty)),
          DukaniIconAction(icon: LucideIcons.userPlus, onTap: () => context.pushNamed(R.customerNew)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.md, DukaniSpacing.lg, 0),
            child: Row(
              children: [
                Expanded(
                  child: DukaniStatTile(label: 'إجمالي العملاء', value: '${customers.length}', icon: LucideIcons.users, iconColor: DukaniColors.forest600),
                ),
                const SizedBox(width: DukaniSpacing.md),
                Expanded(
                  child: DukaniStatTile(label: 'إجمالي الديون', value: '${totalDebt.toStringAsFixed(0)} ${currentCurrencySymbol()}', icon: LucideIcons.fileText, iconColor: DukaniColors.danger, trend: debtorsCount > 0 ? '$debtorsCount مدين' : null, trendUp: false),
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
                DukaniChoiceChip(label: 'الكل', selected: !_debtOnly, onTap: () => setState(() => _debtOnly = false)),
                const SizedBox(width: 8),
                DukaniChoiceChip(label: 'عليهم ديون', selected: _debtOnly, onTap: () => setState(() => _debtOnly = true)),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.md),
          Expanded(
            child: visible.isEmpty
                ? DukaniEmptyState(
                    title: 'لا يوجد عملاء',
                    icon: LucideIcons.users,
                    actionLabel: 'إضافة عميل',
                    onAction: () => context.pushNamed(R.customerNew),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, 0, DukaniSpacing.lg, DukaniSpacing.lg),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
                    itemBuilder: (context, i) => _CustomerRow(customer: visible[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  const _CustomerRow({required this.customer});
  final MockCustomer customer;

  @override
  Widget build(BuildContext context) {
    final hasDebt = customer.debt > 0;
    return DukaniCard(
      onTap: () => context.pushNamed(R.customerDetail, pathParameters: {'id': customer.id}),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: DukaniColors.forest50, shape: BoxShape.circle),
            child: const Icon(LucideIcons.user, color: DukaniColors.forest600),
          ),
          const SizedBox(width: DukaniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(customer.phone, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
              ],
            ),
          ),
          if (hasDebt)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: DukaniColors.dangerBg, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
              child: DukaniAmountText('${customer.debt.toStringAsFixed(0)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: DukaniColors.danger, fontWeight: FontWeight.bold)),
            )
          else
            Text('لا يوجد دين', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.success)),
          const SizedBox(width: 6),
          const Icon(LucideIcons.chevronLeft, color: DukaniColors.ink300),
        ],
      ),
    );
  }
}

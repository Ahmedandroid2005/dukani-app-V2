import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/orders/orders_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _statusColors = <String, Color>{
  'جديد': DukaniColors.info,
  'قيد التجهيز': DukaniColors.gold600,
  'جاهز': DukaniColors.success,
  'مكتمل': DukaniColors.ink500,
};

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _filter = 'الكل';

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    final visible = _filter == 'الكل' ? orders : orders.where((o) => o.status == _filter).toList();

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'الطلبات',
        actions: [DukaniIconAction(icon: LucideIcons.plus, onTap: () => context.pushNamed(R.orderNew))],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.md, DukaniSpacing.lg, DukaniSpacing.md),
              children: [
                for (final f in ['الكل', ...orderStatuses]) ...[
                  DukaniChoiceChip(label: f, selected: f == _filter, onTap: () => setState(() => _filter = f)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? DukaniEmptyState(
                    title: 'لا توجد طلبات',
                    icon: LucideIcons.listChecks,
                    actionLabel: 'طلب جديد',
                    onAction: () => context.pushNamed(R.orderNew),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, 0, DukaniSpacing.lg, DukaniSpacing.lg),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
                    itemBuilder: (context, i) {
                      final o = visible[i];
                      final color = _statusColors[o.status] ?? DukaniColors.ink500;
                      final isLast = o.status == orderStatuses.last;
                      return DukaniCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(o.customerName, style: Theme.of(context).textTheme.titleSmall),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(DukaniRadii.pill)),
                                  child: Text(o.status, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${o.items.length} منتجات · ${o.date}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                            const SizedBox(height: DukaniSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                DukaniAmountText('${o.total.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: DukaniColors.forest700)),
                                if (!isLast)
                                  DukaniButton(
                                    label: 'نقل إلى: ${orderStatuses[orderStatuses.indexOf(o.status) + 1]}',
                                    expand: false,
                                    size: DukaniButtonSize.small,
                                    onPressed: () => ref.read(ordersProvider.notifier).advanceStatus(o.id),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

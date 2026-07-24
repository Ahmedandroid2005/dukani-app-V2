import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/pos/cart_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HeldOrdersScreen extends ConsumerWidget {
  const HeldOrdersScreen({super.key});

  void _resume(BuildContext context, WidgetRef ref, int index) {
    final order = ref.read(heldOrdersProvider.notifier).resume(index);
    ref.read(cartProvider.notifier).restore(order);
    context.pop();
  }

  void _discard(WidgetRef ref, int index) {
    ref.read(heldOrdersProvider.notifier).discard(index);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final held = ref.watch(heldOrdersProvider);

    return Scaffold(
      appBar: const DukaniAppBar(title: 'الفواتير المعلّقة'),
      body: held.isEmpty
          ? const DukaniEmptyState(title: 'لا توجد فواتير معلّقة', message: 'الفواتير التي يتم تعليقها من السلة ستظهر هنا لاستئنافها لاحقًا', icon: LucideIcons.receipt)
          : ListView.separated(
              padding: const EdgeInsets.all(DukaniSpacing.lg),
              itemCount: held.length,
              separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
              itemBuilder: (context, i) {
                final order = held[i];
                return DukaniCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(order.heldLabel ?? 'فاتورة معلّقة', style: Theme.of(context).textTheme.titleSmall),
                          DukaniAmountText('${order.total.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.forest700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${order.itemCount} منتج', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                      const SizedBox(height: DukaniSpacing.md),
                      Row(
                        children: [
                          Expanded(child: DukaniOutlineButton(label: 'حذف', icon: LucideIcons.trash2, onPressed: () => _discard(ref, i))),
                          const SizedBox(width: DukaniSpacing.md),
                          Expanded(child: DukaniButton(label: 'استئناف', icon: LucideIcons.playCircle, onPressed: () => _resume(context, ref, i), size: DukaniButtonSize.medium)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

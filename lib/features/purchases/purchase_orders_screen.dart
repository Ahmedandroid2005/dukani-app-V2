import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/products/products_controller.dart';
import '../../core/purchases/purchases_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/session/session_controller.dart';
import '../../core/suppliers/suppliers_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PurchaseOrdersScreen extends ConsumerWidget {
  const PurchaseOrdersScreen({super.key});

  Future<void> _markReceived(BuildContext context, WidgetRef ref, MockPurchaseOrder order) async {
    final ok = await DukaniConfirmDialog.show(
      context,
      title: 'تأكيد استلام الطلبية؟',
      message: 'سيتم تحديث المخزون تلقائيًا وإضافة ${order.total.toStringAsFixed(2)} ${currentCurrencySymbol()} إلى مستحقات "${order.supplierName}".',
      confirmLabel: 'تأكيد الاستلام',
      icon: LucideIcons.package,
    );
    if (!ok) return;

    for (final item in order.items) {
      ref.read(productsProvider.notifier).adjustStock(item.productId, item.qty);
    }
    ref.read(suppliersProvider.notifier).addPayable(order.supplierId, order.total);
    ref.read(purchaseOrdersProvider.notifier).markReceived(order.id);
    ref.read(activityLogProvider.notifier).log(
          'استلام طلبية شراء من ${order.supplierName} بقيمة ${order.total.toStringAsFixed(2)} ${currentCurrencySymbol()}',
          employeeName: ref.read(sessionProvider)?.name ?? 'صاحب المتجر',
          category: 'مخزون',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(purchaseOrdersProvider);
    final pendingTotal = orders.where((o) => !o.received).fold<double>(0, (s, o) => s + o.total);

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'طلبات ومشتريات',
        actions: [DukaniIconAction(icon: LucideIcons.plus, onTap: () => context.pushNamed(R.purchaseOrderNew))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(DukaniSpacing.lg),
            child: DukaniCard(
              color: DukaniColors.forest700,
              child: Column(
                children: [
                  Text('طلبات بانتظار الاستلام', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 6),
                  DukaniAmountText('${pendingTotal.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? DukaniEmptyState(
                    title: 'لا توجد طلبات شراء',
                    message: 'أنشئ طلب شراء جديدًا من أحد الموردين',
                    icon: LucideIcons.fileText,
                    actionLabel: 'طلب شراء جديد',
                    onAction: () => context.pushNamed(R.purchaseOrderNew),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, 0, DukaniSpacing.lg, DukaniSpacing.lg),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
                    itemBuilder: (context, i) {
                      final o = orders[i];
                      return DukaniCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(o.supplierName, style: Theme.of(context).textTheme.titleSmall),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: o.received ? DukaniColors.successBg : DukaniColors.warningBg, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
                                  child: Text(o.received ? 'مستلم' : 'معلّق', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: o.received ? DukaniColors.success : DukaniColors.warning)),
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
                                if (!o.received) DukaniButton(label: 'تأكيد الاستلام', icon: LucideIcons.package, expand: false, size: DukaniButtonSize.small, onPressed: () => _markReceived(context, ref, o)),
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

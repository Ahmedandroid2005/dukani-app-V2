import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/returns/returns_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReturnsScreen extends ConsumerWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final returns = ref.watch(returnsProvider);
    final totalRefunded = returns.fold<double>(0, (s, r) => s + r.refundAmount);

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'المرتجعات',
        actions: [DukaniIconAction(icon: LucideIcons.plus, onTap: () => context.pushNamed(R.returnNew))],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(DukaniSpacing.lg),
            child: DukaniCard(
              color: DukaniColors.forest700,
              child: Column(
                children: [
                  Text('إجمالي المسترد', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 6),
                  DukaniAmountText('${totalRefunded.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Expanded(
            child: returns.isEmpty
                ? DukaniEmptyState(
                    title: 'لا توجد مرتجعات',
                    message: 'إرجاعات الفواتير ستظهر هنا',
                    icon: LucideIcons.undo2,
                    actionLabel: 'إرجاع جديد',
                    onAction: () => context.pushNamed(R.returnNew),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, 0, DukaniSpacing.lg, DukaniSpacing.lg),
                    itemCount: returns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
                    itemBuilder: (context, i) {
                      final r = returns[i];
                      return DukaniCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('إرجاع ${r.invoiceId}', style: Theme.of(context).textTheme.titleSmall),
                                DukaniAmountText('-${r.refundAmount.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.danger)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${r.customerName} · ${r.reason} · ${r.refundMethod}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
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

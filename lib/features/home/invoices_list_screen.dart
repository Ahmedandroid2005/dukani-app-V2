import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/pos/sales_log_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

String _formatInvoiceTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}';
}

class InvoicesListScreen extends ConsumerStatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final sales = ref.watch(salesLogProvider);
    final query = _search.trim();
    final filtered = query.isEmpty
        ? sales
        : sales.where((s) => s.id.contains(query) || (s.customerName ?? 'عميل نقدي').contains(query)).toList();

    return Scaffold(
      appBar: const DukaniAppBar(title: 'الفواتير'),
      body: sales.isEmpty
          ? const DukaniEmptyState(title: 'لا توجد فواتير بعد', message: 'ستظهر هنا كل الفواتير فور إتمام أول عملية بيع', icon: LucideIcons.receipt)
          : ListView.separated(
              padding: const EdgeInsets.all(DukaniSpacing.lg),
              itemCount: filtered.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return DukaniSearchField(hint: 'بحث برقم الفاتورة أو اسم العميل', onChanged: (v) => setState(() => _search = v));
                }
                final invoice = filtered[i - 1];
                return DukaniCard(
                  onTap: () => context.pushNamed(R.invoiceDetail, pathParameters: {'id': invoice.id}),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: DukaniColors.infoBg, borderRadius: BorderRadius.circular(DukaniRadii.sm)),
                        child: const Icon(LucideIcons.receipt, color: DukaniColors.info),
                      ),
                      const SizedBox(width: DukaniSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(invoice.id, style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(width: 8),
                                const DukaniBadge(label: 'مكتملة', tone: DukaniBadgeTone.success),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '${invoice.customerName ?? 'عميل نقدي'} — ${invoice.itemCount} أصناف — ',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DukaniAmountText(
                                  _formatInvoiceTime(invoice.createdAt),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      DukaniAmountText('${invoice.total.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.forest700)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

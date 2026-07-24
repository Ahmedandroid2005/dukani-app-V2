import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/pos/sales_log_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/dukani_theme.dart';
import '../../../core/widgets/dukani_amount_text.dart';
import '../../../core/widgets/dukani_card.dart';
import '../../../core/widgets/dukani_states.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

String _formatInvoiceTime(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}';
}

class InvoicesSection extends ConsumerWidget {
  const InvoicesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesLogProvider);
    final recent = sales.take(5).toList();

    return DukaniCard(
      padding: const EdgeInsets.all(DukaniSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DukaniSectionHeader(
            title: 'الفواتير',
            subtitle: '${sales.length} فاتورة إجمالًا',
            onViewAll: () => context.pushNamed(R.invoices),
          ),
          const SizedBox(height: DukaniSpacing.md),
          if (recent.isEmpty)
            const DukaniEmptyState(title: 'لا توجد فواتير بعد', icon: LucideIcons.receipt)
          else
            for (final inv in recent) ...[
              _InvoiceRow(invoice: inv),
              if (inv != recent.last) const Divider(height: DukaniSpacing.xl),
            ],
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice});
  final SaleRecord invoice;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => context.pushNamed(R.invoiceDetail, pathParameters: {'id': invoice.id}),
      borderRadius: BorderRadius.circular(DukaniRadii.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: DukaniColors.infoBg, borderRadius: BorderRadius.circular(DukaniRadii.sm)),
            child: const Icon(LucideIcons.receipt, size: 18, color: DukaniColors.info),
          ),
          const SizedBox(width: DukaniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.customerName ?? 'عميل نقدي', style: textTheme.titleSmall),
                Row(
                  children: [
                    Text('${invoice.itemCount} أصناف — ', style: textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                    DukaniAmountText(_formatInvoiceTime(invoice.createdAt), style: textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DukaniAmountText('${invoice.total.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: textTheme.titleSmall?.copyWith(color: DukaniColors.forest700)),
              const Icon(LucideIcons.chevronLeft, size: 16, color: DukaniColors.ink300),
            ],
          ),
        ],
      ),
    );
  }
}

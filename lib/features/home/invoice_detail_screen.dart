import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/pos/sales_log_controller.dart';
import '../../core/printing/receipt_data.dart';
import '../../core/printing/receipt_print_service.dart';
import '../../core/store/store_profile_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

String _two(int n) => n.toString().padLeft(2, '0');
String _formatDate(DateTime t) => '${t.year}-${_two(t.month)}-${_two(t.day)} — ${_two(t.hour)}:${_two(t.minute)}';

/// Rebuilds a printable receipt from a completed sale — the original
/// [ReceiptData] used at checkout isn't kept, only [SaleRecord]'s summary
/// fields, so discount %/tax rate are backed out from the stored amounts
/// rather than the (unavailable) original per-line breakdown.
ReceiptData _receiptFrom(SaleRecord invoice, String storeName) {
  final subtotal = invoice.total + invoice.discountAmount - invoice.taxAmount;
  final taxableAmount = subtotal - invoice.discountAmount;
  return ReceiptData(
    invoiceId: invoice.id,
    createdAt: invoice.createdAt,
    storeName: storeName,
    cashierName: invoice.cashierName,
    lines: [
      for (final l in invoice.lines) ReceiptLine(name: l.productName, qtyLabel: '×${l.qty}', unitPrice: l.price, lineTotal: l.revenue),
    ],
    subtotal: subtotal,
    discountPercent: subtotal == 0 ? 0 : (invoice.discountAmount / subtotal * 100),
    discountAmount: invoice.discountAmount,
    taxRate: taxableAmount == 0 ? 0 : (invoice.taxAmount / taxableAmount * 100),
    taxAmount: invoice.taxAmount,
    total: invoice.total,
    methodLabel: invoice.methodLabel,
    currencySymbol: currentCurrencySymbol(),
  );
}

class InvoiceDetailScreen extends ConsumerWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});
  final String invoiceId;

  Future<void> _runPrintAction(BuildContext context, Future<PrintOutcome> Function() action) async {
    final outcome = await action();
    if (!context.mounted) return;
    if (outcome.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(outcome.message!)));
    }
  }

  void _openActions(BuildContext context, WidgetRef ref, SaleRecord invoice) {
    final storeName = ref.read(storeProfileProvider).valueOrNull?.storeName;
    final receipt = _receiptFrom(invoice, storeName?.trim().isNotEmpty == true ? storeName! : 'دُكّاني');

    showDukaniSheet(
      context,
      title: 'إجراءات الفاتورة',
      child: Column(
        children: [
          DukaniSheetAction(
            icon: LucideIcons.printer,
            label: 'طباعة الفاتورة',
            onTap: () {
              Navigator.pop(context);
              _runPrintAction(context, () => ReceiptPrintService.print(receipt));
            },
          ),
          DukaniSheetAction(
            icon: LucideIcons.share2,
            label: 'مشاركة الفاتورة',
            onTap: () {
              Navigator.pop(context);
              _runPrintAction(context, () => ReceiptPrintService.share(receipt));
            },
          ),
          DukaniSheetAction(
            icon: LucideIcons.trash2,
            label: 'حذف الفاتورة',
            color: DukaniColors.danger,
            onTap: () async {
              Navigator.pop(context);
              final ok = await DukaniConfirmDialog.show(
                context,
                title: 'حذف الفاتورة؟',
                message: 'سيتم تسجيل هذا الإجراء في سجل التنبيهات ولا يمكن التراجع عنه.',
                confirmLabel: 'حذف',
                destructive: true,
                icon: LucideIcons.trash2,
              );
              if (!ok) return;
              if (!context.mounted) return;
              await logSensitiveAction(
                context,
                ref,
                action: 'حذف الفاتورة ${invoice.id}',
                category: 'حذف',
                beforeSnapshot:
                    '${invoice.id} — ${invoice.customerName ?? 'عميل نقدي'} — ${invoice.itemCount} منتجات — ${invoice.total.toStringAsFixed(2)} ${currentCurrencySymbol()} — ${invoice.methodLabel}',
                afterSnapshot: 'تم الحذف نهائيًا',
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesLogProvider);
    SaleRecord? invoice;
    for (final s in sales) {
      if (s.id == invoiceId) {
        invoice = s;
        break;
      }
    }

    if (invoice == null) {
      return const Scaffold(
        appBar: DukaniAppBar(title: 'الفاتورة'),
        body: DukaniEmptyState(title: 'الفاتورة غير موجودة', icon: LucideIcons.searchX),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: DukaniAppBar(
        title: invoice.id,
        actions: [DukaniIconAction(icon: LucideIcons.moreHorizontal, onTap: () => _openActions(context, ref, invoice!))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          DukaniCard(
            child: Column(
              children: [
                const Icon(LucideIcons.store, size: 32, color: DukaniColors.forest700),
                const SizedBox(height: 8),
                Text(_formatDate(invoice.createdAt), style: textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
                const SizedBox(height: DukaniSpacing.lg),
                DukaniAmountText('${invoice.total.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: DukaniTypography.statFigure(Theme.of(context).colorScheme.primary, size: 32)),
                const SizedBox(height: 4),
                const DukaniBadge(label: 'مكتملة', tone: DukaniBadgeTone.success),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoRow(label: 'العميل', value: invoice.customerName ?? 'عميل نقدي'),
                const Divider(height: DukaniSpacing.xl),
                _InfoRow(label: 'الكاشير', value: invoice.cashierName ?? '—'),
                const Divider(height: DukaniSpacing.xl),
                _InfoRow(label: 'طريقة الدفع', value: invoice.methodLabel),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('الأصناف (${invoice.itemCount})', style: textTheme.titleMedium),
                const SizedBox(height: DukaniSpacing.md),
                for (final line in invoice.lines) ...[
                  Row(
                    children: [
                      Expanded(child: Text('${line.productName} × ${line.qty}', style: textTheme.bodyMedium)),
                      DukaniAmountText('${line.revenue.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: DukaniSpacing.sm),
                ],
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(label: 'مشاركة / طباعة', icon: LucideIcons.share2, onPressed: () => _openActions(context, ref, invoice!)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
        Text(value, style: textTheme.titleSmall),
      ],
    );
  }
}

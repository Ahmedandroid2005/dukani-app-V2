import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/pos/sales_log_controller.dart';
import '../../core/products/products_controller.dart';
import '../../core/returns/returns_controller.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

String _todayLabel() {
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)}';
}

class ReturnNewScreen extends ConsumerStatefulWidget {
  const ReturnNewScreen({super.key});

  @override
  ConsumerState<ReturnNewScreen> createState() => _ReturnNewScreenState();
}

class _ReturnNewScreenState extends ConsumerState<ReturnNewScreen> {
  SaleRecord? _invoice;
  final Set<String> _selectedProductIds = {};
  String _reason = returnReasons.first;
  String _refundMethod = refundMethods.first;

  void _pickInvoice(SaleRecord invoice) {
    setState(() {
      _invoice = invoice;
      _selectedProductIds
        ..clear()
        ..addAll(invoice.lines.map((l) => l.productId));
    });
  }

  double get _refundAmount {
    if (_invoice == null) return 0;
    return _invoice!.lines.where((l) => _selectedProductIds.contains(l.productId)).fold(0.0, (s, l) => s + l.revenue);
  }

  void _confirm() {
    if (_invoice == null || _selectedProductIds.isEmpty) return;
    final lines = _invoice!.lines.where((l) => _selectedProductIds.contains(l.productId)).toList();

    ref.read(returnsProvider.notifier).create(MockReturn(
          id: 'ret${DateTime.now().microsecondsSinceEpoch}',
          invoiceId: _invoice!.id,
          customerName: _invoice!.customerName ?? 'عميل نقدي',
          items: [for (final l in lines) MockInvoiceItem(name: l.productName, qty: l.qty, price: l.price)],
          refundAmount: _refundAmount,
          reason: _reason,
          refundMethod: _refundMethod,
          date: _todayLabel(),
        ));

    // Real stock reversal, matched by product ID — not a fragile
    // name-lookup, so it's correct even if the product was renamed since
    // the sale.
    final productsNotifier = ref.read(productsProvider.notifier);
    for (final line in lines) {
      productsNotifier.adjustStock(line.productId, line.qty);
    }

    ref.read(activityLogProvider.notifier).log(
          'إرجاع فاتورة ${_invoice!.id} بقيمة ${_refundAmount.toStringAsFixed(2)} ${currentCurrencySymbol()}',
          employeeName: ref.read(sessionProvider)?.name ?? 'صاحب المتجر',
          category: 'مبيعات',
          sensitive: true,
        );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DukaniAppBar(title: _invoice == null ? 'اختر الفاتورة' : 'إرجاع ${_invoice!.id}'),
      body: _invoice == null ? _buildInvoicePicker(context) : _buildReturnForm(context),
    );
  }

  Widget _buildInvoicePicker(BuildContext context) {
    final sales = ref.watch(salesLogProvider);
    if (sales.isEmpty) {
      return const DukaniEmptyState(title: 'لا توجد فواتير بعد', message: 'يحتاج الإرجاع فاتورة بيع حقيقية أولًا', icon: LucideIcons.receipt);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(DukaniSpacing.lg),
      itemCount: sales.length,
      separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
      itemBuilder: (context, i) {
        final inv = sales[i];
        return DukaniCard(
          onTap: () => _pickInvoice(inv),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv.id, style: Theme.of(context).textTheme.titleSmall),
                    Text('${inv.customerName ?? 'عميل نقدي'} · ${inv.itemCount} منتجات', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                  ],
                ),
              ),
              DukaniAmountText('${inv.total.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.forest700)),
              const SizedBox(width: 6),
              const Icon(LucideIcons.chevronLeft, color: DukaniColors.ink300),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReturnForm(BuildContext context) {
    final invoice = _invoice!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(DukaniSpacing.lg),
            children: [
              Text('المنتجات المطلوب إرجاعها', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: DukaniSpacing.md),
              DukaniCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final line in invoice.lines) ...[
                      CheckboxListTile(
                        value: _selectedProductIds.contains(line.productId),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selectedProductIds.add(line.productId);
                          } else {
                            _selectedProductIds.remove(line.productId);
                          }
                        }),
                        title: Text(line.productName, style: Theme.of(context).textTheme.titleSmall),
                        subtitle: Text('${line.qty} × ${line.price.toStringAsFixed(0)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                        activeColor: DukaniColors.forest600,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (line != invoice.lines.last) const Divider(height: 1, indent: 16),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: DukaniSpacing.xl),
              Text('سبب الإرجاع', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: DukaniSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in returnReasons) DukaniChoiceChip(label: r, selected: r == _reason, onTap: () => setState(() => _reason = r)),
                ],
              ),
              const SizedBox(height: DukaniSpacing.xl),
              Text('طريقة الاسترداد', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: DukaniSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in refundMethods) DukaniChoiceChip(label: m, selected: m == _refundMethod, onTap: () => setState(() => _refundMethod = m)),
                ],
              ),
              const SizedBox(height: DukaniSpacing.xl),
              DukaniCard(
                color: DukaniColors.dangerBg,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('مبلغ الاسترداد', style: Theme.of(context).textTheme.titleSmall),
                    DukaniAmountText('${_refundAmount.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: DukaniColors.danger)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DukaniSpacing.lg),
            child: DukaniButton(
              label: 'تأكيد الإرجاع',
              icon: LucideIcons.undo2,
              onPressed: _selectedProductIds.isEmpty ? null : _confirm,
            ),
          ),
        ),
      ],
    );
  }
}

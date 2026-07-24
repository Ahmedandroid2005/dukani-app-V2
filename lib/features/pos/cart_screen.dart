import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/pos/cart_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/session/session_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _discountPresets = [0.0, 5.0, 10.0, 15.0];

/// The owner (or no employee overlay at all, e.g. mid-testing) can always
/// discount — an employee needs the discount permission explicitly turned
/// on for their account.
bool _canApplyDiscount(WidgetRef ref) {
  final session = ref.watch(sessionProvider);
  if (session == null || session.role == 'مالك') return true;
  return session.permissions.applyDiscount;
}

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  Future<void> _holdOrder(BuildContext context, WidgetRef ref, CartState cart) async {
    final controller = TextEditingController(text: cart.customerName ?? '');
    final label = await showDukaniSheet<String>(
      context,
      title: 'تعليق الفاتورة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('سيتم حفظ السلة الحالية لاستئنافها لاحقًا', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500), textAlign: TextAlign.center),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(hint: 'اسم العميل أو ملاحظة (اختياري)', controller: controller, autofocus: true),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniButton(label: 'تعليق', icon: LucideIcons.pauseCircle, onPressed: () => Navigator.pop(context, controller.text.trim())),
        ],
      ),
    );
    if (label == null) return;
    ref.read(heldOrdersProvider.notifier).hold(cart, label.isEmpty ? 'فاتورة معلّقة' : label);
    ref.read(cartProvider.notifier).clear();
    if (context.mounted) context.pop();
  }

  Future<void> _clearCart(BuildContext context, WidgetRef ref) async {
    final ok = await DukaniConfirmDialog.show(
      context,
      title: 'إفراغ السلة؟',
      message: 'سيتم حذف جميع المنتجات من السلة الحالية.',
      confirmLabel: 'إفراغ',
      destructive: true,
      icon: LucideIcons.trash2,
    );
    if (ok) ref.read(cartProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'السلة',
        actions: [
          if (!cart.isEmpty) DukaniIconAction(icon: LucideIcons.trash2, onTap: () => _clearCart(context, ref)),
        ],
      ),
      body: cart.isEmpty
          ? const DukaniEmptyState(title: 'السلة فاضية', message: 'أضف منتجات من نقطة البيع لتبدأ فاتورة جديدة', icon: LucideIcons.shoppingCart)
          : ListView(
              padding: const EdgeInsets.all(DukaniSpacing.lg),
              children: [
                DukaniCard(
                  padding: const EdgeInsets.symmetric(vertical: DukaniSpacing.sm),
                  child: Column(
                    children: [
                      for (final line in cart.lines) ...[
                        _CartLineRow(
                          line: line,
                          onIncrement: () {
                            if (!ref.read(cartProvider.notifier).incrementLine(line)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('الكمية المتوفرة من ${line.product.name} انتهت (${line.product.stock})')),
                              );
                            }
                          },
                          onDecrement: () => ref.read(cartProvider.notifier).decrementLine(line),
                          onRemove: () => ref.read(cartProvider.notifier).removeLineExact(line),
                        ),
                        if (line != cart.lines.last) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: DukaniSpacing.xl),
                DukaniTextField(
                  label: 'اسم العميل',
                  hint: 'عميل نقدي',
                  onChanged: (v) => ref.read(cartProvider.notifier).setCustomer(v.isEmpty ? null : v),
                ),
                const SizedBox(height: DukaniSpacing.lg),
                DukaniTextField(
                  label: 'ملاحظة على الفاتورة',
                  hint: 'اختياري',
                  onChanged: (v) => ref.read(cartProvider.notifier).setNote(v),
                ),
                if (_canApplyDiscount(ref)) ...[
                  const SizedBox(height: DukaniSpacing.lg),
                  Text('الخصم', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: DukaniSpacing.sm),
                  Row(
                    children: [
                      for (final d in _discountPresets) ...[
                        Expanded(
                          child: DukaniChoiceChip(
                            label: d == 0 ? 'بدون' : '${d.toStringAsFixed(0)}%',
                            selected: cart.discountPercent == d,
                            onTap: () => ref.read(cartProvider.notifier).setDiscountPercent(d),
                          ),
                        ),
                        if (d != _discountPresets.last) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: DukaniSpacing.xl),
                DukaniCard(
                  child: Column(
                    children: [
                      _SummaryRow(label: 'الإجمالي الفرعي', value: cart.subtotal),
                      if (cart.discountAmount > 0) _SummaryRow(label: 'الخصم', value: -cart.discountAmount, danger: true),
                      if (cart.taxEnabled) _SummaryRow(label: 'الضريبة (${cart.taxRatePercent.toStringAsFixed(0)}%)', value: cart.taxAmount),
                      const Divider(height: DukaniSpacing.xl),
                      _SummaryRow(label: 'الإجمالي', value: cart.total, bold: true),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.sm, DukaniSpacing.lg, DukaniSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: DukaniOutlineButton(
                        label: 'تعليق',
                        icon: LucideIcons.pauseCircle,
                        onPressed: () => _holdOrder(context, ref, cart),
                      ),
                    ),
                    const SizedBox(width: DukaniSpacing.md),
                    Expanded(
                      flex: 2,
                      child: DukaniButton(label: 'الدفع', icon: LucideIcons.wallet, onPressed: () => context.pushNamed(R.payment)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CartLineRow extends StatelessWidget {
  const _CartLineRow({required this.line, required this.onIncrement, required this.onDecrement, required this.onRemove});
  final CartLine line;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  String get _subtitle {
    final p = line.product;
    final priceText = switch (line.saleKind) {
      CartSaleKind.unit => '${(p.price + (line.variant?.priceDelta ?? 0)).toStringAsFixed(0)} ${currentCurrencySymbol()}',
      CartSaleKind.weight => '${p.pricePerKg.toStringAsFixed(2)} ${currentCurrencySymbol()}/كغم',
      CartSaleKind.pack => '${p.packPrice.toStringAsFixed(0)} ${currentCurrencySymbol()}/كرتون',
      CartSaleKind.loose => '${p.piecePrice.toStringAsFixed(2)} ${currentCurrencySymbol()}/قطعة',
    };
    return line.variant != null ? '${line.variant!.label} — $priceText' : priceText;
  }

  @override
  Widget build(BuildContext context) {
    final isWeight = line.saleKind == CartSaleKind.weight;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DukaniSpacing.md, vertical: DukaniSpacing.sm),
      child: Row(
        children: [
          DukaniProductImage(icon: line.product.icon, photoBytes: line.product.photoBytes, size: 40),
          const SizedBox(width: DukaniSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.product.name, style: Theme.of(context).textTheme.titleSmall),
                DukaniAmountText(_subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
              ],
            ),
          ),
          if (isWeight)
            DukaniAmountText(line.qtyLabel, style: Theme.of(context).textTheme.titleSmall)
          else
            Row(
              children: [
                _StepperButton(icon: LucideIcons.minus, onTap: onDecrement),
                SizedBox(width: 28, child: Center(child: DukaniAmountText('${line.qty}', style: Theme.of(context).textTheme.titleSmall))),
                _StepperButton(icon: LucideIcons.plus, onTap: onIncrement),
              ],
            ),
          const SizedBox(width: DukaniSpacing.sm),
          DukaniAmountText('${line.lineTotal.toStringAsFixed(0)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.forest700)),
          IconButton(onPressed: onRemove, icon: const Icon(LucideIcons.x, size: 16, color: DukaniColors.ink300)),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DukaniColors.forest50,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 14, color: DukaniColors.forest700)),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.bold = false, this.danger = false});
  final String label;
  final double value;
  final bool bold;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyMedium?.copyWith(color: danger ? DukaniColors.danger : DukaniColors.ink500);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          DukaniAmountText('${value < 0 ? '-' : ''}${value.abs().toStringAsFixed(2)} ${currentCurrencySymbol()}', style: style?.copyWith(color: danger ? DukaniColors.danger : (bold ? DukaniColors.forest700 : style.color))),
        ],
      ),
    );
  }
}

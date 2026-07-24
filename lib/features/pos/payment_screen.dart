import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/business/country_controller.dart';
import '../../core/offline/connectivity_service.dart';
import '../../core/offline/sync_queue.dart';
import '../../core/payments/connected_gateway_controller.dart';
import '../../core/payments/gateway_checkout_screen.dart';
import '../../core/payments/local_payment_methods.dart';
import '../../core/payments/payment_gateway.dart';
import '../../core/pos/cart_controller.dart';
import '../../core/products/products_controller.dart';
import '../../core/pos/sales_log_controller.dart';
import '../../core/printing/receipt_data.dart';
import '../../core/router/app_router.dart';
import '../../core/session/session_controller.dart';
import '../../core/store/store_profile_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One tile in the payment-method grid, or one entry in the "قريبًا"
/// preview strip — which one depends entirely on whether the merchant has
/// connected a gateway that actually processes it (see
/// [ConnectedGatewayController]). Cash and split are the only two that never
/// need a gateway: cash is physical money, split is just a checkout
/// workflow over whichever method(s) end up being used.
class _PaymentOption {
  const _PaymentOption({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}

const _cashOption = _PaymentOption(id: 'cash', label: 'نقدًا', icon: LucideIcons.wallet);
const _splitOption = _PaymentOption(id: 'split', label: 'تقسيم الدفع', icon: LucideIcons.split);
const _alwaysActiveOptions = [_cashOption];

const _gatewayDependentOptions = [
  _PaymentOption(id: 'card', label: 'بطاقة', icon: LucideIcons.creditCard),
  _PaymentOption(id: 'apple_pay', label: 'Apple Pay', icon: LucideIcons.apple),
  _PaymentOption(id: 'google_pay', label: 'Google Pay', icon: LucideIcons.smartphone),
];

bool _gatewaySupports(PaymentGatewayProvider? gateway, String countryCode, String methodId) {
  if (gateway == null) return false;
  if (!gateway.supportedCountryCodes.contains(countryCode)) return false;
  return gateway.supportedMethodIds.contains(methodId);
}

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _methodId = 'cash';
  final _tenderedController = TextEditingController();
  bool _processing = false;

  // Split payment — exactly two legs. Covers the overwhelming majority of
  // real split-tender sales ("half cash, half card") without the UI
  // complexity of an open-ended list of legs a small shop rarely needs.
  String _splitMethod1 = 'cash';
  String? _splitMethod2;
  final _splitAmount1Controller = TextEditingController();
  final _splitAmount2Controller = TextEditingController();

  @override
  void dispose() {
    _tenderedController.dispose();
    _splitAmount1Controller.dispose();
    _splitAmount2Controller.dispose();
    super.dispose();
  }

  double? get _tendered => double.tryParse(_tenderedController.text);
  double get _splitAmount1 => double.tryParse(_splitAmount1Controller.text.trim()) ?? 0;
  double get _splitAmount2 => double.tryParse(_splitAmount2Controller.text.trim()) ?? 0;

  /// The methods a split leg can actually be charged to — same gateway
  /// gating as the main grid, read fresh (not watched) since this only
  /// runs at confirm-time, not on every rebuild.
  List<_PaymentOption> _nonSplitOptions() {
    final countryCode = ref.read(countryProvider);
    final gateway = ref.read(connectedGatewayProvider)?.provider;
    final localAsOptions = localPaymentMethodsFor(countryCode).map((m) => _PaymentOption(id: m.id, label: m.label, icon: m.icon)).toList();
    final gatewayCandidates = [..._gatewayDependentOptions, ...localAsOptions];
    return [..._alwaysActiveOptions, ...gatewayCandidates.where((o) => _gatewaySupports(gateway, countryCode, o.id))];
  }

  Future<void> _confirm(CartState cart, _PaymentOption method) async {
    if (_methodId == 'cash' && (_tendered == null || _tendered! < cart.total)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المبلغ المستلم أقل من الإجمالي')));
      return;
    }
    if (_methodId == 'split' && (_splitAmount1 + _splitAmount2 - cart.total).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مجموع المبلغين لازم يساوي الإجمالي بالضبط')));
      return;
    }

    setState(() => _processing = true);

    var methodLabel = method.label;

    if (_methodId == 'split') {
      final options = _nonSplitOptions();
      String labelFor(String id) => options.firstWhere((o) => o.id == id, orElse: () => _cashOption).label;
      final resolvedMethod2 = _splitMethod2 ?? options.map((o) => o.id).firstWhere((id) => id != _splitMethod1, orElse: () => _splitMethod1);
      final legs = [(_splitMethod1, _splitAmount1), (resolvedMethod2, _splitAmount2)];
      // Cash legs need nothing further — physical money, nothing to charge.
      // Any gateway-backed leg still has to go through the real checkout,
      // one at a time, and the whole split is void if one leg fails —
      // otherwise the merchant is left having collected only part of the
      // sale with no way to represent that.
      for (final (legMethodId, legAmount) in legs) {
        if (legMethodId == 'cash' || legAmount <= 0) continue;
        final paid = await showGatewayCheckoutScreen(context, amount: legAmount, currencyCode: currentCurrencyCode(), methodId: legMethodId);
        if (!mounted) return;
        if (!paid) {
          setState(() => _processing = false);
          return;
        }
      }
      methodLabel = legs.where((l) => l.$2 > 0).map((l) => '${labelFor(l.$1)} (${l.$2.toStringAsFixed(2)})').join(' + ');
    } else if (_methodId == 'cash') {
      await Future.delayed(const Duration(milliseconds: 900));
    } else {
      final paid = await showGatewayCheckoutScreen(
        context,
        amount: cart.total,
        currencyCode: currentCurrencyCode(),
        methodId: _methodId,
      );
      if (!mounted) return;
      if (!paid) {
        setState(() => _processing = false);
        return;
      }
    }
    if (!mounted) return;

    final invoiceId = 'INV-${1000 + Random().nextInt(8999)}';
    final online = await checkIsOnline();
    ref.read(syncQueueProvider.notifier).enqueue('sale', {
      'invoiceId': invoiceId,
      'total': cart.total,
      'itemCount': cart.itemCount,
      'method': methodLabel,
    });
    if (online) ref.read(syncQueueProvider.notifier).flush();

    final productsNotifier = ref.read(productsProvider.notifier);
    for (final line in cart.lines) {
      switch (line.saleKind) {
        case CartSaleKind.unit:
          if (line.variant != null) {
            productsNotifier.adjustVariantStock(line.product.id, line.variant!.id, -line.qty);
          } else {
            productsNotifier.adjustStock(line.product.id, -line.qty);
          }
        case CartSaleKind.weight:
          productsNotifier.sellWeight(line.product.id, line.weightKg ?? 0);
        case CartSaleKind.pack:
          productsNotifier.sellPacks(line.product.id, line.qty);
        case CartSaleKind.loose:
          productsNotifier.sellLoose(line.product.id, line.qty);
      }
    }

    final storeProfile = ref.read(storeProfileProvider).valueOrNull;
    final cashierName = ref.read(sessionProvider)?.name ?? storeProfile?.ownerName;

    ref.read(salesLogProvider.notifier).record(
          SaleRecord(
            id: invoiceId,
            lines: [
              for (final l in cart.lines)
                SaleLine(
                  productId: l.product.id,
                  productName: l.product.name + (l.variant != null ? ' — ${l.variant!.label}' : ''),
                  qty: l.saleKind == CartSaleKind.weight ? 1 : l.qty,
                  // Per-kg/per-pack/per-piece cost isn't tracked separately from
                  // the each-mode unit cost, so profit for those sale kinds is
                  // reported as full revenue rather than a fabricated margin.
                  price: switch (l.saleKind) {
                    CartSaleKind.unit => l.product.price + (l.variant?.priceDelta ?? 0),
                    CartSaleKind.weight => l.lineTotal,
                    CartSaleKind.pack => l.product.packPrice,
                    CartSaleKind.loose => l.product.piecePrice,
                  },
                  cost: l.saleKind == CartSaleKind.unit ? l.product.cost : 0,
                ),
            ],
            total: cart.total,
            methodLabel: methodLabel,
            createdAt: DateTime.now(),
            customerName: cart.customerName,
            cashierName: cashierName,
            taxAmount: cart.taxAmount,
            discountAmount: cart.discountAmount,
          ),
        );

    final change = _methodId == 'cash' ? (_tendered! - cart.total) : 0.0;
    final receipt = ReceiptData(
      invoiceId: invoiceId,
      createdAt: DateTime.now(),
      storeName: storeProfile?.storeName.trim().isNotEmpty == true ? storeProfile!.storeName : 'دُكّاني',
      cashierName: storeProfile?.ownerName,
      lines: [
        for (final l in cart.lines)
          ReceiptLine(
            name: l.product.name + (l.variant != null ? ' — ${[l.variant!.size, l.variant!.color].where((s) => s.isNotEmpty).join(' / ')}' : ''),
            qtyLabel: l.qtyLabel,
            unitPrice: l.lineTotal / (l.saleKind == CartSaleKind.weight ? 1 : l.qty),
            lineTotal: l.lineTotal,
          ),
      ],
      subtotal: cart.subtotal,
      discountPercent: cart.discountPercent,
      discountAmount: cart.discountAmount,
      taxRate: cart.taxRatePercent,
      taxAmount: cart.taxAmount,
      total: cart.total,
      methodLabel: methodLabel,
      currencySymbol: currentCurrencySymbol(),
      tendered: _methodId == 'cash' ? _tendered : null,
      change: change > 0 ? change : null,
    );

    ref.read(cartProvider.notifier).clear();

    if (!mounted) return;
    context.pushReplacementNamed(
      R.saleSuccess,
      extra: SaleSuccessArgs(
        invoiceId: invoiceId,
        total: cart.total,
        itemCount: cart.itemCount,
        methodLabel: methodLabel,
        change: change,
        receipt: receipt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final change = _tendered != null ? _tendered! - cart.total : null;
    final countryCode = ref.watch(countryProvider);
    final gateway = ref.watch(connectedGatewayProvider)?.provider;

    final localAsOptions = localPaymentMethodsFor(countryCode).map((m) => _PaymentOption(id: m.id, label: m.label, icon: m.icon)).toList();
    final gatewayCandidates = [..._gatewayDependentOptions, ...localAsOptions];
    final nonSplitOptions = [..._alwaysActiveOptions, ...gatewayCandidates.where((o) => _gatewaySupports(gateway, countryCode, o.id))];
    final comingSoonOptions = gatewayCandidates.where((o) => !_gatewaySupports(gateway, countryCode, o.id)).toList();
    // Splitting a sale only makes sense with two genuinely different ways
    // to pay — a cash-only shop with no gateway connected has nothing to
    // split between, so the tile doesn't even show up for them.
    final canSplit = nonSplitOptions.length >= 2;
    final activeOptions = [...nonSplitOptions, if (canSplit) _splitOption];
    final otherOptions = nonSplitOptions.where((o) => o.id != _splitMethod1).toList();
    final splitMethod2 = _splitMethod2 ?? (otherOptions.isEmpty ? null : otherOptions.first.id);

    final selected = activeOptions.firstWhere((o) => o.id == _methodId, orElse: () => activeOptions.first);

    return Scaffold(
      appBar: DukaniAppBar(title: 'الدفع'),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          DukaniCard(
            color: DukaniColors.forest700,
            child: Column(
              children: [
                Text('الإجمالي المطلوب', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                const SizedBox(height: 6),
                DukaniAmountText('${cart.total.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          Text('طريقة الدفع', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: DukaniSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: DukaniSpacing.md,
            crossAxisSpacing: DukaniSpacing.md,
            childAspectRatio: 1.6,
            children: [
              for (final o in activeOptions) _MethodTile(option: o, selected: _methodId == o.id, onTap: () => setState(() => _methodId = o.id)),
            ],
          ),
          if (comingSoonOptions.isNotEmpty) ...[
            const SizedBox(height: DukaniSpacing.xl),
            _ComingSoonStrip(methods: comingSoonOptions),
          ],
          if (_methodId == 'cash') ...[
            const SizedBox(height: DukaniSpacing.xl),
            DukaniTextField(
              label: 'المبلغ المستلم',
              hint: '0.00',
              controller: _tenderedController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              prefixIcon: LucideIcons.wallet,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: DukaniSpacing.md),
            Row(
              children: [
                for (final amount in _quickAmounts(cart.total)) ...[
                  Expanded(
                    child: DukaniChoiceChip(
                      label: amount == cart.total ? 'المبلغ بالضبط' : amount.toStringAsFixed(0),
                      selected: _tendered == amount,
                      onTap: () => setState(() => _tenderedController.text = amount.toStringAsFixed(2)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            if (change != null) ...[
              const SizedBox(height: DukaniSpacing.lg),
              DukaniCard(
                color: change >= 0 ? DukaniColors.successBg : DukaniColors.dangerBg,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(change >= 0 ? 'المتبقي للعميل' : 'مبلغ غير كافٍ', style: Theme.of(context).textTheme.titleSmall),
                    DukaniAmountText(
                      '${change.abs().toStringAsFixed(2)} ${currentCurrencySymbol()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: change >= 0 ? DukaniColors.success : DukaniColors.danger, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
          if (_methodId == 'split') ...[
            const SizedBox(height: DukaniSpacing.xl),
            Text('الطريقة الأولى', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: DukaniSpacing.sm),
            _SplitLegField(
              options: nonSplitOptions,
              selectedId: _splitMethod1,
              controller: _splitAmount1Controller,
              onMethodChanged: (id) => setState(() {
                _splitMethod1 = id;
                if (_splitMethod2 == id) _splitMethod2 = null;
              }),
              onAmountChanged: () => setState(() {}),
            ),
            const SizedBox(height: DukaniSpacing.lg),
            Text('الطريقة الثانية', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: DukaniSpacing.sm),
            _SplitLegField(
              options: nonSplitOptions.where((o) => o.id != _splitMethod1).toList(),
              selectedId: splitMethod2,
              controller: _splitAmount2Controller,
              onMethodChanged: (id) => setState(() => _splitMethod2 = id),
              onAmountChanged: () => setState(() {}),
            ),
            const SizedBox(height: DukaniSpacing.lg),
            DukaniCard(
              color: (_splitAmount1 + _splitAmount2 - cart.total).abs() <= 0.01 ? DukaniColors.successBg : DukaniColors.dangerBg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('مجموع المبلغين', style: Theme.of(context).textTheme.titleSmall),
                  DukaniAmountText(
                    '${(_splitAmount1 + _splitAmount2).toStringAsFixed(2)} / ${cart.total.toStringAsFixed(2)} ${currentCurrencySymbol()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: (_splitAmount1 + _splitAmount2 - cart.total).abs() <= 0.01 ? DukaniColors.success : DukaniColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DukaniSpacing.lg),
          child: DukaniButton(
            label: 'تأكيد الدفع',
            icon: LucideIcons.checkCircle2,
            loading: _processing,
            onPressed: cart.isEmpty ? null : () => _confirm(cart, selected),
          ),
        ),
      ),
    );
  }
}

/// One leg of a split payment — a horizontal row of method chips plus the
/// amount going to whichever one is selected.
class _SplitLegField extends StatelessWidget {
  const _SplitLegField({
    required this.options,
    required this.selectedId,
    required this.controller,
    required this.onMethodChanged,
    required this.onAmountChanged,
  });

  final List<_PaymentOption> options;
  final String? selectedId;
  final TextEditingController controller;
  final ValueChanged<String> onMethodChanged;
  final VoidCallback onAmountChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              DukaniChoiceChip(label: o.label, selected: o.id == selectedId, onTap: () => onMethodChanged(o.id)),
          ],
        ),
        const SizedBox(height: DukaniSpacing.sm),
        DukaniTextField(
          hint: '0.00',
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => onAmountChanged(),
          prefixIcon: LucideIcons.wallet,
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.option, required this.selected, required this.onTap});
  final _PaymentOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DukaniCard(
      onTap: onTap,
      border: selected ? DukaniColors.forest600 : null,
      color: selected ? DukaniColors.forest50 : null,
      padding: const EdgeInsets.symmetric(horizontal: DukaniSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(option.icon, size: 20, color: selected ? DukaniColors.forest700 : DukaniColors.ink500),
          const SizedBox(width: 8),
          Text(option.label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: selected ? DukaniColors.forest700 : null)),
        ],
      ),
    );
  }
}

/// A quiet, non-selectable preview of whichever methods aren't live yet —
/// kept visually and functionally separate from the working [_MethodTile]
/// grid above so it never looks like a tappable option or crowds the real
/// ones. What lands here shrinks automatically as the merchant connects a
/// gateway that covers more of these (see [ConnectedGatewayController]).
class _ComingSoonStrip extends StatelessWidget {
  const _ComingSoonStrip({required this.methods});
  final List<_PaymentOption> methods;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('طرق دفع إضافية', style: textTheme.titleSmall?.copyWith(color: DukaniColors.ink500)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: DukaniColors.warningBg, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
              child: Text('قريبًا', style: textTheme.labelSmall?.copyWith(color: DukaniColors.warning, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('هتتفعل تلقائيًا لما تربط بوابة دفع من الإعدادات', style: textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
        const SizedBox(height: DukaniSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in methods)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: DukaniColors.paperDim,
                  borderRadius: BorderRadius.circular(DukaniRadii.pill),
                  border: Border.all(color: DukaniColors.ink100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(m.icon, size: 16, color: DukaniColors.ink500),
                    const SizedBox(width: 6),
                    Text(m.label, style: textTheme.labelMedium?.copyWith(color: DukaniColors.ink500)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

List<double> _quickAmounts(double total) {
  final amounts = <double>{total, (total / 10).ceil() * 10, (total / 50).ceil() * 50, (total / 100).ceil() * 100};
  return amounts.toList();
}

class SaleSuccessArgs {
  const SaleSuccessArgs({
    required this.invoiceId,
    required this.total,
    required this.itemCount,
    required this.methodLabel,
    required this.change,
    required this.receipt,
  });
  final String invoiceId;
  final double total;
  final int itemCount;
  final String methodLabel;
  final double change;
  final ReceiptData receipt;
}

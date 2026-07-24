import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/branches/branches_controller.dart';
import '../../core/products/products_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/transfers/transfers_controller.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum _Step { fromBranch, toBranch, items, pickProduct }

class TransferNewScreen extends ConsumerStatefulWidget {
  const TransferNewScreen({super.key});

  @override
  ConsumerState<TransferNewScreen> createState() => _TransferNewScreenState();
}

class _TransferNewScreenState extends ConsumerState<TransferNewScreen> {
  MockBranch? _from;
  MockBranch? _to;
  _Step _step = _Step.fromBranch;
  final List<TransferItem> _items = [];

  void _pickQty(MockProduct product) {
    setState(() => _step = _Step.items);
    final qtyController = TextEditingController(text: '1');

    showDukaniSheet(
      context,
      title: product.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DukaniTextField(label: 'الكمية المنقولة', controller: qtyController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, autofocus: true),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(
            label: 'إضافة',
            onPressed: () {
              final qty = int.tryParse(qtyController.text.trim());
              if (qty == null || qty <= 0) return;
              setState(() => _items.add(TransferItem(productId: product.id, productName: product.name, qty: qty)));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirm() {
    if (_from == null || _to == null || _items.isEmpty) return;
    ref.read(transfersProvider.notifier).create(MockBranchTransfer(
          id: 'tr${DateTime.now().microsecondsSinceEpoch}',
          fromBranchId: _from!.id,
          fromBranchName: _from!.name,
          toBranchId: _to!.id,
          toBranchName: _to!.name,
          items: _items,
          date: 'اليوم',
        ));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case _Step.fromBranch:
        return Scaffold(appBar: const DukaniAppBar(title: 'نقل من فرع'), body: _buildBranchPicker((b) => setState(() {
                _from = b;
                _step = _Step.toBranch;
              })));
      case _Step.toBranch:
        return Scaffold(
          appBar: DukaniAppBar(title: 'نقل إلى فرع', leading: DukaniIconAction(icon: LucideIcons.arrowLeft, onTap: () => setState(() => _step = _Step.fromBranch))),
          body: _buildBranchPicker((b) => setState(() {
                _to = b;
                _step = _Step.items;
              }), exclude: _from?.id),
        );
      case _Step.pickProduct:
        return Scaffold(
          appBar: DukaniAppBar(title: 'اختر منتجًا', leading: DukaniIconAction(icon: LucideIcons.x, onTap: () => setState(() => _step = _Step.items))),
          body: _buildProductPicker(),
        );
      case _Step.items:
        return Scaffold(
          appBar: DukaniAppBar(title: '${_from!.name} ← ${_to!.name}'),
          body: _buildItemsForm(),
        );
    }
  }

  Widget _buildBranchPicker(ValueChanged<MockBranch> onPick, {String? exclude}) {
    final branches = ref.watch(branchesProvider).where((b) => b.id != exclude).toList();
    return ListView.separated(
      padding: const EdgeInsets.all(DukaniSpacing.lg),
      itemCount: branches.length,
      separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
      itemBuilder: (context, i) {
        final b = branches[i];
        return DukaniCard(
          onTap: () => onPick(b),
          child: Row(
            children: [
              const Icon(LucideIcons.store, color: DukaniColors.forest600),
              const SizedBox(width: DukaniSpacing.md),
              Expanded(child: Text(b.name, style: Theme.of(context).textTheme.titleSmall)),
              const Icon(LucideIcons.chevronLeft, color: DukaniColors.ink300),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductPicker() {
    final catalog = ref.watch(productsProvider);
    return ListView.separated(
      padding: const EdgeInsets.all(DukaniSpacing.lg),
      itemCount: catalog.length,
      separatorBuilder: (_, __) => const SizedBox(height: DukaniSpacing.md),
      itemBuilder: (context, i) {
        final p = catalog[i];
        return DukaniCard(
          onTap: () => _pickQty(p),
          child: Row(
            children: [
              DukaniProductImage(icon: p.icon, photoBytes: p.photoBytes, size: 32),
              const SizedBox(width: DukaniSpacing.md),
              Expanded(child: Text(p.name, style: Theme.of(context).textTheme.titleSmall)),
              Text('مخزون ${p.stock}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemsForm() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(DukaniSpacing.lg),
            children: [
              if (_items.isEmpty)
                const DukaniEmptyState(title: 'لم تُضف منتجات بعد', icon: LucideIcons.arrowLeftRight)
              else
                for (final item in _items) ...[
                  DukaniCard(
                    child: Row(
                      children: [
                        Expanded(child: Text(item.productName, style: Theme.of(context).textTheme.titleSmall)),
                        DukaniAmountText('${item.qty}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.forest700)),
                        IconButton(onPressed: () => setState(() => _items.remove(item)), icon: const Icon(LucideIcons.x, size: 16, color: DukaniColors.ink300)),
                      ],
                    ),
                  ),
                  const SizedBox(height: DukaniSpacing.md),
                ],
              DukaniOutlineButton(label: 'إضافة منتج', icon: LucideIcons.plus, onPressed: () => setState(() => _step = _Step.pickProduct)),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DukaniSpacing.lg),
            child: DukaniButton(label: 'إنشاء طلب التحويل', icon: LucideIcons.arrowLeftRight, onPressed: _items.isEmpty ? null : _confirm),
          ),
        ),
      ],
    );
  }
}

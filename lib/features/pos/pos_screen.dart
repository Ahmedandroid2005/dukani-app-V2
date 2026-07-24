import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/dukani_countries.dart';
import '../../core/offline/connectivity_service.dart';
import '../../core/pos/cart_controller.dart';
import '../../core/products/categories_controller.dart';
import '../../core/products/products_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/scanning/barcode_scanner_sheet.dart';
import '../../core/session/session_controller.dart';
import '../../core/store/store_profile_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Column count scales with available width so the grid stays comfortable
/// on a phone, a tablet held either way, or a large POS display/monitor —
/// instead of always cramming everything into 2 columns.
int _posGridColumns(double width) {
  if (width >= 1500) return 7;
  if (width >= 1150) return 6;
  if (width >= 820) return 5;
  if (width >= 560) return 4;
  return 3;
}

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String _query = '';
  String _category = 'الكل';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// A cashier lives on this screen all shift and has no other obvious way
  /// off it (no back arrow, no settings access) — a store owner already has
  /// the Profile menu for this, so it's only surfaced for non-owner sessions.
  Future<void> _exitSession() async {
    final ok = await DukaniConfirmDialog.show(
      context,
      title: 'الخروج من الوردية؟',
      message: 'سيتم إنهاء جلستك الحالية وستحتاج لتسجيل الدخول مجددًا للعودة لنقطة البيع.',
      confirmLabel: 'تسجيل الخروج',
      destructive: true,
      icon: LucideIcons.logOut,
    );
    if (!ok || !mounted) return;
    ref.read(sessionProvider.notifier).logout();
    if (!mounted) return;
    context.goNamed(R.login);
  }

  /// A hardware barcode scanner types the code into whatever field has
  /// focus and finishes with Enter — this is that Enter handler. An exact
  /// barcode match adds straight to the cart (a real cashier scan should
  /// never need a follow-up tap); anything else is just the merchant typing
  /// a product name and hitting Enter, so it's left as a plain search.
  void _handleSearchSubmit(String text) {
    final code = text.trim();
    if (code.isEmpty) return;
    final matches = ref.read(productsProvider).where((p) => p.barcode == code).toList();
    if (matches.isEmpty) return;
    final added = ref.read(cartProvider.notifier).addProduct(matches.first);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added ? 'أُضيف ${matches.first.name} للسلة' : 'الكمية المتوفرة من ${matches.first.name} انتهت (${matches.first.stock})'),
    ));
    _searchController.clear();
    setState(() => _query = '');
  }

  /// Sums every unit-mode line for this product — a variant-tracked
  /// product can occupy several cart lines at once (one per size/color), so
  /// the grid badge has to add them up rather than surface just the first
  /// match.
  int _qtyFor(CartState cart, String productId) {
    var total = 0;
    for (final line in cart.lines) {
      if (line.product.id == productId && line.saleKind == CartSaleKind.unit) total += line.qty;
    }
    return total;
  }

  /// Weight-sold and bulk-container products: open a sheet to key in a
  /// weight rather than adding a flat +1, since the sale is priced per kg.
  void _openWeightSheet(MockProduct product) {
    final controller = TextEditingController();
    final availableKg = product.unitMode == ProductUnitMode.bulkContainer
        ? product.openStockKg + product.stock * product.containerSizeKg
        : product.openStockKg;

    showDukaniSheet(
      context,
      title: 'بيع بالوزن — ${product.name}',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final kg = double.tryParse(controller.text.trim());
          final total = kg == null ? null : kg * product.pricePerKg;
          final valid = kg != null && kg > 0 && kg <= availableKg;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Two separate decimal numbers in one Arabic sentence —
                  // each must be its own widget starting with the digit, or
                  // the bidi algorithm swaps digit groups around the "."
                  // even past a dash (see MockProductDisplay.stockSummary).
                  DukaniAmountText('${product.pricePerKg.toStringAsFixed(2)} ${currentCurrencySymbol()}/كغم', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
                  Text(' — ', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
                  DukaniAmountText('${availableKg.toStringAsFixed(2)} كغم متوفرة', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
                ],
              ),
              const SizedBox(height: DukaniSpacing.lg),
              DukaniTextField(
                label: 'الوزن (كغم)',
                hint: '0.500',
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textDirection: TextDirection.ltr,
                autofocus: true,
                onChanged: (_) => setSheetState(() {}),
              ),
              const SizedBox(height: DukaniSpacing.sm),
              Wrap(
                spacing: 8,
                children: [
                  // Grams for the sub-kilo presets keeps every chip label a
                  // plain integer — a decimal point mixed into Arabic text
                  // gets visually reordered by the bidi algorithm otherwise
                  // (e.g. "0.25" rendering as "52.0").
                  for (final preset in [0.25, 0.5, 1.0, 2.0])
                    DukaniChoiceChip(
                      label: preset < 1 ? '${(preset * 1000).toInt()}غم' : '${preset.toInt()}كغم',
                      selected: kg == preset,
                      onTap: () {
                        controller.text = preset.toString();
                        setSheetState(() {});
                      },
                    ),
                ],
              ),
              if (total != null) ...[
                const SizedBox(height: DukaniSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('الإجمالي: ', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: DukaniColors.forest700)),
                    DukaniAmountText('${total.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: DukaniColors.forest700)),
                  ],
                ),
              ],
              const SizedBox(height: DukaniSpacing.xl),
              DukaniButton(
                label: 'إضافة للسلة',
                icon: LucideIcons.shoppingCart,
                onPressed: valid
                    ? () {
                        ref.read(cartProvider.notifier).addWeighedProduct(product, kg);
                        Navigator.pop(context);
                      }
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Multi-pack products: sealed pack and loose piece are priced (and
  /// tracked) separately, so the cashier picks how much of each to sell.
  void _openPackSheet(MockProduct product) {
    final packController = TextEditingController();
    final looseController = TextEditingController();

    showDukaniSheet(
      context,
      title: 'بيع — ${product.name}',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final packs = int.tryParse(packController.text.trim()) ?? 0;
          final loose = int.tryParse(looseController.text.trim()) ?? 0;
          final total = packs * product.packPrice + loose * product.piecePrice;
          final maxLoose = product.looseUnits + (product.stock - packs).clamp(0, product.stock) * product.packSize;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('كرتون كامل (${product.packSize} قطعة)', style: Theme.of(context).textTheme.titleSmall),
              DukaniAmountText(
                '${product.packPrice.toStringAsFixed(2)} ${currentCurrencySymbol()} — متوفر: ${product.stock} كرتون',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500),
              ),
              const SizedBox(height: DukaniSpacing.sm),
              DukaniTextField(hint: '0', controller: packController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, onChanged: (_) => setSheetState(() {})),
              const SizedBox(height: DukaniSpacing.lg),
              Text('بالفرط', style: Theme.of(context).textTheme.titleSmall),
              DukaniAmountText(
                '${product.piecePrice.toStringAsFixed(2)} ${currentCurrencySymbol()}/قطعة — متوفر بالفرط: ${product.looseUnits} (وتُفتح كراتين تلقائيًا عند الحاجة)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500),
              ),
              const SizedBox(height: DukaniSpacing.sm),
              DukaniTextField(hint: '0', controller: looseController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr, onChanged: (_) => setSheetState(() {})),
              if (packs > 0 || loose > 0) ...[
                const SizedBox(height: DukaniSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('الإجمالي: ', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: DukaniColors.forest700)),
                    DukaniAmountText('${total.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: DukaniColors.forest700)),
                  ],
                ),
              ],
              const SizedBox(height: DukaniSpacing.xl),
              DukaniButton(
                label: 'إضافة للسلة',
                icon: LucideIcons.shoppingCart,
                onPressed: (packs <= 0 && loose <= 0) || packs > product.stock || loose > maxLoose
                    ? null
                    : () {
                        if (packs > 0) ref.read(cartProvider.notifier).addPacks(product, packs);
                        if (loose > 0) ref.read(cartProvider.notifier).addLoose(product, loose);
                        Navigator.pop(context);
                      },
              ),
            ],
          );
        },
      ),
    );
  }

  /// Variant-tracked products (size/color — clothing, shoes...): pick the
  /// exact size/color before it can go in the cart, since each one draws
  /// from its own stock count and the wrong one can't just be "close enough".
  void _openVariantSheet(MockProduct product) {
    showDukaniSheet(
      context,
      title: 'اختر المقاس / اللون — ${product.name}',
      child: Consumer(
        builder: (context, ref, _) {
          final cart = ref.watch(cartProvider);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final variant in product.variants) ...[
                _VariantSheetRow(
                  variant: variant,
                  qtyInCart: cart.lines.where((l) => l.product.id == product.id && l.variant?.id == variant.id).fold(0, (s, l) => s + l.qty),
                  onAdd: variant.stock <= 0 ? null : () => ref.read(cartProvider.notifier).addVariant(product, variant),
                ),
                if (variant != product.variants.last) const Divider(height: 1),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Looks a scanned/typed code up in the catalog and adds it to the cart —
  /// [CartController.addProduct] already merges into the existing line when
  /// the same product is scanned twice, so a repeat scan just bumps the qty.
  void _addByBarcode(String code) {
    final matches = ref.read(productsProvider).where((p) => p.barcode == code).toList();
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يتم العثور على منتج بهذا الباركود')));
    } else {
      final added = ref.read(cartProvider.notifier).addProduct(matches.first);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added ? 'أُضيف ${matches.first.name} للسلة' : 'الكمية المتوفرة من ${matches.first.name} انتهت (${matches.first.stock})'),
      ));
    }
  }

  void _scanBarcode() {
    final controller = TextEditingController();
    showDukaniSheet(
      context,
      title: 'إدخال الباركود',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DukaniTextField(
            hint: 'أدخل الرقم يدويًا أو استخدم جهاز المسح',
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            prefixIcon: LucideIcons.scanLine,
            textDirection: TextDirection.ltr,
            // HID scanners emulate typing + Enter, so a scan here submits
            // itself without the cashier touching the button.
            onSubmitted: (code) {
              Navigator.pop(context);
              _addByBarcode(code.trim());
            },
          ),
          const SizedBox(height: DukaniSpacing.md),
          DukaniOutlineButton(
            label: 'مسح بالكاميرا',
            icon: LucideIcons.camera,
            onPressed: () async {
              Navigator.pop(context);
              final code = await showBarcodeScannerScreen(context);
              if (code != null) _addByBarcode(code);
            },
          ),
          const SizedBox(height: DukaniSpacing.md),
          DukaniButton(
            label: 'إضافة للسلة',
            icon: LucideIcons.shoppingCart,
            onPressed: () {
              final code = controller.text.trim();
              Navigator.pop(context);
              _addByBarcode(code);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final heldOrders = ref.watch(heldOrdersProvider);
    final catalog = ref.watch(productsProvider);
    final categories = ['الكل', ...ref.watch(categoriesProvider)];
    final session = ref.watch(sessionProvider);
    final isCashier = session != null && session.role != 'مالك';

    // The cart itself carries `taxEnabled`/`taxRatePercent` (see CartState)
    // so every total and receipt computed from it honors what the merchant
    // actually set up — country VAT rate included, never a fixed 15% for
    // every merchant regardless of where they operate — kept in sync
    // whenever the store profile loads or changes, without every call site
    // re-reading it separately.
    ref.listen(storeProfileProvider, (_, next) {
      final profile = next.valueOrNull;
      ref.read(cartProvider.notifier).setTaxEnabled(profile?.taxEnabled ?? true);
      final country = dukaniCountries.firstWhere((c) => c.code == profile?.countryCode, orElse: () => dukaniCountries.first);
      ref.read(cartProvider.notifier).setTaxRatePercent(country.defaultTaxRate);
    });
    final loadedProfile = ref.watch(storeProfileProvider).valueOrNull;
    final loadedCountry = dukaniCountries.firstWhere((c) => c.code == loadedProfile?.countryCode, orElse: () => dukaniCountries.first);
    if (loadedProfile != null && (loadedProfile.taxEnabled != cart.taxEnabled || loadedCountry.defaultTaxRate != cart.taxRatePercent)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(cartProvider.notifier).setTaxEnabled(loadedProfile.taxEnabled);
        ref.read(cartProvider.notifier).setTaxRatePercent(loadedCountry.defaultTaxRate);
      });
    }

    final products = catalog.where((p) {
      final matchesCategory = _category == 'الكل' || p.category == _category;
      final matchesQuery = _query.isEmpty || p.name.contains(_query) || p.barcode.contains(_query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: DukaniAppBar(
        title: 'نقطة البيع',
        actions: [
          DukaniIconAction(icon: LucideIcons.clock, onTap: () => context.pushNamed(R.shift)),
          DukaniIconAction(
            icon: LucideIcons.receipt,
            dotted: heldOrders.isNotEmpty,
            onTap: () => context.pushNamed(R.heldOrders),
          ),
          DukaniIconAction(icon: LucideIcons.scanLine, onTap: _scanBarcode),
          if (isCashier) DukaniIconAction(icon: LucideIcons.logOut, onTap: _exitSession),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.sm, DukaniSpacing.lg, DukaniSpacing.sm),
            child: Row(
              children: [
                Consumer(
                  builder: (context, ref, _) {
                    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isOnline ? DukaniColors.successBg : DukaniColors.dangerBg,
                        borderRadius: BorderRadius.circular(DukaniRadii.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: isOnline ? DukaniColors.success : DukaniColors.danger),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOnline ? 'متصل' : 'غير متصل',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isOnline ? DukaniColors.success : DukaniColors.danger),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, 0, DukaniSpacing.lg, DukaniSpacing.md),
            child: Row(
              children: [
                Material(
                  color: DukaniColors.forest700,
                  borderRadius: BorderRadius.circular(DukaniRadii.md),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(DukaniRadii.md),
                    onTap: () async {
                      final code = await showBarcodeScannerScreen(context);
                      if (code != null) _addByBarcode(code);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Icon(LucideIcons.camera, color: Colors.white, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: DukaniSpacing.sm),
                Expanded(
                  child: DukaniSearchField(
                    hint: 'بحث بالاسم أو الباركود',
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    onSubmitted: _handleSearchSubmit,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: DukaniSpacing.lg),
              children: [
                for (final c in categories) ...[
                  DukaniChoiceChip(label: c, selected: c == _category, onTap: () => setState(() => _category = c)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.md),
          Expanded(
            child: products.isEmpty
                ? const DukaniEmptyState(title: 'لا توجد منتجات', message: 'جرّب كلمة بحث أخرى أو فئة مختلفة', icon: LucideIcons.searchX)
                : GridView.builder(
                    padding: EdgeInsets.fromLTRB(DukaniSpacing.lg, 0, DukaniSpacing.lg, cart.isEmpty ? DukaniSpacing.lg : 110),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _posGridColumns(MediaQuery.of(context).size.width),
                      mainAxisSpacing: DukaniSpacing.md,
                      crossAxisSpacing: DukaniSpacing.md,
                      // The photo/icon now fills the card's full width as a
                      // square (see _ProductCard), so the card needs to run
                      // noticeably taller than wide to leave room for the
                      // name, stock, and price lines below it without
                      // clipping — a plain squarish ratio cuts the price off.
                      childAspectRatio: 0.62,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, i) {
                      final product = products[i];
                      final qty = _qtyFor(cart, product.id);
                      return _ProductCard(
                        product: product,
                        qty: qty,
                        onAdd: () {
                          switch (product.unitMode) {
                            case ProductUnitMode.each:
                              if (product.hasVariants) {
                                _openVariantSheet(product);
                              } else if (!ref.read(cartProvider.notifier).addProduct(product)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('الكمية المتوفرة من ${product.name} انتهت (${product.stock})')),
                                );
                              }
                            case ProductUnitMode.weight:
                            case ProductUnitMode.bulkContainer:
                              _openWeightSheet(product);
                            case ProductUnitMode.multiPack:
                              _openPackSheet(product);
                          }
                        },
                        onRemove: () => ref.read(cartProvider.notifier).decrement(product.id),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(DukaniSpacing.lg, DukaniSpacing.sm, DukaniSpacing.lg, DukaniSpacing.lg),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(DukaniRadii.md),
                    onTap: () => context.pushNamed(R.cart),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: DukaniSpacing.lg),
                      decoration: BoxDecoration(color: DukaniColors.forest700, borderRadius: BorderRadius.circular(DukaniRadii.md)),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
                            child: DukaniAmountText('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: DukaniSpacing.md),
                          Text('عرض السلة', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
                          const Spacer(),
                          DukaniAmountText('${cart.total.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          const Icon(LucideIcons.chevronLeft, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.qty, required this.onAdd, required this.onRemove});
  final MockProduct product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final inCart = qty > 0;
    return DukaniCard(
      onTap: onAdd,
      padding: const EdgeInsets.all(DukaniSpacing.md),
      border: inCart ? DukaniColors.forest500 : null,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fill the card's full width as a square so the photo/icon
              // stays proportionate no matter how many columns the
              // responsive grid is currently showing.
              LayoutBuilder(
                builder: (context, constraints) => DukaniProductImage(
                  icon: product.icon,
                  photoBytes: product.photoBytes,
                  size: constraints.maxWidth,
                ),
              ),
              const SizedBox(height: DukaniSpacing.sm),
              Text(product.name, style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              DukaniAmountText(product.stockSummary, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
              const Spacer(),
              DukaniAmountText(product.priceSummary, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: DukaniColors.forest700)),
            ],
          ),
          if (inCart)
            Positioned(
              top: 0,
              left: 0,
              child: Row(
                children: [
                  _RoundIconButton(icon: LucideIcons.minus, onTap: onRemove),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: DukaniColors.forest700, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
                    child: DukaniAmountText('$qty', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DukaniColors.dangerBg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 14, color: DukaniColors.danger)),
      ),
    );
  }
}

class _VariantSheetRow extends StatelessWidget {
  const _VariantSheetRow({required this.variant, required this.qtyInCart, required this.onAdd});
  final MockProductVariant variant;
  final int qtyInCart;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final outOfStock = variant.stock <= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DukaniSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(variant.label, style: Theme.of(context).textTheme.titleSmall),
                DukaniAmountText(
                  outOfStock ? 'نفدت الكمية' : 'متوفر: ${variant.stock}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: outOfStock ? DukaniColors.danger : DukaniColors.ink500),
                ),
              ],
            ),
          ),
          if (variant.priceDelta != 0)
            DukaniAmountText(
              '${variant.priceDelta > 0 ? '+' : ''}${variant.priceDelta.toStringAsFixed(0)} ${currentCurrencySymbol()}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500),
            ),
          const SizedBox(width: DukaniSpacing.sm),
          if (qtyInCart > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: DukaniColors.forest700, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
              child: DukaniAmountText('$qtyInCart', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: DukaniSpacing.sm),
          ],
          Material(
            color: onAdd == null ? DukaniColors.ink100 : DukaniColors.forest50,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onAdd,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(LucideIcons.plus, size: 20, color: onAdd == null ? DukaniColors.ink300 : DukaniColors.forest700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

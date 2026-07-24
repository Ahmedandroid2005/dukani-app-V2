import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_models.dart';
import '../business/currency.dart';
import '../offline/local_db.dart';
import '../offline/persisted_list_notifier.dart';
import '../offline/settings_controller.dart';

/// How a single cart line was rung up — mirrors [ProductUnitMode] but at
/// the point of sale, since a multi-pack product can be sold both ways
/// (sealed pack and loose piece) in the very same cart.
enum CartSaleKind { unit, weight, pack, loose }

class CartLine {
  const CartLine({required this.product, required this.qty, this.saleKind = CartSaleKind.unit, this.weightKg, this.variant});

  final MockProduct product;
  /// Whole-count quantity — for [CartSaleKind.weight] this is always 1 and
  /// [weightKg] carries the actual amount sold instead.
  final int qty;
  final CartSaleKind saleKind;
  final double? weightKg;
  /// Set only when [product] is variant-tracked (size/color) — which exact
  /// size/color this line is, so payment deducts stock from that variant
  /// and not the product's (unused, in that case) base stock count.
  final MockProductVariant? variant;

  double get _unitPrice => switch (saleKind) {
        CartSaleKind.unit => product.price + (variant?.priceDelta ?? 0),
        CartSaleKind.weight => product.pricePerKg,
        CartSaleKind.pack => product.packPrice,
        CartSaleKind.loose => product.piecePrice,
      };

  double get lineTotal => saleKind == CartSaleKind.weight ? _unitPrice * (weightKg ?? 0) : _unitPrice * qty;

  /// Human-readable quantity — "×3" for counted lines, "0.750 كغم" for
  /// weighed ones.
  String get qtyLabel => saleKind == CartSaleKind.weight ? '${weightKg!.toStringAsFixed(3)} كغم' : '×$qty';

  CartLine copyWith({int? qty, double? weightKg}) =>
      CartLine(product: product, qty: qty ?? this.qty, saleKind: saleKind, weightKg: weightKg ?? this.weightKg, variant: variant);

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'qty': qty,
        'saleKind': saleKind.name,
        if (weightKg != null) 'weightKg': weightKg,
        if (variant != null) 'variant': variant!.toJson(),
      };

  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
        product: MockProduct.fromJson(Map<String, dynamic>.from(json['product'] as Map)),
        qty: json['qty'] as int,
        saleKind: CartSaleKind.values.firstWhere((k) => k.name == json['saleKind'], orElse: () => CartSaleKind.unit),
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        variant: json['variant'] == null ? null : MockProductVariant.fromJson(Map<String, dynamic>.from(json['variant'] as Map)),
      );
}

class CartState {
  const CartState({
    this.lines = const [],
    this.discountPercent = 0,
    this.note = '',
    this.customerName,
    this.heldLabel,
    this.taxEnabled = true,
    this.taxRatePercent = 15.0,
  });

  final List<CartLine> lines;
  final double discountPercent;
  final String note;
  final String? customerName;
  final String? heldLabel;
  /// Mirrors [StoreProfile.taxEnabled] — kept on the cart itself (synced by
  /// whoever opens the POS screen) so every total/receipt computed from
  /// this cart honors the merchant's own setup choice instead of always
  /// charging a tax some merchants explicitly said they don't collect.
  final bool taxEnabled;

  /// The merchant's own country VAT rate (see [DukaniCountry.defaultTaxRate]),
  /// synced onto the cart the same way [taxEnabled] is — every merchant
  /// outside Saudi Arabia has a different legal rate, so this must never be
  /// a single fixed constant.
  final double taxRatePercent;

  double get subtotal => lines.fold(0.0, (s, l) => s + l.lineTotal);
  double get discountAmount => subtotal * discountPercent / 100;
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxEnabled ? taxableAmount * taxRatePercent / 100 : 0;
  double get total => taxableAmount + taxAmount;
  int get itemCount => lines.fold(0, (s, l) => s + (l.saleKind == CartSaleKind.weight ? 1 : l.qty));
  bool get isEmpty => lines.isEmpty;

  CartState copyWith({
    List<CartLine>? lines,
    double? discountPercent,
    String? note,
    String? customerName,
    String? heldLabel,
    bool? taxEnabled,
    double? taxRatePercent,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      discountPercent: discountPercent ?? this.discountPercent,
      note: note ?? this.note,
      customerName: customerName ?? this.customerName,
      heldLabel: heldLabel ?? this.heldLabel,
      taxEnabled: taxEnabled ?? this.taxEnabled,
      taxRatePercent: taxRatePercent ?? this.taxRatePercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'lines': lines.map((l) => l.toJson()).toList(),
        'discountPercent': discountPercent,
        'note': note,
        if (customerName != null) 'customerName': customerName,
        if (heldLabel != null) 'heldLabel': heldLabel,
        'taxEnabled': taxEnabled,
        'taxRatePercent': taxRatePercent,
      };

  factory CartState.fromJson(Map<String, dynamic> json) => CartState(
        lines: (json['lines'] as List? ?? []).map((raw) => CartLine.fromJson(Map<String, dynamic>.from(raw as Map))).toList(),
        discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
        note: json['note'] as String? ?? '',
        customerName: json['customerName'] as String?,
        heldLabel: json['heldLabel'] as String?,
        taxEnabled: json['taxEnabled'] as bool? ?? true,
        taxRatePercent: (json['taxRatePercent'] as num?)?.toDouble() ?? 15.0,
      );
}

class CartController extends StateNotifier<CartState> {
  CartController() : super(CartState(taxRatePercent: currentDefaultTaxRatePercent()));

  /// Returns false (leaving the cart untouched) when the product is already
  /// in the cart at its full available stock and the merchant hasn't turned
  /// on "allow negative stock" — never lets a cashier ring up more of a
  /// product than [MockProduct.stock] actually has.
  bool addProduct(MockProduct product) {
    final idx = state.lines.indexWhere((l) => l.product.id == product.id && l.saleKind == CartSaleKind.unit);
    final currentQty = idx == -1 ? 0 : state.lines[idx].qty;
    if (!currentAllowNegativeStock() && currentQty >= product.stock) return false;
    if (idx == -1) {
      state = state.copyWith(lines: [...state.lines, CartLine(product: product, qty: 1)]);
    } else {
      _setQty(idx, currentQty + 1);
    }
    return true;
  }

  /// Adds (or merges into) a weight-sold line — scanning/tapping the same
  /// weighed product again adds to the same line's total weight instead of
  /// creating a second one.
  void addWeighedProduct(MockProduct product, double kg) {
    final idx = state.lines.indexWhere((l) => l.product.id == product.id && l.saleKind == CartSaleKind.weight);
    if (idx == -1) {
      state = state.copyWith(lines: [...state.lines, CartLine(product: product, qty: 1, saleKind: CartSaleKind.weight, weightKg: kg)]);
    } else {
      final lines = [...state.lines];
      lines[idx] = lines[idx].copyWith(weightKg: (lines[idx].weightKg ?? 0) + kg);
      state = state.copyWith(lines: lines);
    }
  }

  /// Adds [count] sealed packs of a multi-pack product as their own line,
  /// separate from any loose pieces of the same product.
  void addPacks(MockProduct product, int count) {
    final idx = state.lines.indexWhere((l) => l.product.id == product.id && l.saleKind == CartSaleKind.pack);
    if (idx == -1) {
      state = state.copyWith(lines: [...state.lines, CartLine(product: product, qty: count, saleKind: CartSaleKind.pack)]);
    } else {
      _setQty(idx, state.lines[idx].qty + count);
    }
  }

  /// Adds [count] loose pieces of a multi-pack product.
  void addLoose(MockProduct product, int count) {
    final idx = state.lines.indexWhere((l) => l.product.id == product.id && l.saleKind == CartSaleKind.loose);
    if (idx == -1) {
      state = state.copyWith(lines: [...state.lines, CartLine(product: product, qty: count, saleKind: CartSaleKind.loose)]);
    } else {
      _setQty(idx, state.lines[idx].qty + count);
    }
  }

  /// Adds one of a specific size/color variant — a different variant of the
  /// same product always gets its own line, since each draws from its own
  /// stock and can carry its own [MockProductVariant.priceDelta].
  void addVariant(MockProduct product, MockProductVariant variant) {
    final idx = state.lines.indexWhere((l) => l.product.id == product.id && l.variant?.id == variant.id);
    if (idx == -1) {
      state = state.copyWith(lines: [...state.lines, CartLine(product: product, qty: 1, variant: variant)]);
    } else {
      _setQty(idx, state.lines[idx].qty + 1);
    }
  }

  void increment(String productId) => _updateByProductId(productId, (l) => l.qty + 1);

  void decrement(String productId) => _updateByProductId(productId, (l) => l.qty - 1);

  void _updateByProductId(String productId, int Function(CartLine) nextQty) {
    final idx = state.lines.indexWhere((l) => l.product.id == productId);
    if (idx == -1) return;
    _setQty(idx, nextQty(state.lines[idx]));
  }

  /// Line-exact variants — needed once a single product can appear as more
  /// than one line at once (e.g. a sealed-pack line and a loose-piece line
  /// for the same egg carton), where matching by product id alone would be
  /// ambiguous.
  int _indexOfLine(CartLine line) =>
      state.lines.indexWhere((l) => l.product.id == line.product.id && l.saleKind == line.saleKind && l.variant?.id == line.variant?.id);

  /// Same stock ceiling as [addProduct] — returns false without changing
  /// the cart once a unit-sold line is already at the product's full stock.
  bool incrementLine(CartLine line) {
    final idx = _indexOfLine(line);
    if (idx == -1) return false;
    final current = state.lines[idx];
    if (current.saleKind == CartSaleKind.unit && !currentAllowNegativeStock() && current.qty >= current.product.stock) return false;
    _setQty(idx, current.qty + 1);
    return true;
  }

  void decrementLine(CartLine line) {
    final idx = _indexOfLine(line);
    if (idx != -1) _setQty(idx, state.lines[idx].qty - 1);
  }

  void removeLineExact(CartLine line) {
    final idx = _indexOfLine(line);
    if (idx == -1) return;
    final lines = [...state.lines]..removeAt(idx);
    state = state.copyWith(lines: lines);
  }

  void _setQty(int idx, int qty) {
    final lines = [...state.lines];
    if (qty <= 0) {
      lines.removeAt(idx);
    } else {
      lines[idx] = lines[idx].copyWith(qty: qty);
    }
    state = state.copyWith(lines: lines);
  }

  void removeLine(String productId) {
    state = state.copyWith(lines: state.lines.where((l) => l.product.id != productId).toList());
  }

  void setDiscountPercent(double value) => state = state.copyWith(discountPercent: value);

  void setNote(String value) => state = state.copyWith(note: value);

  void setCustomer(String? name) => state = state.copyWith(customerName: name);

  /// Kept a no-op if the value hasn't actually changed, since this gets
  /// called on every rebuild of the screen that watches the store profile.
  void setTaxEnabled(bool value) {
    if (state.taxEnabled == value) return;
    state = state.copyWith(taxEnabled: value);
  }

  /// Same no-op guard as [setTaxEnabled] — keeps the cart's tax percentage
  /// in step with the merchant's own country (see [currentDefaultTaxRatePercent]).
  void setTaxRatePercent(double value) {
    if (state.taxRatePercent == value) return;
    state = state.copyWith(taxRatePercent: value);
  }

  void clear() => state = CartState(taxRatePercent: currentDefaultTaxRatePercent());

  /// Loads a previously held cart back into the active session — used when
  /// resuming a suspended sale from [HeldOrdersController.resume].
  void restore(CartState cart) => state = cart;
}

final cartProvider = StateNotifierProvider<CartController, CartState>((ref) => CartController());

/// Suspended sales — "تعليق الفاتورة" — parked here so the cashier can pick
/// up another customer and resume later without losing the cart. Persisted
/// to Hive (device-local only, not synced to Firestore — a suspended sale
/// belongs to whichever device is running this shift) so it survives the
/// app being killed mid-shift instead of silently disappearing.
class HeldOrdersController extends PersistedListNotifier<CartState> {
  HeldOrdersController() : super(box: LocalDb.heldOrders, seed: const [], toJson: (c) => c.toJson(), fromJson: CartState.fromJson);

  void hold(CartState cart, String label) {
    state = [...state, cart.copyWith(heldLabel: label)];
  }

  CartState resume(int index) {
    final order = state[index];
    state = [...state]..removeAt(index);
    return order;
  }

  void discard(int index) {
    state = [...state]..removeAt(index);
  }
}

final heldOrdersProvider = StateNotifierProvider<HeldOrdersController, List<CartState>>((ref) => HeldOrdersController());

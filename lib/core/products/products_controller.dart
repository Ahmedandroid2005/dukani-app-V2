import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_models.dart';
import '../auth/auth_controller.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

/// Mutable product catalog. Starts empty — persisted to Hive so it
/// survives an app restart, and synced to the store's Firestore document
/// so it isn't stuck on one device. POS, Products and Inventory all read
/// from this single provider so an edit made here is immediately reflected
/// everywhere else.
class ProductsController extends FirestoreSyncedListNotifier<MockProduct> {
  ProductsController(String? ownerUid)
      : super(
          box: LocalDb.products,
          seed: const [],
          toJson: (p) => p.toJson(),
          fromJson: MockProduct.fromJson,
          ownerUid: ownerUid,
          collectionName: 'products',
        );

  void add(MockProduct product) => state = [...state, product];

  void update(String id, MockProduct updated) {
    state = [for (final p in state) p.id == id ? updated : p];
  }

  void remove(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  /// Relative stock change (restock, damage, manual correction…) — clamped
  /// so a series of decrements can never take a product negative.
  void adjustStock(String id, int delta) {
    state = [for (final p in state) p.id == id ? p.copyWith(stock: (p.stock + delta).clamp(0, 1 << 31)) : p];
  }

  /// Absolute stock set — used to reconcile a physical stocktake count.
  void setStock(String id, int newStock) {
    state = [for (final p in state) p.id == id ? p.copyWith(stock: newStock.clamp(0, 1 << 31)) : p];
  }

  /// Sells [kg] off a weight-mode or bulk-container product. For a bulk
  /// container, once the currently-open sack runs out this automatically
  /// opens the next sealed one (decrementing [MockProduct.stock]) so the
  /// cashier never has to do that bookkeeping by hand.
  void sellWeight(String id, double kg) {
    state = [
      for (final p in state)
        if (p.id == id)
          _deductWeight(p, kg)
        else
          p,
    ];
  }

  MockProduct _deductWeight(MockProduct p, double kg) {
    if (p.unitMode != ProductUnitMode.bulkContainer) {
      return p.copyWith(openStockKg: (p.openStockKg - kg).clamp(0, double.infinity));
    }
    var remainingToSell = kg;
    var openKg = p.openStockKg;
    var sealed = p.stock;
    while (remainingToSell > openKg && sealed > 0) {
      remainingToSell -= openKg;
      sealed -= 1;
      openKg = p.containerSizeKg;
    }
    openKg = (openKg - remainingToSell).clamp(0, double.infinity);
    return p.copyWith(stock: sealed, openStockKg: openKg);
  }

  /// Sells [count] sealed packs of a multi-pack product.
  void sellPacks(String id, int count) {
    state = [for (final p in state) p.id == id ? p.copyWith(stock: (p.stock - count).clamp(0, 1 << 31)) : p];
  }

  /// Sells [count] loose pieces of a multi-pack product, automatically
  /// breaking open a sealed pack into loose pieces if that's not enough —
  /// mirrors how a cashier would really handle it at the counter.
  void sellLoose(String id, int count) {
    state = [
      for (final p in state)
        if (p.id == id)
          _deductLoose(p, count)
        else
          p,
    ];
  }

  MockProduct _deductLoose(MockProduct p, int count) {
    var remainingToSell = count;
    var loose = p.looseUnits;
    var sealed = p.stock;
    while (remainingToSell > loose && sealed > 0) {
      sealed -= 1;
      loose += p.packSize;
    }
    loose = (loose - remainingToSell).clamp(0, 1 << 31);
    return p.copyWith(stock: sealed, looseUnits: loose);
  }

  /// Relative stock change on one size/color variant of a product — never
  /// touches the base [MockProduct.stock] or any other variant, so selling
  /// the last "L أزرق" can't accidentally draw down "M أحمر" instead.
  void adjustVariantStock(String productId, String variantId, int delta) {
    state = [
      for (final p in state)
        if (p.id == productId)
          p.copyWith(
            variants: [
              for (final v in p.variants) v.id == variantId ? v.copyWith(stock: (v.stock + delta).clamp(0, 1 << 31)) : v,
            ],
          )
        else
          p,
    ];
  }

  MockProduct? byId(String id) {
    for (final p in state) {
      if (p.id == id) return p;
    }
    return null;
  }

  String nextId() {
    var n = state.length + 1;
    while (state.any((p) => p.id == 'p$n')) {
      n++;
    }
    return 'p$n';
  }
}

final productsProvider = StateNotifierProvider<ProductsController, List<MockProduct>>(
  (ref) => ProductsController(ref.watch(authStateProvider).valueOrNull?.uid),
);

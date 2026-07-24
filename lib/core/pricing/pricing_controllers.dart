import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_models.dart';
import '../auth/auth_controller.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

/// Tax rates, offers, and coupons are small, related "pricing rules"
/// modules — grouped in one file since each controller is tiny, following
/// the same seam as every other module controller in this app.

class TaxesController extends FirestoreSyncedListNotifier<MockTaxRate> {
  TaxesController(String? ownerUid)
      : super(box: LocalDb.taxes, seed: const [], toJson: (t) => t.toJson(), fromJson: MockTaxRate.fromJson, ownerUid: ownerUid, collectionName: 'taxes');

  void add(MockTaxRate rate) => state = [...state, rate];
  void update(String id, MockTaxRate updated) => state = [for (final t in state) t.id == id ? updated : t];
  void remove(String id) => state = state.where((t) => t.id != id || t.isDefault).toList();
  String nextId() {
    var n = state.length + 1;
    while (state.any((t) => t.id == 'tax$n')) {
      n++;
    }
    return 'tax$n';
  }
}

final taxesProvider = StateNotifierProvider<TaxesController, List<MockTaxRate>>(
  (ref) => TaxesController(ref.watch(authStateProvider).valueOrNull?.uid),
);

class OffersController extends FirestoreSyncedListNotifier<MockOffer> {
  OffersController(String? ownerUid)
      : super(box: LocalDb.offers, seed: const [], toJson: (o) => o.toJson(), fromJson: MockOffer.fromJson, ownerUid: ownerUid, collectionName: 'offers');

  void add(MockOffer offer) => state = [...state, offer];
  void update(String id, MockOffer updated) => state = [for (final o in state) o.id == id ? updated : o];
  void remove(String id) => state = state.where((o) => o.id != id).toList();
  void toggleActive(String id) => state = [for (final o in state) o.id == id ? o.copyWith(active: !o.active) : o];
  String nextId() {
    var n = state.length + 1;
    while (state.any((o) => o.id == 'off$n')) {
      n++;
    }
    return 'off$n';
  }
}

final offersProvider = StateNotifierProvider<OffersController, List<MockOffer>>(
  (ref) => OffersController(ref.watch(authStateProvider).valueOrNull?.uid),
);

class CouponsController extends FirestoreSyncedListNotifier<MockCoupon> {
  CouponsController(String? ownerUid)
      : super(box: LocalDb.coupons, seed: const [], toJson: (c) => c.toJson(), fromJson: MockCoupon.fromJson, ownerUid: ownerUid, collectionName: 'coupons');

  void add(MockCoupon coupon) => state = [...state, coupon];
  void update(String id, MockCoupon updated) => state = [for (final c in state) c.id == id ? updated : c];
  void remove(String id) => state = state.where((c) => c.id != id).toList();
  void toggleActive(String id) => state = [for (final c in state) c.id == id ? c.copyWith(active: !c.active) : c];
  String nextId() {
    var n = state.length + 1;
    while (state.any((c) => c.id == 'cp$n')) {
      n++;
    }
    return 'cp$n';
  }
}

final couponsProvider = StateNotifierProvider<CouponsController, List<MockCoupon>>(
  (ref) => CouponsController(ref.watch(authStateProvider).valueOrNull?.uid),
);

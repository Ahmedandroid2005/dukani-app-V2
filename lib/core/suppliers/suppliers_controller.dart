import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_models.dart';
import '../organizations/org_controller.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

/// Mutable supplier directory. Starts empty — every supplier here is one
/// the merchant actually added, never a demo record.
class SuppliersController extends FirestoreSyncedListNotifier<MockSupplier> {
  SuppliersController(String? orgId)
      : super(box: LocalDb.suppliers, seed: const [], toJson: (s) => s.toJson(), fromJson: MockSupplier.fromJson, orgId: orgId, collectionName: 'suppliers');

  void add(MockSupplier supplier) => state = [...state, supplier];

  void update(String id, MockSupplier updated) {
    state = [for (final s in state) s.id == id ? updated : s];
  }

  void remove(String id) {
    state = state.where((s) => s.id != id).toList();
  }

  /// Records a payment made to the supplier — clamps at zero.
  void settlePayable(String id, double amount) {
    state = [for (final s in state) s.id == id ? s.copyWith(payable: (s.payable - amount).clamp(0, double.infinity)) : s];
  }

  /// A received purchase increases what the store owes this supplier.
  void addPayable(String id, double amount) {
    state = [for (final s in state) s.id == id ? s.copyWith(payable: s.payable + amount) : s];
  }

  MockSupplier? byId(String id) {
    for (final s in state) {
      if (s.id == id) return s;
    }
    return null;
  }

  String nextId() {
    var n = state.length + 1;
    while (state.any((s) => s.id == 's$n')) {
      n++;
    }
    return 's$n';
  }
}

final suppliersProvider = StateNotifierProvider<SuppliersController, List<MockSupplier>>(
  (ref) => SuppliersController(ref.watch(currentOrgIdProvider).valueOrNull),
);

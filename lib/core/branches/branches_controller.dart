import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_models.dart';
import '../auth/auth_controller.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

/// Mutable branch directory. Seeded with a single generic main branch (no
/// address/manager pre-filled — a store always needs at least one home
/// base for tax/legal registration) rather than any invented business
/// details; the merchant fills in the real address from the Branches
/// screen. Every branch after that is one the merchant actually added.
class BranchesController extends FirestoreSyncedListNotifier<MockBranch> {
  BranchesController(String? ownerUid)
      : super(
          box: LocalDb.branches,
          seed: const [MockBranch(id: 'br1', name: 'الفرع الرئيسي', isMain: true)],
          toJson: (b) => b.toJson(),
          fromJson: MockBranch.fromJson,
          ownerUid: ownerUid,
          collectionName: 'branches',
        );

  void add(MockBranch branch) => state = [...state, branch];

  void update(String id, MockBranch updated) {
    state = [for (final b in state) b.id == id ? updated : b];
  }

  /// The main branch can't be removed — a store always needs at least one
  /// home base for tax/legal registration.
  void remove(String id) {
    state = state.where((b) => b.id != id || b.isMain).toList();
  }

  MockBranch? byId(String id) {
    for (final b in state) {
      if (b.id == id) return b;
    }
    return null;
  }

  String nextId() {
    var n = state.length + 1;
    while (state.any((b) => b.id == 'br$n')) {
      n++;
    }
    return 'br$n';
  }
}

final branchesProvider = StateNotifierProvider<BranchesController, List<MockBranch>>(
  (ref) => BranchesController(ref.watch(authStateProvider).valueOrNull?.uid),
);

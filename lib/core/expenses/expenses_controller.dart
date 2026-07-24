import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_models.dart';
import '../organizations/org_controller.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

/// Mutable expense log. Starts empty — every entry here is a real expense
/// the merchant logged, never a demo record.
class ExpensesController extends FirestoreSyncedListNotifier<MockExpense> {
  ExpensesController(String? orgId)
      : super(box: LocalDb.expenses, seed: const [], toJson: (e) => e.toJson(), fromJson: MockExpense.fromJson, orgId: orgId, collectionName: 'expenses');

  void add(MockExpense expense) => state = [expense, ...state];

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  String nextId() {
    var n = state.length + 1;
    while (state.any((e) => e.id == 'e$n')) {
      n++;
    }
    return 'e$n';
  }
}

final expensesProvider = StateNotifierProvider<ExpensesController, List<MockExpense>>(
  (ref) => ExpensesController(ref.watch(currentOrgIdProvider).valueOrNull),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_models.dart';
import '../auth/auth_controller.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

/// Mutable employee directory. Starts empty — the owner signs in with their
/// own Firebase account and creates every employee (with a real phone
/// number and password) from the Employees screen; nothing here is
/// preloaded, so there's never a demo account with a guessable password
/// baked into a fresh install.
class EmployeesController extends FirestoreSyncedListNotifier<MockEmployee> {
  EmployeesController(String? ownerUid)
      : super(box: LocalDb.employees, seed: const [], toJson: (e) => e.toJson(), fromJson: MockEmployee.fromJson, ownerUid: ownerUid, collectionName: 'employees');

  void add(MockEmployee employee) => state = [...state, employee];

  void update(String id, MockEmployee updated) {
    state = [for (final e in state) e.id == id ? updated : e];
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void toggleActive(String id) {
    state = [for (final e in state) e.id == id ? e.copyWith(active: !e.active) : e];
  }

  MockEmployee? byId(String id) {
    for (final e in state) {
      if (e.id == id) return e;
    }
    return null;
  }

  MockEmployee? byPhone(String phone) {
    for (final e in state) {
      if (e.phone == phone) return e;
    }
    return null;
  }

  /// Username/phone must be unique across every employee — mirrors the
  /// backend constraint this will eventually enforce server-side too.
  bool isPhoneTaken(String phone, {String? excludingId}) {
    return state.any((e) => e.phone == phone && e.id != excludingId);
  }

  String nextId() {
    var n = state.length + 1;
    while (state.any((e) => e.id == 'emp$n')) {
      n++;
    }
    return 'emp$n';
  }
}

final employeesProvider = StateNotifierProvider<EmployeesController, List<MockEmployee>>(
  (ref) => EmployeesController(ref.watch(authStateProvider).valueOrNull?.uid),
);

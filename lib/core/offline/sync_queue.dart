import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_db.dart';

/// Anything created while offline (a sale, a voided invoice, a stock
/// adjustment...) gets queued here instead of failing outright. No backend
/// is wired up yet, so [flush] simulates the round-trip — but every screen
/// that writes data should go through this queue from day one, so plugging
/// in the real API later doesn't require touching the UI layer at all.
class SyncQueueController extends StateNotifier<List<Map<dynamic, dynamic>>> {
  SyncQueueController() : super(_readAll());

  static List<Map<dynamic, dynamic>> _readAll() {
    return LocalDb.pendingSync.values.cast<Map>().map((m) => Map.from(m)).toList();
  }

  Future<void> enqueue(String type, Map<String, dynamic> payload) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final item = {
      'id': id,
      'type': type,
      'payload': payload,
      'queuedAt': DateTime.now().toIso8601String(),
    };
    await LocalDb.pendingSync.put(id, item);
    state = _readAll();
  }

  /// Simulates syncing every queued item with the server. Replace the
  /// artificial delay with real API calls once a backend exists — the
  /// queue/flush contract stays the same either way.
  Future<void> flush() async {
    if (state.isEmpty) return;
    for (final item in List.of(state)) {
      await Future.delayed(const Duration(milliseconds: 250));
      await LocalDb.pendingSync.delete(item['id']);
    }
    state = _readAll();
  }

  int get pendingCount => state.length;
}

final syncQueueProvider = StateNotifierProvider<SyncQueueController, List<Map<dynamic, dynamic>>>(
  (ref) => SyncQueueController(),
);

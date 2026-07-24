import 'package:cloud_firestore/cloud_firestore.dart';

import 'persisted_list_notifier.dart';

/// Same contract as [PersistedListNotifier] — every mutation still writes
/// to Hive immediately, so the screen never waits on the network and the
/// app keeps working offline exactly as before — but the whole list is
/// also mirrored to one Firestore document per store, so a second device
/// (or the Super Admin panel, later) sees the same data instead of it
/// being stuck on whichever phone happened to write it.
///
/// Sync model, deliberately simple: on construction, pull the cloud copy
/// once and let it win over whatever Hive/seed had (the cloud is the
/// union of every device's writes); after that, every local mutation
/// pushes the full list up. There's no live listener — a change made on
/// another device shows up on this one's next launch, not instantly.
/// That's a real limitation, not an oversight: a realtime listener needs
/// care to avoid feeding its own writes back to itself, and isn't worth
/// that risk until "pull on launch" is proven to actually be too slow for
/// how merchants really use this.
///
/// [orgId] is nullable so a controller can still be constructed before the
/// signed-in owner's organization has resolved (or for a signed-out
/// preview) — sync is simply skipped until a real org is known, exactly
/// like [PersistedListNotifier] already behaves before any data exists.
abstract class FirestoreSyncedListNotifier<T> extends PersistedListNotifier<T> {
  FirestoreSyncedListNotifier({
    required super.box,
    required super.seed,
    required super.toJson,
    required super.fromJson,
    required this.orgId,
    required this.collectionName,
  }) {
    _pullFromCloud();
  }

  final String? orgId;

  /// Which slot under the organization's cloud document this list lives
  /// in — e.g. `'products'`, `'customers'`. Kept distinct per entity so two
  /// controllers never collide on the same document.
  final String collectionName;

  DocumentReference<Map<String, dynamic>>? get _doc {
    final org = orgId;
    if (org == null) return null;
    return FirebaseFirestore.instance.collection('organizations').doc(org).collection('data').doc(collectionName);
  }

  Future<void> _pullFromCloud() async {
    final doc = _doc;
    if (doc == null) return;
    try {
      final snapshot = await doc.get();
      final raw = snapshot.data()?['items'] as List<dynamic>?;
      if (raw == null) return; // nothing synced yet — keep what Hive/seed already loaded
      final cloudItems = raw.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();
      super.state = cloudItems; // via super: write through to Hive without re-pushing what we just pulled
    } catch (_) {
      // Offline, or Firestore rules/project not reachable yet — Hive/seed
      // already loaded synchronously before this ran, so there's always a
      // usable local copy regardless.
    }
  }

  @override
  set state(List<T> value) {
    super.state = value;
    final doc = _doc;
    if (doc == null) return;
    doc.set({'items': value.map(toJson).toList()}).catchError((_) {
      // Hive already has the authoritative local copy; the next mutation
      // (or the next app launch's pull) retries the sync on its own.
    });
  }
}

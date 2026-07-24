import 'package:cloud_firestore/cloud_firestore.dart';

import 'store_profile.dart';

/// The only file that imports `cloud_firestore` for store profiles —
/// everything else talks to [StoreRepository].
class FirestoreStoreRepository implements StoreRepository {
  FirestoreStoreRepository(this._firestore);
  final FirebaseFirestore _firestore;

  /// One store document per owner, keyed by their Firebase UID — the
  /// simplest model that supports today's "one owner, one store" flow.
  /// Multiple branches under one store, or staff accounts that aren't the
  /// owner, read/write under this same document later rather than needing
  /// a new collection.
  DocumentReference<Map<String, dynamic>> _doc(String ownerUid) => _firestore.collection('stores').doc(ownerUid);

  @override
  Future<StoreProfile?> fetch(String ownerUid) async {
    final snapshot = await _doc(ownerUid).get();
    if (!snapshot.exists) return null;
    return StoreProfile.fromJson(snapshot.data()!);
  }

  @override
  Future<void> save(String ownerUid, StoreProfile profile) async {
    final ref = _doc(ownerUid);
    final existing = await ref.get();
    await ref.set({
      ...profile.toJson(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import 'store_profile.dart';

/// The only file that imports `cloud_firestore` for store profiles —
/// everything else talks to [StoreRepository].
class FirestoreStoreRepository implements StoreRepository {
  FirestoreStoreRepository(this._firestore);
  final FirebaseFirestore _firestore;

  /// One store document per organization, keyed by [orgId] — multiple
  /// branches under one store, or additional invited members, read/write
  /// under this same document rather than needing a new collection.
  DocumentReference<Map<String, dynamic>> _doc(String orgId) => _firestore.collection('organizations').doc(orgId);

  @override
  Future<StoreProfile?> fetch(String orgId) async {
    final snapshot = await _doc(orgId).get();
    if (!snapshot.exists) return null;
    return StoreProfile.fromJson(snapshot.data()!);
  }

  @override
  Future<void> save(String orgId, StoreProfile profile) async {
    final ref = _doc(orgId);
    final existing = await ref.get();
    await ref.set({
      ...profile.toJson(),
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

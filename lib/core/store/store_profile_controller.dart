import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import 'firestore_store_repository.dart';
import 'store_profile.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => FirestoreStoreRepository(ref.watch(firestoreProvider)),
);

/// Whether the signed-in owner has already finished setup before — the
/// login screen watches this to send a returning merchant straight to the
/// dashboard instead of re-running first-time setup on every sign-in.
final storeProfileProvider = FutureProvider<StoreProfile?>((ref) async {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return null;
  return ref.watch(storeRepositoryProvider).fetch(uid);
});

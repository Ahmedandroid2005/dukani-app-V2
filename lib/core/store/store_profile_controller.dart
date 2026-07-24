import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_providers.dart';
import '../organizations/org_controller.dart';
import 'firestore_store_repository.dart';
import 'store_profile.dart';

final storeRepositoryProvider = Provider<StoreRepository>(
  (ref) => FirestoreStoreRepository(ref.watch(firestoreProvider)),
);

/// Whether the signed-in owner has already finished setup before — the
/// login screen watches this to send a returning merchant straight to the
/// dashboard instead of re-running first-time setup on every sign-in.
final storeProfileProvider = FutureProvider<StoreProfile?>((ref) async {
  final orgId = await ref.watch(currentOrgIdProvider.future);
  if (orgId == null) return null;
  return ref.watch(storeRepositoryProvider).fetch(orgId);
});

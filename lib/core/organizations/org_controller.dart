import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../firebase_providers.dart';
import 'org_membership_repository.dart';

final orgMembershipRepositoryProvider = Provider<OrgMembershipRepository>(
  (ref) => FirestoreOrgMembershipRepository(ref.watch(firestoreProvider)),
);

/// Which organization's data every tenant-scoped repository should read —
/// the one lookup between "who's signed in" and "which tenant". Every
/// `FirestoreSyncedListNotifier` provider watches this instead of reading
/// `authStateProvider`'s uid directly, so a future invited member (whose
/// own uid differs from the org's id) works without touching any of them.
final currentOrgIdProvider = FutureProvider<String?>((ref) async {
  // Watched only to make this provider recompute on sign-in/sign-out; the
  // uid itself is read off the synchronous `currentUser` getter instead of
  // this stream's `.valueOrNull`, which can still be sitting in its initial
  // loading state immediately after signIn()/signUp() (nothing else may
  // have watched it yet to prime it) — the same race splash_screen.dart and
  // login_screen.dart already had to work around once.
  ref.watch(authStateProvider);
  final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
  if (uid == null) return null;
  final membership = await ref.watch(orgMembershipRepositoryProvider).fetch(uid);
  return membership?.orgId;
});

/// Called once, right when a brand-new owner finishes store setup (see
/// `store_setup_wizard.dart`) — creates their `memberships/{uid}` document
/// so [currentOrgIdProvider] resolves from then on. A returning owner never
/// calls this again; their membership already exists from their first run.
Future<void> bootstrapOrgForNewOwner(WidgetRef ref, String uid) async {
  await ref.read(orgMembershipRepositoryProvider).createOrgForNewOwner(uid);
  ref.invalidate(currentOrgIdProvider);
}

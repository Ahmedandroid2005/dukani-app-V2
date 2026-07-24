import 'package:cloud_firestore/cloud_firestore.dart';

import 'org_membership.dart';

abstract class OrgMembershipRepository {
  Future<OrgMembership?> fetch(String uid);

  /// Creates a brand-new organization owned by [uid] and records the
  /// membership pointing to it — called exactly once, right after a new
  /// owner finishes store setup. The organization's id is just [uid]
  /// itself: the owner's Firebase account already uniquely identifies a
  /// fresh tenant, so there's no reason to mint a second random id for it.
  /// A later invited member (accountant, partner) gets their own
  /// `memberships/{theirUid}` document pointing at this same [uid]-shaped
  /// orgId instead.
  Future<OrgMembership> createOrgForNewOwner(String uid);
}

class FirestoreOrgMembershipRepository implements OrgMembershipRepository {
  FirestoreOrgMembershipRepository(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _firestore.collection('memberships').doc(uid);

  @override
  Future<OrgMembership?> fetch(String uid) async {
    final snapshot = await _doc(uid).get();
    if (!snapshot.exists) return null;
    return OrgMembership.fromJson(snapshot.data()!);
  }

  @override
  Future<OrgMembership> createOrgForNewOwner(String uid) async {
    final membership = OrgMembership(orgId: uid, role: OrgRole.owner);
    await _doc(uid).set(membership.toJson());
    return membership;
  }
}

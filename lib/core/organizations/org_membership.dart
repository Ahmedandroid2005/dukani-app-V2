/// Which organization (tenant) a signed-in Firebase user belongs to, and
/// what they can do there. One document per user at `memberships/{uid}` —
/// looking this up is the only step between "who's logged in" and "which
/// tenant's data do we read", so every other repository can stay ignorant
/// of Firebase Auth entirely and just take an [orgId].
class OrgMembership {
  const OrgMembership({required this.orgId, required this.role});

  final String orgId;
  final OrgRole role;

  factory OrgMembership.fromJson(Map<String, dynamic> json) => OrgMembership(
        orgId: json['orgId'] as String,
        role: OrgRole.values.firstWhere((r) => r.name == json['role'], orElse: () => OrgRole.owner),
      );

  Map<String, dynamic> toJson() => {'orgId': orgId, 'role': role.name};
}

/// The owner is whoever created the organization; every other role is a
/// future door for inviting a second Firebase-authenticated user (an
/// accountant, a partner) into the same tenant without them being able to
/// create/delete the organization itself.
enum OrgRole { owner, manager, staff }

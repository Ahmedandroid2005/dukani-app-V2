/// What the setup wizard collects about a merchant's store — the cloud
/// counterpart to the local-only [BusinessType]/country providers, keyed
/// by the owner's Firebase UID so it survives a reinstall and is what lets
/// a returning owner skip straight past setup on a second device.
class StoreProfile {
  const StoreProfile({
    required this.storeName,
    required this.ownerName,
    required this.businessType,
    required this.countryCode,
    required this.taxEnabled,
    this.ownerEmail,
    this.ownerPhone,
    this.suspended = false,
  });

  final String storeName;
  final String ownerName;

  /// From Firebase Auth at save time — not user-entered. Lets the Super
  /// Admin panel send a real password-reset email or identify an account
  /// without a merchant having to type their own email a second time.
  final String? ownerEmail;
  final String? ownerPhone;

  /// [BusinessType.name] — kept as a plain string here so this model
  /// doesn't need to depend on the business-type enum's module.
  final String businessType;
  final String countryCode;
  final bool taxEnabled;

  /// Set only by the Super Admin panel (see firestore.rules — a merchant's
  /// own write never touches this field) — checked once at sign-in
  /// (login_screen.dart) to block a suspended account from reaching the
  /// dashboard. Deliberately not re-checked on every screen: a merchant
  /// already inside the app keeps working until their next sign-in rather
  /// than being kicked out mid-sale over a network read.
  final bool suspended;

  Map<String, dynamic> toJson() => {
        'storeName': storeName,
        'ownerName': ownerName,
        if (ownerEmail != null) 'ownerEmail': ownerEmail,
        if (ownerPhone != null) 'ownerPhone': ownerPhone,
        'businessType': businessType,
        'countryCode': countryCode,
        'taxEnabled': taxEnabled,
      };

  factory StoreProfile.fromJson(Map<String, dynamic> json) => StoreProfile(
        storeName: json['storeName'] as String? ?? '',
        ownerName: json['ownerName'] as String? ?? '',
        ownerEmail: json['ownerEmail'] as String?,
        ownerPhone: json['ownerPhone'] as String?,
        businessType: json['businessType'] as String? ?? 'generalRetail',
        countryCode: json['countryCode'] as String? ?? 'SA',
        taxEnabled: json['taxEnabled'] as bool? ?? false,
        suspended: json['suspended'] as bool? ?? false,
      );
}

/// What the rest of the app needs from "does this organization already
/// have a store set up" — nothing here mentions Firestore, matching the
/// same dependency-inversion seam [AuthRepository] uses for Firebase Auth.
abstract class StoreRepository {
  Future<StoreProfile?> fetch(String orgId);

  Future<void> save(String orgId, StoreProfile profile);
}

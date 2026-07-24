import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../offline/local_db.dart';

/// A Super Admin-controlled on/off (with optional partial-rollout) switch
/// for a real, already-built feature. This is deliberately NOT a place to
/// list features that don't exist yet — every flag here must gate an
/// actual screen/entry point in the app, or a Super Admin toggling it
/// "on" would be lying to themselves about what just changed.
class DukaniFeatureFlag {
  const DukaniFeatureFlag({required this.id, required this.enabled, required this.rollout});

  final String id;
  final bool enabled;

  /// 0-100. A store only gets the feature if [enabled] is true AND its own
  /// owner UID hashes into the enabled slice — stable per store (the same
  /// merchant doesn't flicker in and out across app launches) without
  /// needing a server round trip to decide.
  final int rollout;

  Map<String, dynamic> toJson() => {'id': id, 'enabled': enabled, 'rollout': rollout};

  factory DukaniFeatureFlag.fromJson(Map<String, dynamic> json) => DukaniFeatureFlag(
        id: json['id'] as String,
        enabled: json['enabled'] as bool,
        rollout: (json['rollout'] as num).toInt(),
      );
}

Map<String, DukaniFeatureFlag> _flags = {};

/// True until the first cache/cloud read completes — every flag defaults
/// to "on" during that window (see [isFeatureEnabled]) so a brand-new
/// install or a signed-out preview never hides a real, working feature
/// just because Super Admin hasn't been reached yet.
bool _loaded = false;

void applyFeatureFlags(List<DukaniFeatureFlag> flags) {
  if (flags.isEmpty) return;
  _flags = {for (final f in flags) f.id: f};
  _loaded = true;
}

/// The single call site every gated entry point uses. Fails open by
/// design — an unknown flag ID, an unloaded catalog, or a signed-out user
/// all resolve to `true`, because the alternative (a merchant losing
/// access to a feature they already rely on due to a sync hiccup) is far
/// worse than an ungated feature briefly staying visible.
bool isFeatureEnabled(String flagId) {
  final flag = _flags[flagId];
  if (!_loaded || flag == null) return true;
  if (!flag.enabled) return false;
  if (flag.rollout >= 100) return true;
  if (flag.rollout <= 0) return false;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return true;
  final bucket = uid.hashCode.abs() % 100;
  return bucket < flag.rollout;
}

class FeatureFlagsSync {
  FeatureFlagsSync._();

  static const _cacheKey = 'featureFlagsV1';

  static void loadCached() {
    final raw = LocalDb.settings.get(_cacheKey) as List<dynamic>?;
    if (raw == null || raw.isEmpty) return;
    try {
      applyFeatureFlags(raw.map((e) => DukaniFeatureFlag.fromJson(Map<String, dynamic>.from(e as Map))).toList());
    } catch (_) {
      // Corrupt/old-schema cache entry — keep failing open until the cloud pull lands.
    }
  }

  static Future<void> refreshFromCloud() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('feature_flags').get();
      if (snapshot.docs.isEmpty) return;
      final flags = snapshot.docs.map((d) => DukaniFeatureFlag.fromJson(d.data())).toList();
      applyFeatureFlags(flags);
      await LocalDb.settings.put(_cacheKey, flags.map((f) => f.toJson()).toList());
    } catch (_) {
      // Offline, rules not yet published, or collection not seeded yet.
    }
  }
}

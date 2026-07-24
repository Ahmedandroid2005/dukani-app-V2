import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/dukani_countries.dart';
import '../offline/local_db.dart';

/// Keeps [dukaniCountries] in sync with the Super Admin-managed `countries`
/// collection in Firestore, without ever blocking app startup on a network
/// call: [loadCached] applies whatever was saved locally last time
/// (synchronously, before the first frame), and [refreshFromCloud] is fired
/// separately, updating both the in-memory catalog and the Hive cache once
/// it lands. A store that's never been online still sees the built-in
/// defaults; one that has sees every country/currency/tax rate a Super
/// Admin has published, including ones added after the app was installed.
class CountryCatalogSync {
  CountryCatalogSync._();

  static const _cacheKey = 'countryCatalogV1';

  /// Synchronous by design — Hive's local read has no `await` once the box
  /// is already open, so this can run right after `LocalDb.init()` and
  /// still land before the first widget builds.
  static void loadCached() {
    final raw = LocalDb.settings.get(_cacheKey) as List<dynamic>?;
    if (raw == null || raw.isEmpty) return;
    try {
      final countries = raw.map((e) => DukaniCountry.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      applyCountryCatalog(countries);
    } catch (_) {
      // Corrupt cache entry from an older schema — keep the built-in defaults.
    }
  }

  /// Fire-and-forget from `main.dart`. Never throws: offline, a not-yet-
  /// seeded collection, or a mid-flight Firestore outage all just mean the
  /// app keeps using whatever [loadCached] already applied.
  static Future<void> refreshFromCloud() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('countries').where('enabled', isEqualTo: true).get();
      if (snapshot.docs.isEmpty) return;
      final countries = snapshot.docs.map((d) => DukaniCountry.fromJson(d.data())).toList()..sort((a, b) => a.nameAr.compareTo(b.nameAr));
      applyCountryCatalog(countries);
      await LocalDb.settings.put(_cacheKey, countries.map((c) => c.toJson()).toList());
    } catch (_) {
      // Offline, rules not yet published, or collection not seeded yet.
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/dukani_countries.dart';
import '../offline/local_db.dart';

/// The store's country, picked during setup. Payment methods and tax
/// defaults both read this — a store in Kuwait sees KNET, one in Egypt sees
/// Fawry, without either merchant seeing options that don't apply to them.
class CountryController extends StateNotifier<String> {
  CountryController() : super(_read());

  static String _read() {
    final stored = LocalDb.settings.get('countryCode') as String?;
    if (stored == null) return dukaniCountries.first.code;
    return dukaniCountries.any((c) => c.code == stored) ? stored : dukaniCountries.first.code;
  }

  Future<void> set(String countryCode) async {
    await LocalDb.settings.put('countryCode', countryCode);
    state = countryCode;
  }
}

final countryProvider = StateNotifierProvider<CountryController, String>(
  (ref) => CountryController(),
);

import '../constants/dukani_countries.dart';
import '../offline/local_db.dart';

/// The currency symbol every amount in the app should be labelled with —
/// reads the merchant's own country directly from local storage so call
/// sites don't need Riverpod/BuildContext just to print a price correctly.
/// Mirrors CountryController's own read-with-fallback logic exactly, since
/// both must agree on what "no country set yet" means.
String currentCurrencySymbol() {
  final code = LocalDb.settings.get('countryCode') as String?;
  final country = dukaniCountries.firstWhere(
    (c) => c.code == code,
    orElse: () => dukaniCountries.first,
  );
  return country.currencySymbol;
}

/// The ISO currency code (e.g. 'SAR', 'EGP') for the merchant's own
/// country — what gateway APIs expect, as opposed to [currentCurrencySymbol]
/// which is for on-screen display.
String currentCurrencyCode() {
  final code = LocalDb.settings.get('countryCode') as String?;
  final country = dukaniCountries.firstWhere(
    (c) => c.code == code,
    orElse: () => dukaniCountries.first,
  );
  return country.currencyCode;
}

/// The VAT/tax percentage for the merchant's own country (see
/// [DukaniCountry.defaultTaxRate]) — the rate the cart should actually
/// charge, instead of assuming every merchant is in a 15%-VAT country.
double currentDefaultTaxRatePercent() {
  final code = LocalDb.settings.get('countryCode') as String?;
  final country = dukaniCountries.firstWhere(
    (c) => c.code == code,
    orElse: () => dukaniCountries.first,
  );
  return country.defaultTaxRate;
}

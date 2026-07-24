/// Country -> currency/tax defaults shown during store setup.
///
/// The list itself is no longer hard-coded to a fixed launch set: it starts
/// from the defaults below (so the app works offline on first install with
/// zero network calls), then [applyCountryCatalog] overwrites it once the
/// Super Admin-managed `countries` collection has been pulled from Firestore
/// (see `country_catalog_sync.dart`). Every existing call site keeps reading
/// the plain `dukaniCountries` list exactly as before — only the one place
/// that populates it changed, so expanding into a new country/currency/tax
/// rate is a Super Admin panel edit, not an app-store release.
class DukaniCountry {
  const DukaniCountry({
    required this.code,
    required this.nameAr,
    required this.flag,
    required this.currencyCode,
    required this.currencyNameAr,
    required this.currencySymbol,
    required this.defaultTaxRate,
    required this.taxNameAr,
  });

  final String code;
  final String nameAr;
  final String flag;
  final String currencyCode;
  final String currencyNameAr;

  /// Short Arabic abbreviation shown next to every amount in the app
  /// (invoices, cart, reports...) — e.g. "ر.س", not the full currency name.
  final String currencySymbol;
  final double defaultTaxRate;
  final String taxNameAr;

  Map<String, dynamic> toJson() => {
        'code': code,
        'nameAr': nameAr,
        'flag': flag,
        'currencyCode': currencyCode,
        'currencyNameAr': currencyNameAr,
        'currencySymbol': currencySymbol,
        'defaultTaxRate': defaultTaxRate,
        'taxNameAr': taxNameAr,
      };

  factory DukaniCountry.fromJson(Map<String, dynamic> json) => DukaniCountry(
        code: json['code'] as String,
        nameAr: json['nameAr'] as String,
        flag: json['flag'] as String,
        currencyCode: json['currencyCode'] as String,
        currencyNameAr: json['currencyNameAr'] as String,
        currencySymbol: json['currencySymbol'] as String,
        defaultTaxRate: (json['defaultTaxRate'] as num).toDouble(),
        taxNameAr: json['taxNameAr'] as String,
      );
}

const List<DukaniCountry> defaultDukaniCountries = [
  DukaniCountry(code: 'SA', nameAr: 'السعودية', flag: '🇸🇦', currencyCode: 'SAR', currencyNameAr: 'ريال سعودي', currencySymbol: 'ر.س', defaultTaxRate: 15, taxNameAr: 'ضريبة القيمة المضافة'),
  DukaniCountry(code: 'AE', nameAr: 'الإمارات', flag: '🇦🇪', currencyCode: 'AED', currencyNameAr: 'درهم إماراتي', currencySymbol: 'درهم', defaultTaxRate: 5, taxNameAr: 'ضريبة القيمة المضافة'),
  DukaniCountry(code: 'EG', nameAr: 'مصر', flag: '🇪🇬', currencyCode: 'EGP', currencyNameAr: 'جنيه مصري', currencySymbol: 'جنيه', defaultTaxRate: 14, taxNameAr: 'ضريبة القيمة المضافة'),
  DukaniCountry(code: 'JO', nameAr: 'الأردن', flag: '🇯🇴', currencyCode: 'JOD', currencyNameAr: 'دينار أردني', currencySymbol: 'د.أ', defaultTaxRate: 16, taxNameAr: 'ضريبة المبيعات العامة'),
  DukaniCountry(code: 'KW', nameAr: 'الكويت', flag: '🇰🇼', currencyCode: 'KWD', currencyNameAr: 'دينار كويتي', currencySymbol: 'د.ك', defaultTaxRate: 0, taxNameAr: 'لا يوجد ضريبة'),
  DukaniCountry(code: 'QA', nameAr: 'قطر', flag: '🇶🇦', currencyCode: 'QAR', currencyNameAr: 'ريال قطري', currencySymbol: 'ر.ق', defaultTaxRate: 0, taxNameAr: 'لا يوجد ضريبة'),
  DukaniCountry(code: 'OM', nameAr: 'عُمان', flag: '🇴🇲', currencyCode: 'OMR', currencyNameAr: 'ريال عُماني', currencySymbol: 'ر.ع', defaultTaxRate: 5, taxNameAr: 'ضريبة القيمة المضافة'),
  DukaniCountry(code: 'BH', nameAr: 'البحرين', flag: '🇧🇭', currencyCode: 'BHD', currencyNameAr: 'دينار بحريني', currencySymbol: 'د.ب', defaultTaxRate: 10, taxNameAr: 'ضريبة القيمة المضافة'),
];

List<DukaniCountry> _catalog = List.of(defaultDukaniCountries);

/// Every existing call site (`dukaniCountries.first`, `.firstWhere(...)`,
/// `.any(...)`) keeps working unchanged — this used to be the `const` list
/// itself and is now a getter over the mutable, Firestore-refreshable copy.
List<DukaniCountry> get dukaniCountries => _catalog;

/// Called by `country_catalog_sync.dart` once the cached-or-cloud list is
/// known. Ignores an empty list on purpose — an empty Super Admin catalog
/// (e.g. transient read failure) must never leave the app with zero
/// countries to pick from.
void applyCountryCatalog(List<DukaniCountry> countries) {
  if (countries.isEmpty) return;
  _catalog = countries;
}

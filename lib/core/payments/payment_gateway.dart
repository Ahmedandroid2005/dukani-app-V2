/// A payment gateway integration Dukani can route a charge through. Each
/// provider declares which countries it settles in and which payment
/// methods it actually processes there — adding a new gateway or country
/// later means adding one entry below, not touching the checkout screen.
///
/// Security boundary: the actual charge call lives server-side, in the
/// `createCharge`/`getChargeStatus` Cloud Functions (functions/src/index.ts)
/// — never here. A decompiled APK/IPA would leak any secret key embedded in
/// the app, letting anyone charge or refund against the merchant's account,
/// so this class only ever declares *which* gateways exist and what they
/// support; see [ChargeRepository] for how a charge is actually made.
abstract class PaymentGatewayProvider {
  const PaymentGatewayProvider();

  String get id;
  String get displayName;
  List<String> get supportedCountryCodes;

  /// Payment method ids (e.g. 'card', 'apple_pay', 'mada', 'knet') this
  /// gateway actually processes. A method not listed here stays in the
  /// "قريبًا" preview strip even after this gateway is connected.
  Set<String> get supportedMethodIds;
}

class StripeGateway extends PaymentGatewayProvider {
  const StripeGateway();
  @override
  String get id => 'stripe';
  @override
  String get displayName => 'Stripe';
  // Card networks + Apple/Google Pay work internationally regardless of
  // merchant country — Stripe isn't tied to a GCC/Egypt-specific footprint
  // the way the regional gateways below are.
  @override
  List<String> get supportedCountryCodes => const ['SA', 'AE', 'EG', 'JO', 'KW', 'QA', 'OM', 'BH'];
  @override
  Set<String> get supportedMethodIds => const {'card', 'apple_pay', 'google_pay'};
}

class TapPaymentsGateway extends PaymentGatewayProvider {
  const TapPaymentsGateway();
  @override
  String get id => 'tap';
  @override
  String get displayName => 'Tap Payments';
  @override
  List<String> get supportedCountryCodes => const ['SA', 'AE', 'KW', 'BH', 'QA', 'OM', 'JO'];
  @override
  Set<String> get supportedMethodIds => const {'card', 'apple_pay', 'mada', 'stc_pay', 'knet', 'benefit', 'omannet'};
}

class PayTabsGateway extends PaymentGatewayProvider {
  const PayTabsGateway();
  @override
  String get id => 'paytabs';
  @override
  String get displayName => 'PayTabs';
  @override
  List<String> get supportedCountryCodes => const ['SA', 'AE', 'KW', 'BH', 'QA', 'OM', 'EG', 'JO'];
  @override
  Set<String> get supportedMethodIds => const {'card', 'apple_pay'};
}

class PaymobGateway extends PaymentGatewayProvider {
  const PaymobGateway();
  @override
  String get id => 'paymob';
  @override
  String get displayName => 'Paymob';
  @override
  List<String> get supportedCountryCodes => const ['EG'];
  // Fawry/Meeza/e-wallet each need their own Paymob "integration id" (set up
  // separately per method in Paymob's dashboard), but functions/src/gateways
  // /paymob.ts only stores and calls a single integration id per merchant —
  // so today it can only ever actually charge a card, regardless of what a
  // tile here might imply. Listing the others would be a tile that looks
  // selectable but silently falls back to a card charge.
  @override
  Set<String> get supportedMethodIds => const {'card'};
}

/// The one gateway here that covers all 8 target countries with a single
/// merchant account (Kuwait, Saudi, UAE, Qatar, Bahrain, Oman, Jordan,
/// Egypt) — see functions/src/gateways/myfatoorah.ts.
class MyFatoorahGateway extends PaymentGatewayProvider {
  const MyFatoorahGateway();
  @override
  String get id => 'myfatoorah';
  @override
  String get displayName => 'MyFatoorah';
  @override
  List<String> get supportedCountryCodes => const ['SA', 'AE', 'EG', 'JO', 'KW', 'QA', 'OM', 'BH'];
  @override
  Set<String> get supportedMethodIds => const {'card', 'apple_pay'};
}

class HyperPayGateway extends PaymentGatewayProvider {
  const HyperPayGateway();
  @override
  String get id => 'hyperpay';
  @override
  String get displayName => 'HyperPay';
  @override
  List<String> get supportedCountryCodes => const ['SA', 'AE', 'EG', 'JO'];
  @override
  Set<String> get supportedMethodIds => const {'card', 'apple_pay'};
}

/// Amazon Payment Services — still branded "FORT" under the hood; see
/// functions/src/gateways/aps.ts for why its integration shape (signed
/// redirect, not a JSON API) is the least standard of the ones here.
class AmazonPaymentServicesGateway extends PaymentGatewayProvider {
  const AmazonPaymentServicesGateway();
  @override
  String get id => 'aps';
  @override
  String get displayName => 'Amazon Payment Services';
  @override
  List<String> get supportedCountryCodes => const ['SA', 'AE', 'EG', 'JO'];
  @override
  Set<String> get supportedMethodIds => const {'card', 'apple_pay'};
}

class GeideaGateway extends PaymentGatewayProvider {
  const GeideaGateway();
  @override
  String get id => 'geidea';
  @override
  String get displayName => 'Geidea';
  @override
  List<String> get supportedCountryCodes => const ['SA', 'EG'];
  @override
  Set<String> get supportedMethodIds => const {'card', 'apple_pay'};
}

class TelrGateway extends PaymentGatewayProvider {
  const TelrGateway();
  @override
  String get id => 'telr';
  @override
  String get displayName => 'Telr';
  @override
  List<String> get supportedCountryCodes => const ['AE', 'SA'];
  @override
  Set<String> get supportedMethodIds => const {'card', 'apple_pay'};
}

/// Fawry Accept — Egypt's own direct online gateway. Distinct from the
/// 'fawry' payment *method* already routed through Paymob for merchants
/// who don't have their own Fawry account: this is for merchants who do.
class FawryGateway extends PaymentGatewayProvider {
  const FawryGateway();
  @override
  String get id => 'fawry';
  @override
  String get displayName => 'Fawry Accept';
  @override
  List<String> get supportedCountryCodes => const ['EG'];
  @override
  Set<String> get supportedMethodIds => const {'card', 'fawry'};
}

class MoyasarGateway extends PaymentGatewayProvider {
  const MoyasarGateway();
  @override
  String get id => 'moyasar';
  @override
  String get displayName => 'Moyasar';
  @override
  List<String> get supportedCountryCodes => const ['SA'];
  @override
  Set<String> get supportedMethodIds => const {'card', 'apple_pay', 'mada'};
}

class ThawaniGateway extends PaymentGatewayProvider {
  const ThawaniGateway();
  @override
  String get id => 'thawani';
  @override
  String get displayName => 'Thawani';
  @override
  List<String> get supportedCountryCodes => const ['OM'];
  @override
  Set<String> get supportedMethodIds => const {'card', 'apple_pay'};
}

class NetworkInternationalGateway extends PaymentGatewayProvider {
  const NetworkInternationalGateway();
  @override
  String get id => 'ni';
  @override
  String get displayName => 'Network International';
  @override
  List<String> get supportedCountryCodes => const ['AE'];
  @override
  Set<String> get supportedMethodIds => const {'card', 'apple_pay'};
}

/// Resolves gateways by country and by id. Registration order below is
/// preference order for [providerFor] — Paymob is checked first so it wins
/// for Egypt (it specializes there), Tap otherwise, with the rest as
/// progressively broader fallbacks and Stripe as the international option.
class PaymentGatewayRegistry {
  PaymentGatewayRegistry._();

  static const List<PaymentGatewayProvider> _providers = [
    PaymobGateway(),
    TapPaymentsGateway(),
    PayTabsGateway(),
    MyFatoorahGateway(),
    HyperPayGateway(),
    AmazonPaymentServicesGateway(),
    GeideaGateway(),
    TelrGateway(),
    FawryGateway(),
    MoyasarGateway(),
    ThawaniGateway(),
    NetworkInternationalGateway(),
    StripeGateway(),
  ];

  static PaymentGatewayProvider? providerFor(String countryCode) {
    for (final provider in _providers) {
      if (provider.supportedCountryCodes.contains(countryCode)) return provider;
    }
    return null;
  }

  /// Every gateway available in [countryCode], strongest/most recognized
  /// first — so a merchant picking from the "ربط بوابة الدفع" screen sees
  /// the option most other merchants in their own country actually use at
  /// the top, not whichever order gateways happen to be declared in code.
  /// Ranked from real usage/recognition signals per country (see the PR
  /// this shipped in) rather than being alphabetical or registration-order.
  static const Map<String, List<String>> _strengthOrderByCountry = {
    'SA': ['paytabs', 'tap', 'moyasar', 'hyperpay', 'myfatoorah', 'aps', 'geidea', 'telr', 'stripe'],
    'AE': ['tap', 'paytabs', 'ni', 'telr', 'aps', 'hyperpay', 'myfatoorah', 'stripe'],
    'EG': ['paymob', 'fawry', 'paytabs', 'hyperpay', 'geidea', 'aps', 'myfatoorah', 'stripe'],
    'JO': ['paytabs', 'hyperpay', 'aps', 'tap', 'myfatoorah', 'stripe'],
    'KW': ['tap', 'paytabs', 'myfatoorah', 'stripe'],
    'QA': ['tap', 'paytabs', 'myfatoorah', 'stripe'],
    'OM': ['thawani', 'tap', 'paytabs', 'myfatoorah', 'stripe'],
    'BH': ['tap', 'paytabs', 'myfatoorah', 'stripe'],
  };

  static List<PaymentGatewayProvider> availableFor(String countryCode) {
    final available = _providers.where((p) => p.supportedCountryCodes.contains(countryCode)).toList();
    final order = _strengthOrderByCountry[countryCode] ?? const [];
    available.sort((a, b) {
      final rankA = order.indexOf(a.id);
      final rankB = order.indexOf(b.id);
      return (rankA == -1 ? order.length : rankA).compareTo(rankB == -1 ? order.length : rankB);
    });
    return available;
  }

  static PaymentGatewayProvider? byId(String id) {
    for (final provider in _providers) {
      if (provider.id == id) return provider;
    }
    return null;
  }

  static List<PaymentGatewayProvider> get all => _providers;
}

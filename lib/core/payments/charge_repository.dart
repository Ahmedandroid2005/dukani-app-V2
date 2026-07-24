/// A hosted checkout session created by the `createCharge` Cloud Function —
/// [checkoutUrl] is opened in a WebView so the customer types their card on
/// the gateway's own page, never inside Dukani.
class ChargeSession {
  const ChargeSession({required this.checkoutUrl, required this.chargeId});
  final String checkoutUrl;
  final String chargeId;
}

enum ChargeStatus { succeeded, failed, pending }

/// Simple Arabic-message exception for anything that goes wrong starting or
/// checking a charge (no gateway connected, network failure, gateway error).
class ChargeException implements Exception {
  const ChargeException(this.message);
  final String message;
}

/// Routes a real charge through whichever gateway the merchant connected —
/// via the `createCharge`/`getChargeStatus` Cloud Functions, which are the
/// only code that ever holds the merchant's real gateway secret key.
abstract class ChargeRepository {
  Future<ChargeSession> createCharge({
    required double amount,
    required String currencyCode,
    required String methodId,
  });

  Future<ChargeStatus> getStatus(String chargeId);
}

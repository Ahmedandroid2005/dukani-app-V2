import 'payment_gateway.dart';

/// The merchant's own gateway account — their own Tap, PayTabs, Paymob, or
/// Stripe credentials, entered once in Settings. [extra] carries a second
/// value some gateways need alongside the key (PayTabs' profile id, or
/// Paymob's "integrationId:iframeId" pair) — see functions/src/gateways for
/// which gateways use it.
class ConnectedGateway {
  const ConnectedGateway({required this.gatewayId, required this.apiKey, this.extra});

  final String gatewayId;
  final String apiKey;
  final String? extra;

  PaymentGatewayProvider? get provider => PaymentGatewayRegistry.byId(gatewayId);

  Map<String, dynamic> toJson() => {
        'gatewayId': gatewayId,
        'apiKey': apiKey,
        if (extra != null) 'extra': extra,
      };

  factory ConnectedGateway.fromJson(Map<String, dynamic> json) => ConnectedGateway(
        gatewayId: json['gatewayId'] as String,
        apiKey: json['apiKey'] as String,
        extra: json['extra'] as String?,
      );
}

/// Stores the merchant's gateway credentials in Firestore so the
/// `chargePayment` Cloud Function can read them server-side (see
/// functions/src/index.ts) — the mobile app itself never calls a gateway
/// directly with them.
abstract class GatewayCredentialsRepository {
  Future<ConnectedGateway?> fetch(String orgId);
  Future<void> save(String orgId, ConnectedGateway gateway);
  Future<void> delete(String orgId);
}

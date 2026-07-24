/// A hosted checkout session for upgrading the store's own subscription
/// (the merchant paying Dukani) — see [SubscriptionRepository.createCheckout].
class SubscriptionCheckoutSession {
  const SubscriptionCheckoutSession({required this.checkoutUrl});
  final String checkoutUrl;
}

class SubscriptionException implements Exception {
  const SubscriptionException(this.message);
  final String message;
}

/// Routes subscription upgrades through the `createSubscriptionCheckout`
/// Cloud Function, and watches the plan Stripe's webhook actually confirmed
/// — never a value the client itself sets, since only Stripe's webhook is
/// trusted to say a subscription payment really went through (see
/// functions/src/subscription.ts).
abstract class SubscriptionRepository {
  Future<SubscriptionCheckoutSession> createCheckout(String planId);
  Stream<String?> watchPlan(String orgId);
}

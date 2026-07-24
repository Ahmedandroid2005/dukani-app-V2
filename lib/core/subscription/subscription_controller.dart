import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_providers.dart';
import '../organizations/org_controller.dart';
import '../payments/charge_controller.dart' show firebaseFunctionsProvider;
import 'firebase_subscription_repository.dart';
import 'subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => FirebaseSubscriptionRepository(ref.watch(firebaseFunctionsProvider), ref.watch(firestoreProvider)),
);

/// The organization's current plan id ('starter'/'pro'/'business'), or null
/// before any subscription has ever been confirmed by Stripe's webhook.
/// Updates live — the subscription screen doesn't need a manual refresh
/// after checkout, it just watches this.
final currentPlanProvider = StreamProvider<String?>((ref) {
  final orgId = ref.watch(currentOrgIdProvider).valueOrNull;
  if (orgId == null) return Stream.value(null);
  return ref.watch(subscriptionRepositoryProvider).watchPlan(orgId);
});

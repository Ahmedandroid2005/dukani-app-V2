import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../payments/charge_controller.dart' show firebaseFunctionsProvider;
import '../store/store_profile_controller.dart' show firestoreProvider;
import 'firebase_subscription_repository.dart';
import 'subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => FirebaseSubscriptionRepository(ref.watch(firebaseFunctionsProvider), ref.watch(firestoreProvider)),
);

/// The store's current plan id ('starter'/'pro'/'business'), or null before
/// any subscription has ever been confirmed by Stripe's webhook. Updates
/// live — the subscription screen doesn't need a manual refresh after
/// checkout, it just watches this.
final currentPlanProvider = StreamProvider<String?>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(subscriptionRepositoryProvider).watchPlan(uid);
});

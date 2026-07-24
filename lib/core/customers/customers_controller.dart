import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_models.dart';
import '../auth/auth_controller.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

/// Points awarded to both the referrer and the new customer when a
/// referral code is applied.
const referralBonusPoints = 50;

/// Mutable customer directory. Starts empty — every customer here is one
/// the merchant actually added, never a demo record.
class CustomersController extends FirestoreSyncedListNotifier<MockCustomer> {
  CustomersController(String? ownerUid)
      : super(
          box: LocalDb.customers,
          seed: const [],
          toJson: (c) => c.toJson(),
          fromJson: MockCustomer.fromJson,
          ownerUid: ownerUid,
          collectionName: 'customers',
        );

  void add(MockCustomer customer) => state = [...state, customer];

  void update(String id, MockCustomer updated) {
    state = [for (final c in state) c.id == id ? updated : c];
  }

  void remove(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  /// Records a debt payment — clamps at zero so an over-payment can't flip
  /// the balance negative.
  void settleDebt(String id, double amount) {
    state = [for (final c in state) c.id == id ? c.copyWith(debt: (c.debt - amount).clamp(0, double.infinity)) : c];
  }

  void addPoints(String id, int points) {
    state = [for (final c in state) c.id == id ? c.copyWith(loyaltyPoints: c.loyaltyPoints + points) : c];
  }

  /// Redeeming clamps at zero so a customer can never redeem more points
  /// than their balance.
  void redeemPoints(String id, int points) {
    state = [for (final c in state) c.id == id ? c.copyWith(loyaltyPoints: (c.loyaltyPoints - points).clamp(0, 1 << 31)) : c];
  }

  MockCustomer? byId(String id) {
    for (final c in state) {
      if (c.id == id) return c;
    }
    return null;
  }

  MockCustomer? byReferralCode(String code) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    for (final c in state) {
      if (c.referralCode.toUpperCase() == normalized) return c;
    }
    return null;
  }

  String generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    String code;
    do {
      code = List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
    } while (state.any((c) => c.referralCode == code));
    return code;
  }

  /// Awards the referral bonus to both sides of a completed referral.
  void applyReferralBonus(String newCustomerId, String referrerId) {
    state = [
      for (final c in state)
        if (c.id == newCustomerId || c.id == referrerId)
          c.copyWith(loyaltyPoints: c.loyaltyPoints + referralBonusPoints)
        else
          c,
    ];
  }

  String nextId() {
    var n = state.length + 1;
    while (state.any((c) => c.id == 'c$n')) {
      n++;
    }
    return 'c$n';
  }
}

final customersProvider = StateNotifierProvider<CustomersController, List<MockCustomer>>(
  (ref) => CustomersController(ref.watch(authStateProvider).valueOrNull?.uid),
);

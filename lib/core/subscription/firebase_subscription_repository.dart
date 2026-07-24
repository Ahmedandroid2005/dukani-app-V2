import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'subscription_repository.dart';

/// The only file that imports `cloud_functions`/`cloud_firestore` for
/// subscriptions — everything else talks to [SubscriptionRepository].
class FirebaseSubscriptionRepository implements SubscriptionRepository {
  FirebaseSubscriptionRepository(this._functions, this._firestore);
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  @override
  Future<SubscriptionCheckoutSession> createCheckout(String planId) async {
    try {
      final result = await _functions.httpsCallable('createSubscriptionCheckout').call<Map<String, dynamic>>({
        'planId': planId,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return SubscriptionCheckoutSession(checkoutUrl: data['checkoutUrl'] as String);
    } on FirebaseFunctionsException catch (e) {
      throw SubscriptionException(_messageFor(e));
    }
  }

  @override
  Stream<String?> watchPlan(String ownerUid) {
    return _firestore.collection('stores').doc(ownerUid).snapshots().map((snapshot) => snapshot.data()?['plan'] as String?);
  }

  String _messageFor(FirebaseFunctionsException e) => switch (e.code) {
        'unauthenticated' => 'الرجاء تسجيل الدخول أولاً.',
        'failed-precondition' => e.message ?? 'تعذر تحديد سعر الباقة لبلدك.',
        'invalid-argument' => 'باقة غير معروفة.',
        'internal' => e.message ?? 'تعذّر فتح صفحة الدفع، حاول مرة أخرى.',
        _ => 'تعذّر فتح صفحة الدفع، حاول مرة أخرى.',
      };
}

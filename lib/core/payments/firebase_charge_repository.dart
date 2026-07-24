import 'package:cloud_functions/cloud_functions.dart';

import 'charge_repository.dart';

/// The only file that imports `cloud_functions` — everything else talks to
/// [ChargeRepository]. Calls the callable functions in functions/src/index.ts.
class FirebaseChargeRepository implements ChargeRepository {
  FirebaseChargeRepository(this._functions);
  final FirebaseFunctions _functions;

  @override
  Future<ChargeSession> createCharge({
    required double amount,
    required String currencyCode,
    required String methodId,
  }) async {
    try {
      final result = await _functions.httpsCallable('createCharge').call<Map<String, dynamic>>({
        'amount': amount,
        'currencyCode': currencyCode,
        'methodId': methodId,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      return ChargeSession(checkoutUrl: data['checkoutUrl'] as String, chargeId: data['chargeId'] as String);
    } on FirebaseFunctionsException catch (e) {
      throw ChargeException(_messageFor(e));
    }
  }

  @override
  Future<ChargeStatus> getStatus(String chargeId) async {
    try {
      final result = await _functions.httpsCallable('getChargeStatus').call<Map<String, dynamic>>({
        'chargeId': chargeId,
      });
      final status = Map<String, dynamic>.from(result.data as Map)['status'] as String;
      return switch (status) {
        'succeeded' => ChargeStatus.succeeded,
        'failed' => ChargeStatus.failed,
        _ => ChargeStatus.pending,
      };
    } on FirebaseFunctionsException catch (e) {
      throw ChargeException(_messageFor(e));
    }
  }

  String _messageFor(FirebaseFunctionsException e) => switch (e.code) {
        'failed-precondition' => e.message ?? 'لا يوجد بوابة دفع مربوطة بحسابك بعد.',
        'unauthenticated' => 'الرجاء تسجيل الدخول أولاً.',
        'not-found' => 'لم يتم العثور على عملية الدفع.',
        'invalid-argument' => e.message ?? 'بيانات الدفع غير صحيحة.',
        'internal' => e.message ?? 'تعذّر إتمام الدفع، حاول مرة أخرى.',
        _ => 'تعذّر إتمام الدفع، حاول مرة أخرى.',
      };
}

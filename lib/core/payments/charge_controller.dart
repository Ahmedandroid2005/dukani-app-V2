import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'charge_repository.dart';
import 'firebase_charge_repository.dart';

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) => FirebaseFunctions.instance);

final chargeRepositoryProvider = Provider<ChargeRepository>(
  (ref) => FirebaseChargeRepository(ref.watch(firebaseFunctionsProvider)),
);

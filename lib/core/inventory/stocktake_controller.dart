import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../organizations/org_controller.dart';
import '../offline/firestore_json.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

class StocktakeVariance {
  const StocktakeVariance({required this.productName, required this.systemStock, required this.countedStock});
  final String productName;
  final int systemStock;
  final int countedStock;

  int get diff => countedStock - systemStock;

  Map<String, dynamic> toJson() => {'productName': productName, 'systemStock': systemStock, 'countedStock': countedStock};

  factory StocktakeVariance.fromJson(Map<String, dynamic> json) => StocktakeVariance(
        productName: json['productName'] as String,
        systemStock: json['systemStock'] as int,
        countedStock: json['countedStock'] as int,
      );
}

/// One completed stocktake session — real record of what was actually
/// recounted and what didn't match, so "متى آخر جرد" and "فروقات مكتشفة"
/// in the Stocktake report reflect a real event instead of always saying
/// nothing happened.
class StocktakeRecord {
  const StocktakeRecord({required this.id, required this.completedAt, required this.variances});
  final String id;
  final DateTime completedAt;
  final List<StocktakeVariance> variances;

  Map<String, dynamic> toJson() => {'id': id, 'completedAt': completedAt, 'variances': variances.map((v) => v.toJson()).toList()};

  factory StocktakeRecord.fromJson(Map<String, dynamic> json) => StocktakeRecord(
        id: json['id'] as String,
        completedAt: asDateTime(json['completedAt']) ?? DateTime.now(),
        variances: (json['variances'] as List? ?? []).map((raw) => StocktakeVariance.fromJson(Map<String, dynamic>.from(raw as Map))).toList(),
      );
}

class StocktakeController extends FirestoreSyncedListNotifier<StocktakeRecord> {
  StocktakeController(String? orgId)
      : super(box: LocalDb.stocktakes, seed: const [], toJson: (s) => s.toJson(), fromJson: StocktakeRecord.fromJson, orgId: orgId, collectionName: 'stocktakes');

  void record(List<StocktakeVariance> variances) {
    state = [
      StocktakeRecord(id: DateTime.now().microsecondsSinceEpoch.toString(), completedAt: DateTime.now(), variances: variances),
      ...state,
    ];
  }
}

final stocktakeProvider = StateNotifierProvider<StocktakeController, List<StocktakeRecord>>(
  (ref) => StocktakeController(ref.watch(currentOrgIdProvider).valueOrNull),
);

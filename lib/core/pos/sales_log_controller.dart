import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../offline/firestore_json.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

class SaleLine {
  const SaleLine({required this.productId, required this.productName, required this.qty, required this.price, required this.cost});
  final String productId;
  /// Snapshotted at sale time, same as the printed receipt — so this line
  /// still reads correctly even if the product is later renamed or deleted,
  /// instead of a live join back to the catalog going stale or missing.
  final String productName;
  final int qty;
  final double price;
  final double cost;

  double get revenue => price * qty;
  double get profit => (price - cost) * qty;

  Map<String, dynamic> toJson() => {'productId': productId, 'productName': productName, 'qty': qty, 'price': price, 'cost': cost};

  factory SaleLine.fromJson(Map<String, dynamic> json) => SaleLine(
        productId: json['productId'] as String,
        productName: json['productName'] as String? ?? '',
        qty: json['qty'] as int,
        price: (json['price'] as num).toDouble(),
        cost: (json['cost'] as num).toDouble(),
      );
}

class SaleRecord {
  const SaleRecord({
    required this.id,
    required this.lines,
    required this.total,
    required this.methodLabel,
    required this.createdAt,
    this.customerName,
    this.cashierName,
    this.taxAmount = 0,
    this.discountAmount = 0,
  });
  final String id;
  final List<SaleLine> lines;
  final double total;
  final String methodLabel;
  final DateTime createdAt;
  /// Null for a walk-in/cash sale with no customer picked — the merchant
  /// app's own convention is to display "عميل نقدي" for that case rather
  /// than storing that literal string here.
  final String? customerName;
  /// Whoever was signed in at checkout — the employee if one is logged in
  /// via the employee-login flow, otherwise the store owner.
  final String? cashierName;
  /// Tax actually charged on this sale (0 if the merchant has tax off) —
  /// snapshotted from the cart at checkout so a later tax-rate change
  /// never rewrites what an old receipt actually charged.
  final double taxAmount;
  /// Discount actually applied to this sale's subtotal, in currency.
  final double discountAmount;

  double get profit => lines.fold(0.0, (s, l) => s + l.profit);
  double get cost => lines.fold(0.0, (s, l) => s + l.cost * l.qty);
  int get itemCount => lines.fold(0, (s, l) => s + l.qty);

  Map<String, dynamic> toJson() => {
        'id': id,
        'lines': lines.map((l) => l.toJson()).toList(),
        'total': total,
        'methodLabel': methodLabel,
        'createdAt': createdAt,
        if (customerName != null) 'customerName': customerName,
        if (cashierName != null) 'cashierName': cashierName,
        'taxAmount': taxAmount,
        'discountAmount': discountAmount,
      };

  factory SaleRecord.fromJson(Map<String, dynamic> json) => SaleRecord(
        id: json['id'] as String,
        lines: (json['lines'] as List).map((raw) => SaleLine.fromJson(Map<String, dynamic>.from(raw as Map))).toList(),
        total: (json['total'] as num).toDouble(),
        methodLabel: json['methodLabel'] as String,
        createdAt: asDateTime(json['createdAt']) ?? DateTime.now(),
        customerName: json['customerName'] as String?,
        cashierName: json['cashierName'] as String?,
        taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      );
}

/// Log of sales actually completed this session through the real POS flow —
/// feeds the "live" KPIs on the sales/profit reports so entering real
/// products and selling them visibly moves those numbers, instead of the
/// reports staying fixed demo figures forever.
class SalesLogController extends FirestoreSyncedListNotifier<SaleRecord> {
  SalesLogController(String? ownerUid)
      : super(box: LocalDb.salesLog, seed: const [], toJson: (s) => s.toJson(), fromJson: SaleRecord.fromJson, ownerUid: ownerUid, collectionName: 'salesLog');

  void record(SaleRecord sale) => state = [sale, ...state];
}

final salesLogProvider = StateNotifierProvider<SalesLogController, List<SaleRecord>>(
  (ref) => SalesLogController(ref.watch(authStateProvider).valueOrNull?.uid),
);

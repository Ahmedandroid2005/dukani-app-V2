import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../organizations/org_controller.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

class PurchaseItem {
  const PurchaseItem({required this.productId, required this.productName, required this.qty, required this.cost});
  final String productId;
  final String productName;
  final int qty;
  final double cost;

  double get lineTotal => qty * cost;

  Map<String, dynamic> toJson() => {'productId': productId, 'productName': productName, 'qty': qty, 'cost': cost};

  factory PurchaseItem.fromJson(Map<String, dynamic> json) => PurchaseItem(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        qty: json['qty'] as int,
        cost: (json['cost'] as num).toDouble(),
      );
}

class MockPurchaseOrder {
  const MockPurchaseOrder({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.items,
    required this.date,
    this.received = false,
  });

  final String id;
  final String supplierId;
  final String supplierName;
  final List<PurchaseItem> items;
  final String date;
  final bool received;

  double get total => items.fold(0.0, (s, i) => s + i.lineTotal);

  MockPurchaseOrder copyWith({bool? received}) => MockPurchaseOrder(
        id: id,
        supplierId: supplierId,
        supplierName: supplierName,
        items: items,
        date: date,
        received: received ?? this.received,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'items': items.map((i) => i.toJson()).toList(),
        'date': date,
        'received': received,
      };

  factory MockPurchaseOrder.fromJson(Map<String, dynamic> json) => MockPurchaseOrder(
        id: json['id'] as String,
        supplierId: json['supplierId'] as String,
        supplierName: json['supplierName'] as String,
        items: (json['items'] as List).map((raw) => PurchaseItem.fromJson(Map<String, dynamic>.from(raw as Map))).toList(),
        date: json['date'] as String,
        received: json['received'] as bool,
      );
}

class PurchaseOrdersController extends FirestoreSyncedListNotifier<MockPurchaseOrder> {
  PurchaseOrdersController(String? orgId)
      : super(
          box: LocalDb.purchaseOrders,
          seed: const [],
          toJson: (o) => o.toJson(),
          fromJson: MockPurchaseOrder.fromJson,
          orgId: orgId,
          collectionName: 'purchaseOrders',
        );

  void create(MockPurchaseOrder order) => state = [order, ...state];

  void markReceived(String id) {
    state = [for (final o in state) o.id == id ? o.copyWith(received: true) : o];
  }
}

final purchaseOrdersProvider = StateNotifierProvider<PurchaseOrdersController, List<MockPurchaseOrder>>(
  (ref) => PurchaseOrdersController(ref.watch(currentOrgIdProvider).valueOrNull),
);

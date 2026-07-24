import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

const orderStatuses = ['جديد', 'قيد التجهيز', 'جاهز', 'مكتمل'];

class OrderItem {
  const OrderItem({required this.productId, required this.productName, required this.qty, required this.price});
  final String productId;
  final String productName;
  final int qty;
  final double price;

  double get lineTotal => qty * price;

  Map<String, dynamic> toJson() => {'productId': productId, 'productName': productName, 'qty': qty, 'price': price};

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        qty: json['qty'] as int,
        price: (json['price'] as num).toDouble(),
      );
}

class MockCustomerOrder {
  const MockCustomerOrder({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.items,
    required this.date,
    this.notes = '',
    this.status = 'جديد',
  });

  final String id;
  final String customerName;
  final String phone;
  final List<OrderItem> items;
  final String date;
  final String notes;
  final String status;

  double get total => items.fold(0.0, (s, i) => s + i.lineTotal);

  MockCustomerOrder copyWith({String? status}) => MockCustomerOrder(
        id: id,
        customerName: customerName,
        phone: phone,
        items: items,
        date: date,
        notes: notes,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'phone': phone,
        'items': items.map((i) => i.toJson()).toList(),
        'date': date,
        'notes': notes,
        'status': status,
      };

  factory MockCustomerOrder.fromJson(Map<String, dynamic> json) => MockCustomerOrder(
        id: json['id'] as String,
        customerName: json['customerName'] as String,
        phone: json['phone'] as String,
        items: (json['items'] as List).map((raw) => OrderItem.fromJson(Map<String, dynamic>.from(raw as Map))).toList(),
        date: json['date'] as String,
        notes: json['notes'] as String,
        status: json['status'] as String,
      );
}

/// A queue for phone-in / pre-orders that need fulfillment before the
/// customer picks up — distinct from an immediate POS checkout, which
/// completes in one pass and never sits in a "قيد التجهيز" state.
class OrdersController extends FirestoreSyncedListNotifier<MockCustomerOrder> {
  OrdersController(String? ownerUid)
      : super(box: LocalDb.orders, seed: const [], toJson: (o) => o.toJson(), fromJson: MockCustomerOrder.fromJson, ownerUid: ownerUid, collectionName: 'orders');

  void create(MockCustomerOrder order) => state = [order, ...state];

  void advanceStatus(String id) {
    state = [
      for (final o in state)
        if (o.id == id)
          o.copyWith(status: orderStatuses[(orderStatuses.indexOf(o.status) + 1).clamp(0, orderStatuses.length - 1)])
        else
          o,
    ];
  }
}

final ordersProvider = StateNotifierProvider<OrdersController, List<MockCustomerOrder>>(
  (ref) => OrdersController(ref.watch(authStateProvider).valueOrNull?.uid),
);

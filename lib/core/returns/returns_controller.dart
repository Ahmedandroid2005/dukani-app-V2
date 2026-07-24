import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_models.dart';
import '../organizations/org_controller.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

const returnReasons = ['منتج تالف', 'غير مطابق للطلب', 'عدل العميل رأيه', 'أخرى'];
const refundMethods = ['نقدًا', 'إرجاع للبطاقة', 'رصيد للعميل'];

class MockReturn {
  const MockReturn({
    required this.id,
    required this.invoiceId,
    required this.customerName,
    required this.items,
    required this.refundAmount,
    required this.reason,
    required this.refundMethod,
    required this.date,
  });

  final String id;
  final String invoiceId;
  final String customerName;
  final List<MockInvoiceItem> items;
  final double refundAmount;
  final String reason;
  final String refundMethod;
  final String date;

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceId': invoiceId,
        'customerName': customerName,
        'items': items.map((i) => i.toJson()).toList(),
        'refundAmount': refundAmount,
        'reason': reason,
        'refundMethod': refundMethod,
        'date': date,
      };

  factory MockReturn.fromJson(Map<String, dynamic> json) => MockReturn(
        id: json['id'] as String,
        invoiceId: json['invoiceId'] as String,
        customerName: json['customerName'] as String,
        items: (json['items'] as List).map((raw) => MockInvoiceItem.fromJson(Map<String, dynamic>.from(raw as Map))).toList(),
        refundAmount: (json['refundAmount'] as num).toDouble(),
        reason: json['reason'] as String,
        refundMethod: json['refundMethod'] as String,
        date: json['date'] as String,
      );
}

class ReturnsController extends FirestoreSyncedListNotifier<MockReturn> {
  ReturnsController(String? orgId)
      : super(box: LocalDb.returns, seed: const [], toJson: (r) => r.toJson(), fromJson: MockReturn.fromJson, orgId: orgId, collectionName: 'returns');

  void create(MockReturn ret) => state = [ret, ...state];
}

final returnsProvider = StateNotifierProvider<ReturnsController, List<MockReturn>>(
  (ref) => ReturnsController(ref.watch(currentOrgIdProvider).valueOrNull),
);

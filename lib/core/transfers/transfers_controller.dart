import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../offline/firestore_synced_list_notifier.dart';
import '../offline/local_db.dart';

class TransferItem {
  const TransferItem({required this.productId, required this.productName, required this.qty});
  final String productId;
  final String productName;
  final int qty;

  Map<String, dynamic> toJson() => {'productId': productId, 'productName': productName, 'qty': qty};

  factory TransferItem.fromJson(Map<String, dynamic> json) =>
      TransferItem(productId: json['productId'] as String, productName: json['productName'] as String, qty: json['qty'] as int);
}

class MockBranchTransfer {
  const MockBranchTransfer({
    required this.id,
    required this.fromBranchId,
    required this.fromBranchName,
    required this.toBranchId,
    required this.toBranchName,
    required this.items,
    required this.date,
    this.received = false,
  });

  final String id;
  final String fromBranchId;
  final String fromBranchName;
  final String toBranchId;
  final String toBranchName;
  final List<TransferItem> items;
  final String date;
  final bool received;

  MockBranchTransfer copyWith({bool? received}) => MockBranchTransfer(
        id: id,
        fromBranchId: fromBranchId,
        fromBranchName: fromBranchName,
        toBranchId: toBranchId,
        toBranchName: toBranchName,
        items: items,
        date: date,
        received: received ?? this.received,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromBranchId': fromBranchId,
        'fromBranchName': fromBranchName,
        'toBranchId': toBranchId,
        'toBranchName': toBranchName,
        'items': items.map((i) => i.toJson()).toList(),
        'date': date,
        'received': received,
      };

  factory MockBranchTransfer.fromJson(Map<String, dynamic> json) => MockBranchTransfer(
        id: json['id'] as String,
        fromBranchId: json['fromBranchId'] as String,
        fromBranchName: json['fromBranchName'] as String,
        toBranchId: json['toBranchId'] as String,
        toBranchName: json['toBranchName'] as String,
        items: (json['items'] as List).map((raw) => TransferItem.fromJson(Map<String, dynamic>.from(raw as Map))).toList(),
        date: json['date'] as String,
        received: json['received'] as bool,
      );
}

/// Records stock movements between branches. This phase doesn't maintain
/// a per-branch stock ledger (products carry one global quantity), so a
/// transfer is a paper trail — a log of what moved and when — rather than
/// something that debits one branch's count and credits another's.
class TransfersController extends FirestoreSyncedListNotifier<MockBranchTransfer> {
  TransfersController(String? ownerUid)
      : super(box: LocalDb.transfers, seed: const [], toJson: (t) => t.toJson(), fromJson: MockBranchTransfer.fromJson, ownerUid: ownerUid, collectionName: 'transfers');

  void create(MockBranchTransfer transfer) => state = [transfer, ...state];

  void markReceived(String id) {
    state = [for (final t in state) t.id == id ? t.copyWith(received: true) : t];
  }
}

final transfersProvider = StateNotifierProvider<TransfersController, List<MockBranchTransfer>>(
  (ref) => TransfersController(ref.watch(authStateProvider).valueOrNull?.uid),
);

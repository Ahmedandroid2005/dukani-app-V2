import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';

class SupportChatMessage {
  const SupportChatMessage({required this.id, required this.sender, required this.text, required this.sentAt});

  final String id;

  /// 'merchant' or 'admin' — enforced server-side by firestore.rules, which
  /// only lets each side author messages under their own name.
  final String sender;
  final String text;
  final DateTime sentAt;

  bool get fromMerchant => sender == 'merchant';

  factory SupportChatMessage.fromDoc(String id, Map<String, dynamic> data) => SupportChatMessage(
        id: id,
        sender: data['sender'] as String? ?? 'merchant',
        text: data['text'] as String? ?? '',
        sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

CollectionReference<Map<String, dynamic>>? _messagesCollection(String? ownerUid) {
  if (ownerUid == null) return null;
  return FirebaseFirestore.instance.collection('stores').doc(ownerUid).collection('data').doc('supportChat').collection('messages');
}

/// One real-time chat thread per store with دُكاني's own support team —
/// unlike every other synced list in the app (see
/// FirestoreSyncedListNotifier's "pull once on launch" model), a chat has
/// to show the other side's messages as they arrive, so this listens live
/// instead of only refreshing on next app open.
final supportChatProvider = StreamProvider<List<SupportChatMessage>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  final collection = _messagesCollection(uid);
  if (collection == null) return Stream.value(const []);
  return collection.orderBy('sentAt').snapshots().map(
        (snapshot) => snapshot.docs.map((d) => SupportChatMessage.fromDoc(d.id, d.data())).toList(),
      );
});

class SupportChatController {
  SupportChatController(this._ref);
  final Ref _ref;

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final uid = _ref.read(authStateProvider).valueOrNull?.uid;
    final collection = _messagesCollection(uid);
    if (collection == null) return;
    await collection.add({'sender': 'merchant', 'text': trimmed, 'sentAt': FieldValue.serverTimestamp()});
  }
}

final supportChatControllerProvider = Provider((ref) => SupportChatController(ref));

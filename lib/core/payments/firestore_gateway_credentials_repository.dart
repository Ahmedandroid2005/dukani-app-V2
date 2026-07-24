import 'package:cloud_firestore/cloud_firestore.dart';

import 'payment_gateway_credentials.dart';

/// The only file that imports `cloud_firestore` for gateway credentials —
/// everything else talks to [GatewayCredentialsRepository]. Same document
/// path the Cloud Function reads: stores/{ownerUid}/data/paymentGateway.
class FirestoreGatewayCredentialsRepository implements GatewayCredentialsRepository {
  FirestoreGatewayCredentialsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String ownerUid) =>
      _firestore.collection('stores').doc(ownerUid).collection('data').doc('paymentGateway');

  @override
  Future<ConnectedGateway?> fetch(String ownerUid) async {
    final snapshot = await _doc(ownerUid).get();
    if (!snapshot.exists) return null;
    return ConnectedGateway.fromJson(snapshot.data()!);
  }

  @override
  Future<void> save(String ownerUid, ConnectedGateway gateway) => _doc(ownerUid).set(gateway.toJson());

  @override
  Future<void> delete(String ownerUid) => _doc(ownerUid).delete();
}

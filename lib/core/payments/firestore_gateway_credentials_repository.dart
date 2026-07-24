import 'package:cloud_firestore/cloud_firestore.dart';

import 'payment_gateway_credentials.dart';

/// The only file that imports `cloud_firestore` for gateway credentials —
/// everything else talks to [GatewayCredentialsRepository]. Same document
/// path the Cloud Function reads: organizations/{orgId}/data/paymentGateway.
class FirestoreGatewayCredentialsRepository implements GatewayCredentialsRepository {
  FirestoreGatewayCredentialsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String orgId) =>
      _firestore.collection('organizations').doc(orgId).collection('data').doc('paymentGateway');

  @override
  Future<ConnectedGateway?> fetch(String orgId) async {
    final snapshot = await _doc(orgId).get();
    if (!snapshot.exists) return null;
    return ConnectedGateway.fromJson(snapshot.data()!);
  }

  @override
  Future<void> save(String orgId, ConnectedGateway gateway) => _doc(orgId).set(gateway.toJson());

  @override
  Future<void> delete(String orgId) => _doc(orgId).delete();
}

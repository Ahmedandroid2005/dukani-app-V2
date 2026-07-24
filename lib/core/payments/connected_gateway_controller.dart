import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase_providers.dart';
import '../offline/local_db.dart';
import '../organizations/org_controller.dart';
import 'firestore_gateway_credentials_repository.dart';
import 'payment_gateway_credentials.dart';

export 'payment_gateway_credentials.dart' show ConnectedGateway;

final gatewayCredentialsRepositoryProvider = Provider<GatewayCredentialsRepository>(
  (ref) => FirestoreGatewayCredentialsRepository(ref.watch(firestoreProvider)),
);

class ConnectedGatewayController extends StateNotifier<ConnectedGateway?> {
  ConnectedGatewayController(this._orgId, this._repository) : super(_read()) {
    // A device that's never connected a gateway locally (e.g. the merchant
    // just signed in on a new phone) still picks up whatever they connected
    // elsewhere, same pull-on-launch pattern as FirestoreSyncedListNotifier.
    if (_orgId != null && state == null) _pullFromCloud();
  }

  final String? _orgId;
  final GatewayCredentialsRepository _repository;

  static ConnectedGateway? _read() {
    final gatewayId = LocalDb.settings.get('connectedGatewayId') as String?;
    final apiKey = LocalDb.settings.get('connectedGatewayApiKey') as String?;
    final extra = LocalDb.settings.get('connectedGatewayExtra') as String?;
    if (gatewayId == null || apiKey == null || apiKey.isEmpty) return null;
    return ConnectedGateway(gatewayId: gatewayId, apiKey: apiKey, extra: extra);
  }

  Future<void> _pullFromCloud() async {
    try {
      final cloud = await _repository.fetch(_orgId!);
      if (cloud == null) return;
      await LocalDb.settings.put('connectedGatewayId', cloud.gatewayId);
      await LocalDb.settings.put('connectedGatewayApiKey', cloud.apiKey);
      if (cloud.extra != null) await LocalDb.settings.put('connectedGatewayExtra', cloud.extra);
      state = cloud;
    } catch (_) {
      // Offline, or Firestore not reachable yet — the local (empty) state
      // already loaded synchronously before this ran.
    }
  }

  Future<void> connect(String gatewayId, String apiKey, {String? extra}) async {
    await LocalDb.settings.put('connectedGatewayId', gatewayId);
    await LocalDb.settings.put('connectedGatewayApiKey', apiKey);
    if (extra != null) {
      await LocalDb.settings.put('connectedGatewayExtra', extra);
    } else {
      await LocalDb.settings.delete('connectedGatewayExtra');
    }
    final gateway = ConnectedGateway(gatewayId: gatewayId, apiKey: apiKey, extra: extra);
    state = gateway;
    if (_orgId != null) _repository.save(_orgId, gateway).catchError((_) {});
  }

  Future<void> disconnect() async {
    await LocalDb.settings.delete('connectedGatewayId');
    await LocalDb.settings.delete('connectedGatewayApiKey');
    await LocalDb.settings.delete('connectedGatewayExtra');
    state = null;
    if (_orgId != null) _repository.delete(_orgId).catchError((_) {});
  }
}

final connectedGatewayProvider = StateNotifierProvider<ConnectedGatewayController, ConnectedGateway?>(
  (ref) => ConnectedGatewayController(
    ref.watch(currentOrgIdProvider).valueOrNull,
    ref.watch(gatewayCredentialsRepositoryProvider),
  ),
);

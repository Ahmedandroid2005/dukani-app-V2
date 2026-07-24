import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True whenever the device has some network path (wifi/mobile/ethernet).
/// Every screen that needs to gate "sync now" vs "queue for later" reads
/// this instead of calling connectivity_plus directly.
final isOnlineProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged.map(_hasConnection).asBroadcastStream()
    ..listen((_) {}); // keep the underlying stream warm between rebuilds
});

bool _hasConnection(List<ConnectivityResult> results) {
  return results.any((r) => r != ConnectivityResult.none);
}

/// Convenience read for one-off checks (e.g. before attempting a "sync now").
Future<bool> checkIsOnline() async {
  final results = await Connectivity().checkConnectivity();
  return _hasConnection(results);
}

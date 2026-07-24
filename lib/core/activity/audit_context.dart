import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Best-effort "which device" label for an audit-log entry. A real device
/// name (model, hostname) needs a platform channel we don't have yet, so
/// this stays honest about what it actually knows.
String currentDeviceLabel() {
  if (kIsWeb) return 'متصفح ويب';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'جهاز Android';
    case TargetPlatform.iOS:
      return 'جهاز iPhone/iPad';
    default:
      return 'جهاز غير معروف';
  }
}

/// The IP address itself is only meaningful as seen by the server when the
/// event syncs — capturing it client-side would just be the local network
/// address, which isn't useful for an audit trail. This reports what we can
/// honestly know on-device: whether we're online at all, with a graceful
/// fallback when offline instead of silently omitting the field.
Future<String> currentIpStatus() async {
  final results = await Connectivity().checkConnectivity();
  final offline = results.every((r) => r == ConnectivityResult.none);
  return offline ? 'غير متصل بالإنترنت وقت العملية' : 'سيُسجَّل عنوان IP عند المزامنة';
}

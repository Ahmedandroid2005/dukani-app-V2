import 'package:cloud_firestore/cloud_firestore.dart';

/// A message the Super Admin sent to merchants (see the admin panel's
/// "إرسال إشعار" page) — separate from the purely-local operational alerts
/// (low stock, debts due...) generated on-device from the merchant's own
/// data. Read-only from the app's side: only an admin account can write to
/// this collection (see firestore.rules).
class BroadcastNotification {
  const BroadcastNotification({required this.title, required this.message, required this.target, required this.createdAt});

  final String title;
  final String message;

  /// `'all'`, `'plan:pro'`, or `'country:SA'` — matched client-side against
  /// the signed-in merchant's own plan/country so targeting works without
  /// needing a fan-out write per recipient.
  final String target;
  final DateTime? createdAt;

  factory BroadcastNotification.fromJson(Map<String, dynamic> json) => BroadcastNotification(
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        target: json['target'] as String? ?? 'all',
        createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      );

  bool matches({required String plan, required String countryCode}) {
    if (target == 'all') return true;
    if (target == 'plan:$plan') return true;
    if (target == 'country:$countryCode') return true;
    return false;
  }
}

/// Best-effort, one-shot fetch — called from the Notifications screen's
/// build, not kept in a background sync like the country/feature-flag
/// catalogs, since a merchant only needs this list when they actually open
/// the screen. Returns an empty list offline rather than throwing, so the
/// screen still renders the merchant's own local alerts either way.
Future<List<BroadcastNotification>> fetchBroadcastNotifications() async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('broadcasts').orderBy('createdAt', descending: true).limit(20).get();
    return snapshot.docs.map((d) => BroadcastNotification.fromJson(d.data())).toList();
  } catch (_) {
    return [];
  }
}

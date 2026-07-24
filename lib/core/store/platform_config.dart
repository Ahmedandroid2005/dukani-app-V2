import 'package:cloud_firestore/cloud_firestore.dart';

/// Support contact details set by Super Admin (see the admin panel's
/// Settings page, platform_config/general) — read here so "تواصل معنا"
/// actually reaches the real, currently-configured channel instead of a
/// hardcoded number baked into the app that goes stale.
class PlatformConfig {
  const PlatformConfig({required this.supportEmail, required this.supportWhatsapp});

  final String supportEmail;
  final String supportWhatsapp;

  factory PlatformConfig.fromJson(Map<String, dynamic> json) => PlatformConfig(
        supportEmail: json['supportEmail'] as String? ?? 'support@trydukani.com',
        supportWhatsapp: json['supportWhatsapp'] as String? ?? '',
      );

  static const fallback = PlatformConfig(supportEmail: 'support@trydukani.com', supportWhatsapp: '');
}

/// Best-effort, one-shot fetch — same seam as [fetchBroadcastNotifications].
/// Falls back to the known real support address offline rather than
/// showing nothing.
Future<PlatformConfig> fetchPlatformConfig() async {
  try {
    final snap = await FirebaseFirestore.instance.collection('platform_config').doc('general').get();
    final data = snap.data();
    if (data == null) return PlatformConfig.fallback;
    return PlatformConfig.fromJson(data);
  } catch (_) {
    return PlatformConfig.fallback;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/local_db.dart';

/// The activities Dukani tailors its screens for. Every merchant picks one
/// during setup, and the app — bottom nav, settings list, POS flow — reads
/// this to hide whatever doesn't apply instead of showing one generic menu
/// to everyone. Restaurant/cafe is deliberately out of scope for now — it's
/// a full system on its own (kitchen tickets, split bills, table service)
/// planned as a separate future product, not a business type here.
enum BusinessType { grocery, clothing, electronics, generalRetail }

/// Maps a business-type label chosen in the setup wizard to its gating
/// category — matches [_businessTypes] in the setup wizard one for one.
/// Anything unrecognized (currently just "أخرى" / other) falls back to
/// [BusinessType.generalRetail], the plain "sell anything off a shelf" set.
BusinessType businessTypeFromLabel(String label) => switch (label) {
      'بقالة / سوبر ماركت' => BusinessType.grocery,
      'ملابس' => BusinessType.clothing,
      'إلكترونيات' => BusinessType.electronics,
      _ => BusinessType.generalRetail,
    };

class BusinessTypeController extends StateNotifier<BusinessType> {
  BusinessTypeController() : super(_read());

  static BusinessType _read() {
    final stored = LocalDb.settings.get('businessType') as String?;
    if (stored == null) return BusinessType.generalRetail;
    return BusinessType.values.firstWhere((t) => t.name == stored, orElse: () => BusinessType.generalRetail);
  }

  Future<void> set(BusinessType type) async {
    await LocalDb.settings.put('businessType', type.name);
    state = type;
  }
}

final businessTypeProvider = StateNotifierProvider<BusinessTypeController, BusinessType>(
  (ref) => BusinessTypeController(),
);

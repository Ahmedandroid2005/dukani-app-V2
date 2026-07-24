import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_db.dart';

class AppSettings {
  const AppSettings({
    this.selfieCaptureEnabled = true,
    this.locationCaptureEnabled = true,
    this.darkMode = false,
    this.notifySales = true,
    this.notifyLowStock = true,
    this.notifyDebts = true,
    this.notifyShiftClose = false,
    this.allowNegativeStock = false,
  });

  final bool selfieCaptureEnabled;
  final bool locationCaptureEnabled;
  final bool darkMode;
  final bool notifySales;
  final bool notifyLowStock;
  final bool notifyDebts;
  final bool notifyShiftClose;

  /// Off by default — a cashier can never ring up more of a product than
  /// [MockProduct.stock] actually has. A merchant who explicitly wants to
  /// keep selling past zero (pre-orders, backorders) can turn this on.
  final bool allowNegativeStock;

  AppSettings copyWith({
    bool? selfieCaptureEnabled,
    bool? locationCaptureEnabled,
    bool? darkMode,
    bool? notifySales,
    bool? notifyLowStock,
    bool? notifyDebts,
    bool? notifyShiftClose,
    bool? allowNegativeStock,
  }) {
    return AppSettings(
      selfieCaptureEnabled: selfieCaptureEnabled ?? this.selfieCaptureEnabled,
      locationCaptureEnabled: locationCaptureEnabled ?? this.locationCaptureEnabled,
      darkMode: darkMode ?? this.darkMode,
      notifySales: notifySales ?? this.notifySales,
      notifyLowStock: notifyLowStock ?? this.notifyLowStock,
      notifyDebts: notifyDebts ?? this.notifyDebts,
      notifyShiftClose: notifyShiftClose ?? this.notifyShiftClose,
      allowNegativeStock: allowNegativeStock ?? this.allowNegativeStock,
    );
  }
}

/// Privacy & app preferences, persisted locally so they survive restarts —
/// and read locally-first like everything else, per the offline-first rule.
///
/// [selfieCaptureEnabled] / [locationCaptureEnabled] specifically exist
/// because capturing an employee's selfie or location on sensitive actions
/// (voiding an invoice, opening the cash drawer) can run into privacy law
/// or workplace-policy restrictions in some countries — so it must be an
/// explicit, store-owner-controlled choice, not baked in as always-on.
class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(_read());

  static AppSettings _read() {
    final box = LocalDb.settings;
    return AppSettings(
      selfieCaptureEnabled: box.get('selfieCaptureEnabled', defaultValue: true) as bool,
      locationCaptureEnabled: box.get('locationCaptureEnabled', defaultValue: true) as bool,
      darkMode: box.get('darkMode', defaultValue: false) as bool,
      notifySales: box.get('notifySales', defaultValue: true) as bool,
      notifyLowStock: box.get('notifyLowStock', defaultValue: true) as bool,
      notifyDebts: box.get('notifyDebts', defaultValue: true) as bool,
      notifyShiftClose: box.get('notifyShiftClose', defaultValue: false) as bool,
      allowNegativeStock: box.get('allowNegativeStock', defaultValue: false) as bool,
    );
  }

  Future<void> setSelfieCapture(bool value) async {
    await LocalDb.settings.put('selfieCaptureEnabled', value);
    state = state.copyWith(selfieCaptureEnabled: value);
  }

  Future<void> setLocationCapture(bool value) async {
    await LocalDb.settings.put('locationCaptureEnabled', value);
    state = state.copyWith(locationCaptureEnabled: value);
  }

  Future<void> setDarkMode(bool value) async {
    await LocalDb.settings.put('darkMode', value);
    state = state.copyWith(darkMode: value);
  }

  Future<void> setNotifySales(bool value) async {
    await LocalDb.settings.put('notifySales', value);
    state = state.copyWith(notifySales: value);
  }

  Future<void> setNotifyLowStock(bool value) async {
    await LocalDb.settings.put('notifyLowStock', value);
    state = state.copyWith(notifyLowStock: value);
  }

  Future<void> setNotifyDebts(bool value) async {
    await LocalDb.settings.put('notifyDebts', value);
    state = state.copyWith(notifyDebts: value);
  }

  Future<void> setNotifyShiftClose(bool value) async {
    await LocalDb.settings.put('notifyShiftClose', value);
    state = state.copyWith(notifyShiftClose: value);
  }

  Future<void> setAllowNegativeStock(bool value) async {
    await LocalDb.settings.put('allowNegativeStock', value);
    state = state.copyWith(allowNegativeStock: value);
  }
}

final settingsProvider = StateNotifierProvider<SettingsController, AppSettings>(
  (ref) => SettingsController(),
);

/// Reads [AppSettings.allowNegativeStock] straight from Hive — for call
/// sites (like [CartController]) that need the current value without
/// Riverpod/BuildContext, mirroring [currentCurrencySymbol]'s own pattern.
bool currentAllowNegativeStock() => LocalDb.settings.get('allowNegativeStock', defaultValue: false) as bool;

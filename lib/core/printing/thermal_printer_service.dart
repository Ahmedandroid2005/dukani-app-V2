import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../offline/local_db.dart';

/// A remembered Bluetooth thermal printer — same shape as
/// [BluetoothInfo] but decoupled from the plugin's type so the rest of the
/// app doesn't need to import it just to show a name on screen.
class SavedPrinter {
  const SavedPrinter({required this.name, required this.macAddress});
  final String name;
  final String macAddress;
}

/// Thin wrapper around the `print_bluetooth_thermal` plugin: lists paired
/// devices, connects, sends bytes, and remembers the merchant's chosen
/// printer across app restarts (in the same local settings box every other
/// setting persists through — see [LocalDb]).
class ThermalPrinterService {
  ThermalPrinterService._();
  static const _macKey = 'printer_mac';
  static const _nameKey = 'printer_name';

  static SavedPrinter? get savedPrinter {
    final mac = LocalDb.settings.get(_macKey) as String?;
    final name = LocalDb.settings.get(_nameKey) as String?;
    if (mac == null || name == null) return null;
    return SavedPrinter(name: name, macAddress: mac);
  }

  static Future<void> savePrinter(SavedPrinter printer) async {
    await LocalDb.settings.put(_macKey, printer.macAddress);
    await LocalDb.settings.put(_nameKey, printer.name);
  }

  static Future<void> clearSavedPrinter() async {
    await LocalDb.settings.delete(_macKey);
    await LocalDb.settings.delete(_nameKey);
  }

  static Future<bool> get bluetoothEnabled => PrintBluetoothThermal.bluetoothEnabled;

  /// Triggers Android's runtime Bluetooth-permission prompt on first use
  /// (Android 12+ requires BLUETOOTH_CONNECT/SCAN to be granted at runtime,
  /// not just declared in the manifest) — call before listing devices.
  static Future<bool> ensurePermission() => PrintBluetoothThermal.isPermissionBluetoothGranted;

  static Future<List<SavedPrinter>> pairedDevices() async {
    final devices = await PrintBluetoothThermal.pairedBluetooths;
    return devices.map((d) => SavedPrinter(name: d.name, macAddress: d.macAdress)).toList();
  }

  /// Connects to [printer], sends [bytes], then disconnects — a receipt
  /// print job is short-lived, so there's no reason to hold the Bluetooth
  /// connection open between sales.
  static Future<bool> printBytes(SavedPrinter printer, List<int> bytes) async {
    final connected = await PrintBluetoothThermal.connect(macPrinterAddress: printer.macAddress);
    if (!connected) return false;
    try {
      return await PrintBluetoothThermal.writeBytes(bytes);
    } finally {
      await PrintBluetoothThermal.disconnect;
    }
  }
}

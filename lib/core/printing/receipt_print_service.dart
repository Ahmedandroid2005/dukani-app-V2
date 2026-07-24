import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:printing/printing.dart';

import '../offline/local_db.dart';
import 'receipt_data.dart';
import 'receipt_escpos_builder.dart';
import 'receipt_pdf_builder.dart';
import 'thermal_printer_service.dart';

enum PrinterMode { bluetooth, systemOrPdf }

/// What actually happens when a receipt needs to go out — reads the
/// merchant's printer settings (persisted in [LocalDb.settings], edited
/// from [PrinterSettingsScreen]) and picks the right path:
///  - a paired Bluetooth thermal printer gets raw ESC/POS bytes directly
///  - otherwise the OS print dialog opens, which reaches any Wi-Fi/USB
///    printer Android already knows a driver for, and doubles as the
///    "export/share as PDF" path with zero extra code.
class ReceiptPrintService {
  ReceiptPrintService._();

  static const _modeKey = 'printer_mode';
  static const _paperKey = 'printer_paper_size';
  static const _autoprintKey = 'printer_autoprint';

  static PrinterMode get mode {
    final raw = LocalDb.settings.get(_modeKey) as String?;
    return raw == 'bluetooth' ? PrinterMode.bluetooth : PrinterMode.systemOrPdf;
  }

  static Future<void> setMode(PrinterMode mode) => LocalDb.settings.put(_modeKey, mode == PrinterMode.bluetooth ? 'bluetooth' : 'system');

  static PaperSize get paperSize => (LocalDb.settings.get(_paperKey) as String?) == '58' ? PaperSize.mm58 : PaperSize.mm80;

  static Future<void> setPaperSize(PaperSize size) => LocalDb.settings.put(_paperKey, size == PaperSize.mm58 ? '58' : '80');

  static bool get autoprint => (LocalDb.settings.get(_autoprintKey) as bool?) ?? true;

  static Future<void> setAutoprint(bool value) => LocalDb.settings.put(_autoprintKey, value);

  /// Result of a print attempt — a plain outcome + human-readable Arabic
  /// message, so the calling screen just shows it in a SnackBar without
  /// needing to know why something failed.
  static Future<PrintOutcome> print(ReceiptData receipt) async {
    final printer = ThermalPrinterService.savedPrinter;
    if (mode == PrinterMode.bluetooth && printer != null) {
      try {
        final bytes = await ReceiptEscPosBuilder.build(receipt, paperSize: paperSize);
        final ok = await ThermalPrinterService.printBytes(printer, bytes);
        return ok
            ? const PrintOutcome(true, 'تم إرسال الفاتورة للطابعة')
            : const PrintOutcome(false, 'تعذّر الاتصال بالطابعة — تأكد إنها شغالة وقريبة');
      } catch (_) {
        return const PrintOutcome(false, 'تعذّر إرسال الفاتورة للطابعة');
      }
    }
    return openSystemPrintDialog(receipt);
  }

  /// Opens Android's native print dialog — works with any printer already
  /// set up on the device, and lets the merchant save as PDF from the same
  /// dialog if they don't pick a printer.
  static Future<PrintOutcome> openSystemPrintDialog(ReceiptData receipt) async {
    try {
      final doc = await ReceiptPdfBuilder.build(receipt);
      await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'فاتورة ${receipt.invoiceId}');
      return const PrintOutcome(true, null);
    } catch (_) {
      return const PrintOutcome(false, 'تعذّر فتح شاشة الطباعة');
    }
  }

  static Future<PrintOutcome> share(ReceiptData receipt) async {
    try {
      final doc = await ReceiptPdfBuilder.build(receipt);
      final bytes = await doc.save();
      await Printing.sharePdf(bytes: bytes, filename: '${receipt.invoiceId}.pdf');
      return const PrintOutcome(true, null);
    } catch (_) {
      return const PrintOutcome(false, 'تعذّر مشاركة الفاتورة');
    }
  }

  static Future<PrintOutcome> testPrint() async {
    final now = DateTime.now();
    final sample = ReceiptData(
      invoiceId: 'تجريبي',
      createdAt: now,
      storeName: 'صفحة اختبار',
      lines: const [ReceiptLine(name: 'صنف تجريبي', qtyLabel: '×1', unitPrice: 10, lineTotal: 10)],
      subtotal: 10,
      discountPercent: 0,
      discountAmount: 0,
      taxRate: 0,
      taxAmount: 0,
      total: 10,
      methodLabel: 'اختبار',
      currencySymbol: '',
    );
    return print(sample);
  }
}

class PrintOutcome {
  const PrintOutcome(this.success, this.message);
  final bool success;
  final String? message;
}

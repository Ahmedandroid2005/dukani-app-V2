import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'receipt_data.dart';
import 'receipt_pdf_builder.dart';

/// Turns a [ReceiptData] into raw ESC/POS bytes a Bluetooth thermal printer
/// can print directly.
///
/// Most cheap thermal printers only understand Latin/Cyrillic ESC/POS code
/// pages — sending them the Arabic text directly prints garbled characters
/// or nothing at all. The reliable, printer-agnostic fix used industry-wide
/// for non-Latin receipts is to render the ticket as a bitmap and print
/// *that* — so this reuses the same PDF built for the system print dialog,
/// rasterizes it, and sends it as an ESC/POS raster image instead of text.
class ReceiptEscPosBuilder {
  static Future<List<int>> build(ReceiptData receipt, {PaperSize paperSize = PaperSize.mm80}) async {
    final pw.Document doc = await ReceiptPdfBuilder.build(receipt);
    final Uint8List pdfBytes = await doc.save();

    final targetWidthPx = paperSize == PaperSize.mm58 ? 384 : 576;

    img.Image? raster;
    await for (final page in Printing.raster(pdfBytes, dpi: 203)) {
      final rgba = await page.toPng();
      raster = img.decodePng(rgba);
      break; // one-page receipt
    }
    if (raster == null) {
      throw StateError('تعذّر تجهيز الفاتورة للطباعة');
    }
    if (raster.width != targetWidthPx) {
      raster = img.copyResize(raster, width: targetWidthPx);
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    var bytes = <int>[];
    bytes += generator.reset();
    bytes += generator.imageRaster(raster, align: PosAlign.center);
    bytes += generator.feed(2);
    bytes += generator.cut();
    return bytes;
  }
}

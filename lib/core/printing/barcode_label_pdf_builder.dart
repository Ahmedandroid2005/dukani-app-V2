import 'package:barcode/barcode.dart' as bc;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// One product's worth of labels to print — [copies] sheet slots, not one
/// combined label, since a merchant restocking ten units of the same item
/// wants ten identical stickers, not one label that says "×10".
class LabelRequest {
  const LabelRequest({required this.name, required this.barcode, required this.price, required this.currencySymbol, this.copies = 1});
  final String name;
  final String barcode;
  final double price;
  final String currencySymbol;
  final int copies;
}

/// Lays out a sheet of Code128 barcode stickers — 3 columns of small labels
/// on A4, which is what a merchant printing on plain paper or a standard
/// label-sheet at home/in-store actually has, rather than assuming a
/// dedicated label printer nobody but a large electronics chain would own.
class BarcodeLabelPdfBuilder {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _ensureFonts() async {
    _regular ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    _bold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
  }

  static Future<pw.Document> build(List<LabelRequest> requests) async {
    await _ensureFonts();
    final doc = pw.Document();
    final theme = pw.ThemeData.withFont(base: _regular!, bold: _bold!);

    final labels = <LabelRequest>[for (final r in requests) for (var i = 0; i < r.copies; i++) r];

    const perRow = 3;
    const perPage = perRow * 8;

    for (var start = 0; start < labels.length; start += perPage) {
      final page = labels.skip(start).take(perPage).toList();
      doc.addPage(
        pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a4.copyWith(marginLeft: 16, marginRight: 16, marginTop: 16, marginBottom: 16),
          build: (context) {
            return pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final label in page)
                  pw.Container(
                    width: (PdfPageFormat.a4.width - 32 - (perRow - 1) * 8) / perRow,
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5)),
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          label.name,
                          maxLines: 1,
                          overflow: pw.TextOverflow.clip,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(font: _bold, fontSize: 8),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${label.price.toStringAsFixed(2)} ${label.currencySymbol}',
                          style: pw.TextStyle(font: _bold, fontSize: 9),
                          textDirection: pw.TextDirection.rtl,
                        ),
                        pw.SizedBox(height: 3),
                        pw.BarcodeWidget(
                          data: label.barcode,
                          barcode: bc.Barcode.code128(),
                          drawText: true,
                          textStyle: const pw.TextStyle(fontSize: 7),
                          height: 34,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }

    return doc;
  }

  /// A short, locally-unique Code128-safe number for products that have no
  /// manufacturer barcode — timestamp-based so two labels printed a second
  /// apart never collide, no server round-trip required (this is exactly
  /// the situation printing works offline for in the first place).
  static String generateInternalCode() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return '2${now.toString().substring(now.toString().length - 11)}';
  }
}

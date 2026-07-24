import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'receipt_data.dart';

/// Renders a [ReceiptData] as a narrow receipt-roll PDF page. Loads the
/// app's own bundled Cairo font rather than a default Latin-only PDF font —
/// otherwise every Arabic character on the receipt (store name, item names,
/// "الإجمالي"...) would render as blank boxes.
class ReceiptPdfBuilder {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _ensureFonts() async {
    _regular ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    _bold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
  }

  static Future<pw.Document> build(ReceiptData receipt) async {
    await _ensureFonts();
    final doc = pw.Document();

    final theme = pw.ThemeData.withFont(base: _regular!, bold: _bold!);
    final money = (double v) => '${v.toStringAsFixed(2)} ${receipt.currencySymbol}';

    doc.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.roll80.copyWith(marginLeft: 12, marginRight: 12, marginTop: 12, marginBottom: 12),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(child: pw.Text(receipt.storeName, style: pw.TextStyle(font: _bold, fontSize: 16))),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    '${receipt.invoiceId} — ${_formatDate(receipt.createdAt)}',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                ),
                if (receipt.cashierName != null && receipt.cashierName!.trim().isNotEmpty)
                  pw.Center(child: pw.Text('الكاشير: ${receipt.cashierName}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700))),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 0.7),
                for (final line in receipt.lines) ...[
                  pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(line.name, style: const pw.TextStyle(fontSize: 10))),
                      pw.Expanded(flex: 1, child: pw.Text(line.qtyLabel, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 2, child: pw.Text(money(line.lineTotal), style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.left)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                ],
                pw.Divider(thickness: 0.7),
                _totalsRow('المجموع الفرعي', money(receipt.subtotal)),
                if (receipt.discountPercent > 0) _totalsRow('الخصم (${receipt.discountPercent.toStringAsFixed(0)}٪)', '-${money(receipt.discountAmount)}'),
                if (receipt.taxAmount > 0) _totalsRow('الضريبة (${receipt.taxRate.toStringAsFixed(0)}٪)', money(receipt.taxAmount)),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.7),
                _totalsRow('الإجمالي', money(receipt.total), bold: true),
                pw.SizedBox(height: 8),
                _totalsRow('طريقة الدفع', receipt.methodLabel),
                if (receipt.tendered != null) _totalsRow('المبلغ المستلم', money(receipt.tendered!)),
                if (receipt.change != null && receipt.change! > 0) _totalsRow('المتبقي للعميل', money(receipt.change!)),
                pw.SizedBox(height: 14),
                pw.Center(child: pw.Text('شكرًا لتعاملكم معنا', style: pw.TextStyle(font: _bold, fontSize: 11))),
              ],
            ),
          );
        },
      ),
    );

    return doc;
  }

  static pw.Widget _totalsRow(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(fontSize: bold ? 12 : 10, font: bold ? _bold : _regular);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label, style: style), pw.Text(value, style: style)],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}

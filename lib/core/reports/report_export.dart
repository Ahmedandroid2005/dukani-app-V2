import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/mock/mock_reports.dart';

/// Turns one or more [ReportDefinition]s (the same KPIs + rows every report
/// screen already renders on-screen) into a real file the merchant can
/// save, share, or print — the export sheet used to just close itself with
/// no file produced at all.
class ReportExport {
  ReportExport._();

  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<void> _ensureFonts() async {
    _regular ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Regular.ttf'));
    _bold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Cairo-Bold.ttf'));
  }

  /// KPI rows first, then the report's own row list, per report — the same
  /// two sections every [ReportDefinition] shows on screen.
  static List<List<String>> _rowsFor(List<ReportDefinition> reports) => [
        for (final report in reports) ...[
          [report.title],
          ['المؤشر', 'القيمة'],
          for (final kpi in report.kpis) [kpi.label, kpi.value],
          [],
          [report.rowsTitle, '', ''],
          for (final row in report.rows) [row.title, row.subtitle, row.trailing],
          [],
        ],
      ];

  static Future<pw.Document> _buildPdf(List<ReportDefinition> reports) async {
    await _ensureFonts();
    final doc = pw.Document();
    final theme = pw.ThemeData.withFont(base: _regular!, bold: _bold!);

    for (final report in reports) {
      doc.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Text(report.title, style: pw.TextStyle(font: _bold, fontSize: 18)),
                  pw.SizedBox(height: 12),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    children: [
                      for (final kpi in report.kpis)
                        pw.TableRow(children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(kpi.label, style: const pw.TextStyle(fontSize: 11))),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(kpi.value, style: pw.TextStyle(font: _bold, fontSize: 11), textAlign: pw.TextAlign.left),
                          ),
                        ]),
                    ],
                  ),
                  pw.SizedBox(height: 16),
                  pw.Text(report.rowsTitle, style: pw.TextStyle(font: _bold, fontSize: 14)),
                  pw.SizedBox(height: 6),
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(3), 2: pw.FlexColumnWidth(2)},
                    children: [
                      for (final row in report.rows)
                        pw.TableRow(children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(row.title, style: const pw.TextStyle(fontSize: 10))),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(row.subtitle, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(row.trailing, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.left),
                          ),
                        ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return doc;
  }

  static Future<void> exportPdf(ReportDefinition report) => exportAllPdf([report], fileName: report.title);

  static Future<void> print(ReportDefinition report) => printAll([report], name: report.title);

  /// "Excel" export is the same underlying file as CSV — every spreadsheet
  /// app (Excel included) opens a .csv natively, and it avoids pulling in a
  /// second binary-format package just to produce a file most merchants
  /// will drop straight into Excel anyway.
  static Future<void> exportCsv(ReportDefinition report) => exportAllCsv([report], fileName: report.title);

  static Future<void> exportAllPdf(List<ReportDefinition> reports, {String fileName = 'تقارير دُكاني'}) async {
    final doc = await _buildPdf(reports);
    final bytes = await doc.save();
    await Printing.sharePdf(bytes: bytes, filename: '$fileName.pdf');
  }

  static Future<void> printAll(List<ReportDefinition> reports, {String name = 'تقارير دُكاني'}) async {
    final doc = await _buildPdf(reports);
    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: name);
  }

  static Future<void> exportAllCsv(List<ReportDefinition> reports, {String fileName = 'تقارير دُكاني'}) async {
    final csvText = const ListToCsvConverter().convert(_rowsFor(reports));
    final bytes = Uint8List.fromList(utf8.encode('﻿$csvText'));
    await FilePicker.platform.saveFile(
      fileName: '$fileName.csv',
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
  }
}

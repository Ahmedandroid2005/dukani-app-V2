import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/customers/customers_controller.dart';
import '../../core/expenses/expenses_controller.dart';
import '../../core/inventory/stocktake_controller.dart';
import '../../core/pos/sales_log_controller.dart';
import '../../core/products/products_controller.dart';
import '../../core/purchases/purchases_controller.dart';
import '../../core/reports/live_report_builder.dart';
import '../../core/reports/report_export.dart';
import '../../core/returns/returns_controller.dart';
import '../../core/suppliers/suppliers_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_reports.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum _PeriodKind { day, month, last3Months, custom }

class ReportDetailScreen extends ConsumerStatefulWidget {
  const ReportDetailScreen({super.key, required this.reportId});
  final String reportId;

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  _PeriodKind _periodKind = _PeriodKind.month;
  DateTimeRange? _customRange;

  String get _period => switch (_periodKind) {
        _PeriodKind.day => 'اليوم',
        _PeriodKind.month => 'هذا الشهر',
        _PeriodKind.last3Months => 'آخر 3 شهور',
        _PeriodKind.custom => _customRange == null ? 'فترة محددة' : '${_fmt(_customRange!.start)} — ${_fmt(_customRange!.end)}',
      };

  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365 * 2)),
      lastDate: now,
      initialDateRange: _customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _periodKind = _PeriodKind.custom;
      });
    }
  }

  Future<void> _runExport(Future<void> Function() action) async {
    Navigator.pop(context);
    try {
      await action();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذّر تصدير التقرير، حاول تاني')));
    }
  }

  void _export(ReportDefinition report) {
    showDukaniSheet(
      context,
      title: 'تصدير التقرير',
      child: Column(
        children: [
          DukaniSheetAction(icon: LucideIcons.fileText, label: 'تصدير PDF', color: DukaniColors.danger, onTap: () => _runExport(() => ReportExport.exportPdf(report))),
          DukaniSheetAction(icon: LucideIcons.grid, label: 'تصدير Excel (CSV)', color: DukaniColors.success, onTap: () => _runExport(() => ReportExport.exportCsv(report))),
          DukaniSheetAction(icon: LucideIcons.fileText, label: 'تصدير CSV', onTap: () => _runExport(() => ReportExport.exportCsv(report))),
          DukaniSheetAction(icon: LucideIcons.printer, label: 'طباعة', onTap: () => _runExport(() => ReportExport.print(report))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staticReport = findReport(widget.reportId);

    if (staticReport == null) {
      return const Scaffold(
        appBar: DukaniAppBar(title: 'التقرير'),
        body: DukaniEmptyState(title: 'التقرير غير موجود', icon: LucideIcons.searchX),
      );
    }

    final report = buildLiveReport(
      widget.reportId,
      fallback: staticReport,
      sales: ref.watch(salesLogProvider),
      products: ref.watch(productsProvider),
      customers: ref.watch(customersProvider),
      suppliers: ref.watch(suppliersProvider),
      expenses: ref.watch(expensesProvider),
      activityLog: ref.watch(activityLogProvider),
      purchaseOrders: ref.watch(purchaseOrdersProvider),
      returns: ref.watch(returnsProvider),
      stocktakes: ref.watch(stocktakeProvider),
    );

    return Scaffold(
      appBar: DukaniAppBar(
        title: report.title,
        actions: [DukaniIconAction(icon: LucideIcons.share2, onTap: () => _export(report))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                DukaniChoiceChip(label: 'يوم', selected: _periodKind == _PeriodKind.day, onTap: () => setState(() => _periodKind = _PeriodKind.day)),
                const SizedBox(width: 8),
                DukaniChoiceChip(label: 'هذا الشهر', selected: _periodKind == _PeriodKind.month, onTap: () => setState(() => _periodKind = _PeriodKind.month)),
                const SizedBox(width: 8),
                DukaniChoiceChip(label: 'آخر 3 شهور', selected: _periodKind == _PeriodKind.last3Months, onTap: () => setState(() => _periodKind = _PeriodKind.last3Months)),
                const SizedBox(width: 8),
                DukaniChoiceChip(icon: LucideIcons.calendarDays, label: 'تحديد فترة', selected: _periodKind == _PeriodKind.custom, onTap: _pickCustomRange),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.sm),
          Text(_period, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: DukaniColors.ink500)),
          const SizedBox(height: DukaniSpacing.lg),
          GridView.count(
            crossAxisCount: report.kpis.length >= 3 ? 3 : report.kpis.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: DukaniSpacing.md,
            crossAxisSpacing: DukaniSpacing.md,
            childAspectRatio: 1.05,
            children: [
              for (final kpi in report.kpis)
                DukaniCard(
                  padding: const EdgeInsets.all(DukaniSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DukaniAmountText(kpi.value, style: DukaniTypography.statFigure(Theme.of(context).colorScheme.onSurface, size: 17)),
                      const SizedBox(height: 4),
                      Text(kpi.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500), maxLines: 2),
                      if (kpi.trend != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              kpi.trendUp == false ? LucideIcons.arrowDown : LucideIcons.arrowUp,
                              size: 11,
                              color: kpi.trendUp == false ? DukaniColors.danger : DukaniColors.success,
                            ),
                            DukaniAmountText(
                              kpi.trend!,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: kpi.trendUp == false ? DukaniColors.danger : DukaniColors.success),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
          if (report.chartType != ReportChartType.none) ...[
            const SizedBox(height: DukaniSpacing.xl),
            DukaniCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('الاتجاه خلال ${_period.toLowerCase()}', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: DukaniSpacing.md),
                  if (report.chartType == ReportChartType.line)
                    DukaniLineChart(values: report.chartValues, labels: report.chartLabels)
                  else if (report.chartType == ReportChartType.bar)
                    DukaniBarChart(values: report.chartValues, labels: report.chartLabels)
                  else
                    Center(
                      child: DukaniPieChart(
                        slices: [
                          for (int i = 0; i < report.rows.length && i < DukaniColors.chartSeries.length; i++)
                            DukaniPieSlice(label: report.rows[i].title, value: double.tryParse(report.rows[i].trailing.replaceAll(RegExp('[^0-9.]'), '')) ?? 1, color: DukaniColors.chartSeries[i]),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: DukaniSpacing.xl),
          DukaniCard(
            padding: const EdgeInsets.all(DukaniSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(report.rowsTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: DukaniSpacing.md),
                for (final row in report.rows) ...[
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: row.danger ? DukaniColors.dangerBg : DukaniColors.forest50,
                          borderRadius: BorderRadius.circular(DukaniRadii.sm),
                        ),
                        child: Icon(row.icon ?? LucideIcons.circle, size: 16, color: row.danger ? DukaniColors.danger : DukaniColors.forest600),
                      ),
                      const SizedBox(width: DukaniSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.title, style: Theme.of(context).textTheme.titleSmall),
                            Text(row.subtitle, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                          ],
                        ),
                      ),
                      DukaniAmountText(
                        row.trailing,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: row.danger ? DukaniColors.danger : DukaniColors.forest700),
                      ),
                    ],
                  ),
                  if (row != report.rows.last) const Divider(height: DukaniSpacing.xl),
                ],
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(label: 'تصدير التقرير', icon: LucideIcons.share2, onPressed: () => _export(report)),
        ],
      ),
    );
  }
}

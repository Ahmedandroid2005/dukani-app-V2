import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/mock/mock_models.dart';
import '../../data/mock/mock_reports.dart';
import '../business/currency.dart';
import '../inventory/stocktake_controller.dart';
import '../pos/sales_log_controller.dart';
import '../purchases/purchases_controller.dart';
import '../returns/returns_controller.dart';
import 'live_reports.dart';

String _money(double v) => '${v.toStringAsFixed(2)} ${currentCurrencySymbol()}';

/// Recomputes every field of a report from real store data — replaces the
/// fixed demo numbers in mock_reports.dart for every report id this store
/// actually has data for. Falls back to [fallback]'s icon/title/category
/// (display metadata only, never numbers) for anything not handled below.
ReportDefinition buildLiveReport(
  String id, {
  required ReportDefinition fallback,
  required List<SaleRecord> sales,
  required List<MockProduct> products,
  required List<MockCustomer> customers,
  required List<MockSupplier> suppliers,
  required List<MockExpense> expenses,
  required List<MockActivityEntry> activityLog,
  required List<MockPurchaseOrder> purchaseOrders,
  required List<MockReturn> returns,
  required List<StocktakeRecord> stocktakes,
}) {
  ReportDefinition base({
    required List<ReportKpi> kpis,
    ReportChartType chartType = ReportChartType.none,
    List<double> chartValues = const [],
    List<String> chartLabels = const [],
    required String rowsTitle,
    required List<ReportRow> rows,
  }) =>
      ReportDefinition(
        id: fallback.id,
        title: fallback.title,
        icon: fallback.icon,
        category: fallback.category,
        kpis: kpis,
        chartType: chartType,
        chartValues: chartValues,
        chartLabels: chartLabels,
        rowsTitle: rowsTitle,
        rows: rows,
      );

  switch (id) {
    case 'sales':
      final today = salesToday(sales);
      final revenue = LiveSalesFigures.from(sales);
      final series = weeklyRevenueSeries(sales);
      return base(
        kpis: [
          ReportKpi(label: 'إجمالي المبيعات', value: _money(revenue.totalRevenue)),
          ReportKpi(label: 'عدد الفواتير', value: '${revenue.invoiceCount}'),
          ReportKpi(label: 'متوسط الفاتورة', value: _money(revenue.avgInvoice)),
        ],
        chartType: ReportChartType.line,
        chartValues: series.values,
        chartLabels: series.labels,
        rowsTitle: 'أحدث الفواتير',
        rows: [
          for (final s in sales.take(10))
            ReportRow(title: s.id, subtitle: '${s.customerName ?? 'عميل نقدي'} — ${s.methodLabel}', trailing: _money(s.total), icon: LucideIcons.receipt),
        ],
      );

    case 'profits':
      final figures = LiveProfitFigures.from(sales);
      final series = weeklyProfitSeries(sales);
      final byCategory = <String, double>{};
      for (final s in sales) {
        for (final l in s.lines) {
          final product = products.where((p) => p.id == l.productId).toList();
          final category = product.isEmpty ? 'أخرى' : product.first.category;
          byCategory[category] = (byCategory[category] ?? 0) + l.profit;
        }
      }
      final sortedCategories = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return base(
        kpis: [
          ReportKpi(label: 'صافي الربح', value: _money(figures.netProfit)),
          ReportKpi(label: 'هامش الربح', value: '${figures.marginPercent.toStringAsFixed(1)}%'),
          ReportKpi(label: 'تكلفة البضاعة', value: _money(figures.cogs)),
        ],
        chartType: ReportChartType.line,
        chartValues: series.values,
        chartLabels: series.labels,
        rowsTitle: 'أكثر الأقسام ربحًا',
        rows: [
          for (final e in sortedCategories.take(8)) ReportRow(title: e.key, subtitle: '', trailing: _money(e.value), icon: LucideIcons.tags),
        ],
      );

    case 'expenses':
      final total = expenses.fold(0.0, (s, e) => s + e.amount);
      final byCategory = <String, double>{};
      for (final e in expenses) {
        byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
      }
      final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return base(
        kpis: [
          ReportKpi(label: 'إجمالي المصروفات', value: _money(total)),
          ReportKpi(label: 'أكبر تصنيف', value: sorted.isEmpty ? '—' : sorted.first.key),
        ],
        chartType: sorted.isEmpty ? ReportChartType.none : ReportChartType.pie,
        rowsTitle: 'المصروفات حسب التصنيف',
        rows: [for (final e in sorted) ReportRow(title: e.key, subtitle: '', trailing: _money(e.value), icon: LucideIcons.receipt)],
      );

    case 'debts':
      final debtors = customers.where((c) => c.debt > 0).toList()..sort((a, b) => b.debt.compareTo(a.debt));
      final total = debtors.fold(0.0, (s, c) => s + c.debt);
      return base(
        kpis: [
          ReportKpi(label: 'إجمالي الديون', value: _money(total)),
          ReportKpi(label: 'عملاء مدينون', value: '${debtors.length}'),
        ],
        rowsTitle: 'العملاء المدينون',
        rows: [
          for (final c in debtors) ReportRow(title: c.name, subtitle: c.phone, trailing: _money(c.debt), icon: LucideIcons.user, danger: c.debt > 200),
        ],
      );

    case 'payments':
      final byMethod = <String, double>{};
      for (final s in sales) {
        byMethod[s.methodLabel] = (byMethod[s.methodLabel] ?? 0) + s.total;
      }
      final sorted = byMethod.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final total = sales.fold(0.0, (s, r) => s + r.total);
      return base(
        kpis: [for (final e in sorted) ReportKpi(label: e.key, value: _money(e.value))],
        chartType: sorted.isEmpty ? ReportChartType.none : ReportChartType.pie,
        rowsTitle: 'طرق الدفع',
        rows: [
          for (final e in sorted)
            ReportRow(
              title: e.key,
              subtitle: total == 0 ? '' : '${(e.value / total * 100).toStringAsFixed(0)}% من المبيعات',
              trailing: _money(e.value),
              icon: LucideIcons.creditCard,
            ),
        ],
      );

    case 'taxes':
      final totalTax = sales.fold(0.0, (s, r) => s + r.taxAmount);
      final series = <ReportRow>[];
      final byWeek = <String, double>{};
      for (final s in sales.where((s) => s.taxAmount > 0)) {
        final key = '${s.createdAt.year}-${s.createdAt.month.toString().padLeft(2, '0')}';
        byWeek[key] = (byWeek[key] ?? 0) + s.taxAmount;
      }
      final sortedMonths = byWeek.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
      for (final e in sortedMonths.take(6)) {
        series.add(ReportRow(title: e.key, subtitle: '', trailing: _money(e.value), icon: LucideIcons.calendarRange));
      }
      return base(
        kpis: [
          ReportKpi(label: 'إجمالي الضريبة المحصّلة', value: _money(totalTax)),
        ],
        rowsTitle: 'الضريبة حسب الشهر',
        rows: series,
      );

    case 'inventory':
      final value = products.fold(0.0, (s, p) => s + p.price * p.stock);
      final lowStock = products.where((p) => !p.isOutOfStock && p.isLowStock).length;
      return base(
        kpis: [
          ReportKpi(label: 'إجمالي المنتجات', value: '${products.length}'),
          ReportKpi(label: 'قيمة المخزون', value: _money(value)),
          ReportKpi(label: 'قاربت على النفاد', value: '$lowStock'),
        ],
        rowsTitle: 'المنتجات',
        rows: [
          for (final p in products.take(20)) ReportRow(title: p.name, subtitle: 'المخزون: ${p.stock} وحدة', trailing: _money(p.price * p.stock), icon: LucideIcons.package),
        ],
      );

    case 'stock_movement':
      final sold = sales.fold(0, (s, r) => s + r.itemCount);
      final received = purchaseOrders.where((o) => o.received).fold(0, (s, o) => s + o.items.fold(0, (s2, i) => s2 + i.qty));
      final returnedQty = returns.fold(0, (s, r) => s + r.items.fold(0, (s2, i) => s2 + i.qty));
      final rows = <ReportRow>[
        for (final s in sales.take(5))
          for (final l in s.lines.take(2)) ReportRow(title: l.productName, subtitle: 'صادر — عملية بيع ${s.id}', trailing: '-${l.qty}', icon: LucideIcons.arrowUp),
        for (final o in purchaseOrders.where((o) => o.received).take(5))
          for (final i in o.items.take(2)) ReportRow(title: i.productName, subtitle: 'وارد — فاتورة شراء ${o.id}', trailing: '+${i.qty}', icon: LucideIcons.arrowDown),
        for (final r in returns.take(5))
          for (final i in r.items.take(2)) ReportRow(title: i.name, subtitle: 'مرتجع — ${r.reason}', trailing: '-${i.qty}', icon: LucideIcons.alertTriangle, danger: true),
      ];
      return base(
        kpis: [
          ReportKpi(label: 'وارد (طلبات شراء مستلمة)', value: '$received وحدة'),
          ReportKpi(label: 'صادر (مبيعات)', value: '$sold وحدة'),
          ReportKpi(label: 'مرتجع', value: '$returnedQty وحدة'),
        ],
        rowsTitle: 'آخر الحركات',
        rows: rows.take(10).toList(),
      );

    case 'items':
      final categories = products.map((p) => p.category).toSet();
      final aggregates = productSalesAggregates(sales);
      final ranked = products.where((p) => aggregates.containsKey(p.id)).toList()..sort((a, b) => aggregates[b.id]!.revenue.compareTo(aggregates[a.id]!.revenue));
      return base(
        kpis: [
          ReportKpi(label: 'عدد الأصناف', value: '${products.length}'),
          ReportKpi(label: 'عدد التصنيفات', value: '${categories.length}'),
        ],
        rowsTitle: 'أفضل الأصناف مبيعًا',
        rows: [
          for (final p in ranked.take(10))
            ReportRow(title: p.name, subtitle: '${p.category} — ${aggregates[p.id]!.qtySold} عملية بيع', trailing: _money(aggregates[p.id]!.revenue), icon: LucideIcons.tags),
        ],
      );

    case 'expiring':
      final now = DateTime.now();
      final expiring = products.where((p) => p.expiryDate != null && p.expiryDate!.difference(now).inDays <= 30).toList()
        ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));
      final lossValue = expiring.fold(0.0, (s, p) => s + p.price * p.stock);
      return base(
        kpis: [
          ReportKpi(label: 'أصناف قاربت على الانتهاء', value: '${expiring.length}'),
          ReportKpi(label: 'قيمة الخسارة المحتملة', value: _money(lossValue)),
        ],
        rowsTitle: 'الأصناف حسب تاريخ الانتهاء',
        rows: [
          for (final p in expiring)
            ReportRow(
              title: p.name,
              subtitle: p.expiryDate!.isBefore(now) ? 'منتهي الصلاحية' : 'ينتهي بعد ${p.expiryDate!.difference(now).inDays} يوم',
              trailing: '${p.stock} وحدة',
              icon: LucideIcons.calendarX,
              danger: p.expiryDate!.difference(now).inDays <= 7,
            ),
        ],
      );

    case 'stocktake':
      final last = stocktakes.isEmpty ? null : stocktakes.first;
      final daysAgo = last == null ? null : DateTime.now().difference(last.completedAt).inDays;
      return base(
        kpis: [
          ReportKpi(label: 'آخر جرد', value: last == null ? 'لم يتم جرد بعد' : (daysAgo == 0 ? 'اليوم' : 'منذ $daysAgo يوم')),
          ReportKpi(label: 'فروقات مكتشفة', value: last == null ? '—' : '${last.variances.length} صنف'),
        ],
        rowsTitle: 'فروقات آخر جرد',
        rows: last == null
            ? []
            : [
                for (final v in last.variances)
                  ReportRow(title: v.productName, subtitle: 'متوقع ${v.systemStock} — فعلي ${v.countedStock}', trailing: '${v.diff > 0 ? '+' : ''}${v.diff}', icon: LucideIcons.equal, danger: true),
              ],
      );

    case 'slow_moving':
      final aggregates = productSalesAggregates(sales);
      final now = DateTime.now();
      final slow = products.where((p) {
        final agg = aggregates[p.id];
        final daysSince = agg == null ? null : now.difference(agg.lastSoldAt).inDays;
        return p.stock > 0 && daysSince != null && daysSince >= 21;
      }).toList()
        ..sort((a, b) => now.difference(aggregates[a.id]!.lastSoldAt).inDays.compareTo(now.difference(aggregates[b.id]!.lastSoldAt).inDays) * -1);
      final tiedUpValue = slow.fold(0.0, (s, p) => s + p.price * p.stock);
      return base(
        kpis: [
          ReportKpi(label: 'أصناف راكدة', value: '${slow.length}'),
          ReportKpi(label: 'قيمتها', value: _money(tiedUpValue)),
        ],
        rowsTitle: 'الأصناف الأطول ركودًا',
        rows: [
          for (final p in slow)
            ReportRow(
              title: p.name,
              subtitle: 'بدون بيع منذ ${now.difference(aggregates[p.id]!.lastSoldAt).inDays} يومًا',
              trailing: _money(p.price * p.stock),
              icon: LucideIcons.hourglass,
              danger: now.difference(aggregates[p.id]!.lastSoldAt).inDays >= 45,
            ),
        ],
      );

    case 'customers':
    case 'sales_by_customer':
      final byCustomer = <String, double>{};
      final countByCustomer = <String, int>{};
      for (final s in sales) {
        final name = s.customerName ?? 'عميل نقدي';
        byCustomer[name] = (byCustomer[name] ?? 0) + s.total;
        countByCustomer[name] = (countByCustomer[name] ?? 0) + 1;
      }
      final sorted = byCustomer.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final avg = sales.isEmpty ? 0.0 : sales.fold(0.0, (s, r) => s + r.total) / sales.length;
      return base(
        kpis: id == 'customers'
            ? [
                ReportKpi(label: 'إجمالي العملاء', value: '${customers.length}'),
                ReportKpi(label: 'عملاء عاملون (لهم مبيعات)', value: '${sorted.length}'),
              ]
            : [ReportKpi(label: 'متوسط الشراء للفاتورة', value: _money(avg))],
        rowsTitle: id == 'customers' ? 'أفضل العملاء' : 'المبيعات حسب العميل',
        rows: [
          for (final e in sorted.take(10))
            ReportRow(title: e.key, subtitle: '${countByCustomer[e.key]} عملية شراء', trailing: _money(e.value), icon: LucideIcons.star),
        ],
      );

    case 'suppliers':
      final payable = suppliers.fold(0.0, (s, sup) => s + sup.payable);
      final owed = suppliers.where((s) => s.payable > 0).toList()..sort((a, b) => b.payable.compareTo(a.payable));
      return base(
        kpis: [
          ReportKpi(label: 'إجمالي الموردين', value: '${suppliers.length}'),
          ReportKpi(label: 'مستحقات لموردين', value: _money(payable)),
        ],
        rowsTitle: 'الموردون',
        rows: [
          for (final s in owed) ReportRow(title: s.name, subtitle: s.lastOrder, trailing: _money(s.payable), icon: LucideIcons.truck, danger: s.payable > 0),
        ],
      );

    case 'employees':
      final byEmployee = <String, double>{};
      final countByEmployee = <String, int>{};
      for (final s in sales) {
        final name = s.cashierName ?? 'غير معروف';
        byEmployee[name] = (byEmployee[name] ?? 0) + s.total;
        countByEmployee[name] = (countByEmployee[name] ?? 0) + 1;
      }
      final sorted = byEmployee.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return base(
        kpis: [
          ReportKpi(label: 'موظفون لهم مبيعات', value: '${sorted.length}'),
          ReportKpi(label: 'أعلى مبيعات', value: sorted.isEmpty ? '—' : sorted.first.key),
        ],
        rowsTitle: 'أداء الموظفين',
        rows: [
          for (final e in sorted) ReportRow(title: e.key, subtitle: '${countByEmployee[e.key]} فاتورة', trailing: _money(e.value), icon: LucideIcons.user),
        ],
      );

    case 'cashier':
      final deletions = <String, int>{};
      for (final e in activityLog.where((e) => e.category == 'حذف')) {
        deletions[e.employeeName] = (deletions[e.employeeName] ?? 0) + 1;
      }
      final sorted = deletions.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final totalDiscount = sales.fold(0.0, (s, r) => s + r.discountAmount);
      return base(
        kpis: [
          ReportKpi(label: 'عمليات حذف مسجّلة', value: '${deletions.values.fold(0, (s, v) => s + v)}'),
          ReportKpi(label: 'إجمالي الخصومات المعطاة', value: _money(totalDiscount)),
        ],
        rowsTitle: 'نشاط الحذف حسب الموظف',
        rows: sorted.isEmpty
            ? []
            : [for (final e in sorted) ReportRow(title: e.key, subtitle: '${e.value} عملية حذف', trailing: e.value >= 3 ? 'راجع السبب' : 'طبيعي', icon: e.value >= 3 ? LucideIcons.alertTriangle : LucideIcons.checkCircle2, danger: e.value >= 3)],
      );

    case 'branches':
      // No branch is captured on a sale at checkout time yet — showing a
      // fabricated per-branch split would be worse than an honest single
      // total, so this stays a real aggregate rather than invented rows.
      final revenue = sales.fold(0.0, (s, r) => s + r.total);
      return base(
        kpis: [
          ReportKpi(label: 'إجمالي المبيعات (كل الفروع)', value: _money(revenue)),
        ],
        rowsTitle: 'ملاحظة',
        rows: const [
          ReportRow(title: 'التقسيم حسب الفرع غير متاح بعد', subtitle: 'المبيعات لا تُسجَّل بفرع محدد حاليًا', trailing: '', icon: LucideIcons.info),
        ],
      );

    default:
      return fallback;
  }
}

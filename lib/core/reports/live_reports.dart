import '../pos/sales_log_controller.dart';

/// Live KPI figures computed from a set of real, completed sales — the
/// caller decides the window (today, this week, all-time...) by filtering
/// the list before passing it in.
class LiveSalesFigures {
  const LiveSalesFigures({required this.totalRevenue, required this.invoiceCount, required this.avgInvoice});
  final double totalRevenue;
  final int invoiceCount;
  final double avgInvoice;

  factory LiveSalesFigures.from(List<SaleRecord> sales) {
    final totalRevenue = sales.fold(0.0, (s, r) => s + r.total);
    final count = sales.length;
    return LiveSalesFigures(
      totalRevenue: totalRevenue,
      invoiceCount: count,
      avgInvoice: count == 0 ? 0 : totalRevenue / count,
    );
  }
}

class LiveProfitFigures {
  const LiveProfitFigures({required this.netProfit, required this.marginPercent, required this.cogs});
  final double netProfit;
  final double marginPercent;
  final double cogs;

  factory LiveProfitFigures.from(List<SaleRecord> sales) {
    final revenue = sales.fold(0.0, (s, r) => s + r.total);
    final profit = sales.fold(0.0, (s, r) => s + r.profit);
    final cogs = sales.fold(0.0, (s, r) => s + r.cost);
    return LiveProfitFigures(
      netProfit: profit,
      marginPercent: revenue == 0 ? 0 : (profit / revenue) * 100,
      cogs: cogs,
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

List<SaleRecord> salesOnDay(List<SaleRecord> sales, DateTime day) => sales.where((s) => _isSameDay(s.createdAt, day)).toList();

List<SaleRecord> salesToday(List<SaleRecord> sales) => salesOnDay(sales, DateTime.now());

List<SaleRecord> salesYesterday(List<SaleRecord> sales) => salesOnDay(sales, DateTime.now().subtract(const Duration(days: 1)));

/// Percentage change from [from] to [to] — null when there's nothing to
/// compare against (no baseline), so the caller can hide a trend badge
/// instead of showing a misleading "+100%"/"-100%" off a zero baseline.
double? percentChange(double from, double to) {
  if (from == 0) return null;
  return ((to - from) / from) * 100;
}

const _shortWeekdayLabels = {1: 'اثنين', 2: 'ثلاثاء', 3: 'أربعاء', 4: 'خميس', 5: 'جمعة', 6: 'سبت', 7: 'أحد'};

class WeeklySeries {
  const WeeklySeries({required this.values, required this.labels});
  final List<double> values;
  final List<String> labels;
}

/// Real profit per day for the last 7 calendar days (oldest first), built
/// from actually-completed sales — replaces the old hardcoded demo series
/// on the Home dashboard and the Sales Forecast screen.
WeeklySeries weeklyProfitSeries(List<SaleRecord> sales) {
  final today = DateTime.now();
  final days = List.generate(7, (i) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - i)));
  final values = [for (final day in days) salesOnDay(sales, day).fold(0.0, (s, r) => s + r.profit)];
  final labels = [for (final day in days) _shortWeekdayLabels[day.weekday]!];
  return WeeklySeries(values: values, labels: labels);
}

/// Real revenue per day for the last 7 calendar days (oldest first) — same
/// shape as [weeklyProfitSeries], for the Sales report's chart.
WeeklySeries weeklyRevenueSeries(List<SaleRecord> sales) {
  final today = DateTime.now();
  final days = List.generate(7, (i) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - i)));
  final values = [for (final day in days) salesOnDay(sales, day).fold(0.0, (s, r) => s + r.total)];
  final labels = [for (final day in days) _shortWeekdayLabels[day.weekday]!];
  return WeeklySeries(values: values, labels: labels);
}

class ProductSalesAggregate {
  const ProductSalesAggregate({required this.qtySold, required this.revenue, required this.lastSoldAt});
  final int qtySold;
  final double revenue;
  final DateTime lastSoldAt;
}

/// Real per-product sales totals, aggregated straight from completed sale
/// lines — the source of truth for "top selling products" and for how
/// long it's been since a product last sold, instead of a stored field on
/// the product itself that nothing ever kept up to date.
Map<String, ProductSalesAggregate> productSalesAggregates(List<SaleRecord> sales) {
  final qty = <String, int>{};
  final revenue = <String, double>{};
  final lastSoldAt = <String, DateTime>{};

  for (final sale in sales) {
    for (final line in sale.lines) {
      qty[line.productId] = (qty[line.productId] ?? 0) + line.qty;
      revenue[line.productId] = (revenue[line.productId] ?? 0) + line.revenue;
      final current = lastSoldAt[line.productId];
      if (current == null || sale.createdAt.isAfter(current)) {
        lastSoldAt[line.productId] = sale.createdAt;
      }
    }
  }

  return {
    for (final id in qty.keys) id: ProductSalesAggregate(qtySold: qty[id]!, revenue: revenue[id]!, lastSoldAt: lastSoldAt[id]!),
  };
}

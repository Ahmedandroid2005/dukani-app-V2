import 'package:flutter/material.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ReportChartType { line, bar, pie, none }

class ReportKpi {
  const ReportKpi({required this.label, required this.value, this.trend, this.trendUp});
  final String label;
  final String value;
  final String? trend;
  final bool? trendUp;
}

class ReportRow {
  const ReportRow({required this.title, required this.subtitle, required this.trailing, this.icon, this.danger = false});
  final String title;
  final String subtitle;
  final String trailing;
  final IconData? icon;
  final bool danger;
}

class ReportDefinition {
  ReportDefinition({
    required this.id,
    required this.title,
    required this.icon,
    required this.category,
    required this.kpis,
    this.chartType = ReportChartType.none,
    this.chartValues = const [],
    this.chartLabels = const [],
    required this.rowsTitle,
    required this.rows,
  });

  final String id;
  final String title;
  final IconData icon;
  final ReportCategory category;
  final List<ReportKpi> kpis;
  final ReportChartType chartType;
  final List<double> chartValues;
  final List<String> chartLabels;
  final String rowsTitle;
  final List<ReportRow> rows;
}

enum ReportCategory {
  financial('التقارير المالية', LucideIcons.wallet),
  inventory('تقارير المخزون', LucideIcons.warehouse),
  customersSuppliers('تقارير العملاء والموردين', LucideIcons.users),
  employeesBranches('تقارير الموظفين والفروع', LucideIcons.idCard);

  const ReportCategory(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _weekLabels = ['خميس', 'جمعة', 'سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء'];

final List<ReportDefinition> mockReports = [
  // ── التقارير المالية ──────────────────────────────────────────
  ReportDefinition(
    id: 'sales',
    title: 'تقرير المبيعات',
    icon: LucideIcons.store,
    category: ReportCategory.financial,
    kpis: [
      ReportKpi(label: 'إجمالي المبيعات', value: '32,650 ${currentCurrencySymbol()}', trend: '18.5%', trendUp: true),
      ReportKpi(label: 'عدد الفواتير', value: '128', trend: '12 فاتورة', trendUp: true),
      ReportKpi(label: 'متوسط الفاتورة', value: '255 ${currentCurrencySymbol()}'),
    ],
    chartType: ReportChartType.line,
    chartValues: [3200, 4100, 3800, 5200, 4800, 6100, 8250],
    chartLabels: _weekLabels,
    rowsTitle: 'أحدث الفواتير',
    rows: [
      ReportRow(title: 'INV-1042', subtitle: 'أحمد الشمري — بطاقة', trailing: '186.50 ${currentCurrencySymbol()}', icon: LucideIcons.receipt),
      ReportRow(title: 'INV-1041', subtitle: 'عميل نقدي — نقدًا', trailing: '42.00 ${currentCurrencySymbol()}', icon: LucideIcons.receipt),
      ReportRow(title: 'INV-1040', subtitle: 'ليان حسن — Apple Pay', trailing: '310.00 ${currentCurrencySymbol()}', icon: LucideIcons.receipt),
    ],
  ),
  ReportDefinition(
    id: 'profits',
    title: 'تقرير الأرباح',
    icon: LucideIcons.trendingUp,
    category: ReportCategory.financial,
    kpis: [
      ReportKpi(label: 'صافي الربح', value: '8,250 ${currentCurrencySymbol()}', trend: '18.5%', trendUp: true),
      ReportKpi(label: 'هامش الربح', value: '25.3%'),
      ReportKpi(label: 'تكلفة البضاعة', value: '18,400 ${currentCurrencySymbol()}'),
    ],
    chartType: ReportChartType.line,
    chartValues: [3200, 4100, 3800, 5200, 4800, 6100, 8250],
    chartLabels: _weekLabels,
    rowsTitle: 'أكثر الأقسام ربحًا',
    rows: [
      ReportRow(title: 'المشروبات', subtitle: '128 عملية بيع', trailing: '3,250 ${currentCurrencySymbol()}', icon: LucideIcons.coffee),
      ReportRow(title: 'المخبوزات', subtitle: '54 عملية بيع', trailing: '1,850 ${currentCurrencySymbol()}', icon: LucideIcons.croissant),
    ],
  ),
  ReportDefinition(
    id: 'expenses',
    title: 'تقرير المصروفات',
    icon: LucideIcons.receipt,
    category: ReportCategory.financial,
    kpis: [
      ReportKpi(label: 'إجمالي المصروفات', value: '5,420 ${currentCurrencySymbol()}', trend: '4.2%', trendUp: false),
      ReportKpi(label: 'أكبر تصنيف', value: 'الإيجار'),
    ],
    chartType: ReportChartType.pie,
    rowsTitle: 'المصروفات حسب التصنيف',
    rows: [
      ReportRow(title: 'الإيجار', subtitle: 'شهري', trailing: '2,500 ${currentCurrencySymbol()}', icon: LucideIcons.building2),
      ReportRow(title: 'الكهرباء والماء', subtitle: 'شهري', trailing: '850 ${currentCurrencySymbol()}', icon: LucideIcons.zap),
      ReportRow(title: 'رواتب جزئية', subtitle: 'أسبوعي', trailing: '1,200 ${currentCurrencySymbol()}', icon: LucideIcons.users),
      ReportRow(title: 'صيانة', subtitle: 'غير دوري', trailing: '870 ${currentCurrencySymbol()}', icon: LucideIcons.wrench),
    ],
  ),
  ReportDefinition(
    id: 'debts',
    title: 'تقرير الديون',
    icon: LucideIcons.fileText,
    category: ReportCategory.financial,
    kpis: [
      ReportKpi(label: 'إجمالي الديون', value: '1,550 ${currentCurrencySymbol()}'),
      ReportKpi(label: 'عملاء مدينون', value: '3'),
      ReportKpi(label: 'متأخرة', value: '450 ${currentCurrencySymbol()}', trend: 'تحتاج متابعة', trendUp: false),
    ],
    rowsTitle: 'العملاء المدينون',
    rows: [
      ReportRow(title: 'خالد المطيري', subtitle: 'آخر عملية: قبل يومين', trailing: '450 ${currentCurrencySymbol()}', icon: LucideIcons.user, danger: true),
      ReportRow(title: 'نورة العتيبي', subtitle: 'آخر عملية: قبل 5 أيام', trailing: '120 ${currentCurrencySymbol()}', icon: LucideIcons.user),
      ReportRow(title: 'فهد القحطاني', subtitle: 'آخر عملية: أمس', trailing: '980 ${currentCurrencySymbol()}', icon: LucideIcons.user, danger: true),
    ],
  ),
  ReportDefinition(
    id: 'payments',
    title: 'تقرير المدفوعات',
    icon: LucideIcons.creditCard,
    category: ReportCategory.financial,
    kpis: [
      ReportKpi(label: 'نقدًا', value: '12,400 ${currentCurrencySymbol()}'),
      ReportKpi(label: 'بطاقة', value: '15,200 ${currentCurrencySymbol()}'),
      ReportKpi(label: 'محافظ رقمية', value: '5,050 ${currentCurrencySymbol()}'),
    ],
    chartType: ReportChartType.pie,
    rowsTitle: 'طرق الدفع',
    rows: [
      ReportRow(title: 'نقدًا', subtitle: '38% من المبيعات', trailing: '12,400 ${currentCurrencySymbol()}', icon: LucideIcons.wallet),
      ReportRow(title: 'بطاقة', subtitle: '47% من المبيعات', trailing: '15,200 ${currentCurrencySymbol()}', icon: LucideIcons.creditCard),
      ReportRow(title: 'Apple Pay / Google Pay', subtitle: '15% من المبيعات', trailing: '5,050 ${currentCurrencySymbol()}', icon: LucideIcons.smartphone),
    ],
  ),
  ReportDefinition(
    id: 'taxes',
    title: 'تقرير الضرائب',
    icon: LucideIcons.percent,
    category: ReportCategory.financial,
    kpis: [
      ReportKpi(label: 'ضريبة القيمة المضافة المحصّلة', value: '4,897 ${currentCurrencySymbol()}'),
      ReportKpi(label: 'نسبة الضريبة', value: '15%'),
    ],
    rowsTitle: 'الضريبة حسب الفترة',
    rows: [
      ReportRow(title: 'هذا الأسبوع', subtitle: '128 فاتورة', trailing: '4,897 ${currentCurrencySymbol()}', icon: LucideIcons.calendarRange),
      ReportRow(title: 'الأسبوع الماضي', subtitle: '109 فواتير', trailing: '4,120 ${currentCurrencySymbol()}', icon: LucideIcons.calendarRange),
    ],
  ),

  // ── تقارير المخزون ────────────────────────────────────────────
  ReportDefinition(
    id: 'inventory',
    title: 'تقرير المخزون',
    icon: LucideIcons.package,
    category: ReportCategory.inventory,
    kpis: [
      ReportKpi(label: 'إجمالي المنتجات', value: '342'),
      ReportKpi(label: 'قيمة المخزون', value: '186,400 ${currentCurrencySymbol()}'),
      ReportKpi(label: 'قاربت على النفاد', value: '3', trend: 'تحتاج طلب', trendUp: false),
    ],
    rowsTitle: 'المنتجات',
    rows: [
      ReportRow(title: 'قهوة تركية', subtitle: 'المخزون: 40 وحدة', trailing: '1,250 ${currentCurrencySymbol()}', icon: LucideIcons.package),
      ReportRow(title: 'مياه معدنية', subtitle: 'المخزون: 210 وحدة', trailing: '750 ${currentCurrencySymbol()}', icon: LucideIcons.package),
    ],
  ),
  ReportDefinition(
    id: 'stock_movement',
    title: 'تقرير حركة المخزون',
    icon: LucideIcons.arrowLeftRight,
    category: ReportCategory.inventory,
    kpis: [
      ReportKpi(label: 'وارد', value: '540 وحدة'),
      ReportKpi(label: 'صادر (مبيعات)', value: '618 وحدة'),
      ReportKpi(label: 'تالف/مرتجع', value: '12 وحدة', trend: 'راجع السبب', trendUp: false),
    ],
    rowsTitle: 'آخر الحركات',
    rows: [
      ReportRow(title: 'كرواسون', subtitle: 'صادر — عملية بيع', trailing: '-3', icon: LucideIcons.arrowUp),
      ReportRow(title: 'أرز بسمتي', subtitle: 'وارد — فاتورة شراء', trailing: '+100', icon: LucideIcons.arrowDown),
      ReportRow(title: 'حليب', subtitle: 'تالف — انتهاء صلاحية', trailing: '-6', icon: LucideIcons.alertTriangle, danger: true),
    ],
  ),
  ReportDefinition(
    id: 'items',
    title: 'تقرير الأصناف',
    icon: LucideIcons.layoutGrid,
    category: ReportCategory.inventory,
    kpis: [
      ReportKpi(label: 'عدد الأصناف', value: '342'),
      ReportKpi(label: 'عدد التصنيفات', value: '8'),
    ],
    rowsTitle: 'أفضل الأصناف مبيعًا',
    rows: [
      ReportRow(title: 'قهوة تركية', subtitle: 'مشروبات — 128 عملية بيع', trailing: '1,250 ${currentCurrencySymbol()}', icon: LucideIcons.coffee),
      ReportRow(title: 'مياه معدنية', subtitle: 'مشروبات — 300 عملية بيع', trailing: '750 ${currentCurrencySymbol()}', icon: LucideIcons.droplet),
    ],
  ),
  ReportDefinition(
    id: 'expiring',
    title: 'تقرير الأصناف المنتهية',
    icon: LucideIcons.calendarX,
    category: ReportCategory.inventory,
    kpis: [
      ReportKpi(label: 'أصناف قاربت على الانتهاء', value: '4', trend: 'خلال 7 أيام', trendUp: false),
      ReportKpi(label: 'قيمة الخسارة المحتملة', value: '340 ${currentCurrencySymbol()}'),
    ],
    rowsTitle: 'الأصناف حسب تاريخ الانتهاء',
    rows: [
      ReportRow(title: 'حليب طازج', subtitle: 'ينتهي بعد يومين', trailing: '18 وحدة', icon: LucideIcons.calendarX, danger: true),
      ReportRow(title: 'زبادي', subtitle: 'ينتهي بعد 4 أيام', trailing: '10 وحدة', icon: LucideIcons.calendarX, danger: true),
      ReportRow(title: 'عصير طازج', subtitle: 'ينتهي بعد أسبوع', trailing: '6 وحدة', icon: LucideIcons.calendarX),
    ],
  ),
  ReportDefinition(
    id: 'stocktake',
    title: 'تقرير الجرد',
    icon: LucideIcons.clipboardCheck,
    category: ReportCategory.inventory,
    kpis: [
      ReportKpi(label: 'آخر جرد', value: 'منذ 12 يومًا'),
      ReportKpi(label: 'فروقات مكتشفة', value: '5 أصناف', trend: 'راجع السبب', trendUp: false),
    ],
    rowsTitle: 'فروقات آخر جرد',
    rows: [
      ReportRow(title: 'كرواسون', subtitle: 'متوقع 30 — فعلي 26', trailing: '-4', icon: LucideIcons.equal, danger: true),
      ReportRow(title: 'شاي أخضر', subtitle: 'متوقع 70 — فعلي 65', trailing: '-5', icon: LucideIcons.equal, danger: true),
    ],
  ),
  ReportDefinition(
    id: 'slow_moving',
    title: 'تقرير الأصناف الراكدة',
    icon: LucideIcons.hourglass,
    category: ReportCategory.inventory,
    kpis: [
      ReportKpi(label: 'أصناف راكدة', value: '6'),
      ReportKpi(label: 'قيمتها', value: '2,140 ${currentCurrencySymbol()}', trend: 'رأس مال معطّل', trendUp: false),
    ],
    rowsTitle: 'الأصناف الأطول ركودًا',
    rows: [
      ReportRow(title: 'زيت زيتون فاخر', subtitle: 'بدون بيع منذ 45 يومًا', trailing: '620 ${currentCurrencySymbol()}', icon: LucideIcons.hourglass, danger: true),
      ReportRow(title: 'شوكولاتة مستوردة', subtitle: 'بدون بيع منذ 38 يومًا', trailing: '410 ${currentCurrencySymbol()}', icon: LucideIcons.hourglass),
    ],
  ),

  // ── تقارير العملاء والموردين ──────────────────────────────────
  ReportDefinition(
    id: 'customers',
    title: 'تقرير العملاء',
    icon: LucideIcons.users,
    category: ReportCategory.customersSuppliers,
    kpis: [
      ReportKpi(label: 'إجمالي العملاء', value: '214'),
      ReportKpi(label: 'عملاء جدد هذا الشهر', value: '18', trend: '12%', trendUp: true),
    ],
    rowsTitle: 'أفضل العملاء',
    rows: [
      ReportRow(title: 'أحمد الشمري', subtitle: '24 عملية شراء', trailing: '4,820 ${currentCurrencySymbol()}', icon: LucideIcons.star),
      ReportRow(title: 'ليان حسن', subtitle: '19 عملية شراء', trailing: '3,110 ${currentCurrencySymbol()}', icon: LucideIcons.star),
    ],
  ),
  ReportDefinition(
    id: 'sales_by_customer',
    title: 'تقرير المبيعات حسب العميل',
    icon: LucideIcons.userSearch,
    category: ReportCategory.customersSuppliers,
    kpis: [
      ReportKpi(label: 'متوسط الشراء للعميل', value: '186 ${currentCurrencySymbol()}'),
    ],
    rowsTitle: 'المبيعات حسب العميل',
    rows: [
      ReportRow(title: 'أحمد الشمري', subtitle: 'آخر شراء: اليوم', trailing: '4,820 ${currentCurrencySymbol()}', icon: LucideIcons.receipt),
      ReportRow(title: 'عميل نقدي (متنوع)', subtitle: 'بدون بيانات عميل', trailing: '9,240 ${currentCurrencySymbol()}', icon: LucideIcons.receipt),
    ],
  ),
  ReportDefinition(
    id: 'suppliers',
    title: 'تقرير الموردين',
    icon: LucideIcons.truck,
    category: ReportCategory.customersSuppliers,
    kpis: [
      ReportKpi(label: 'إجمالي الموردين', value: '12'),
      ReportKpi(label: 'مستحقات لموردين', value: '3,400 ${currentCurrencySymbol()}', trend: 'تحتاج سداد', trendUp: false),
    ],
    rowsTitle: 'الموردون',
    rows: [
      ReportRow(title: 'شركة الأمانة للتوريد', subtitle: 'آخر توريد: أمس', trailing: '1,800 ${currentCurrencySymbol()}', icon: LucideIcons.truck, danger: true),
      ReportRow(title: 'مؤسسة الوفاء', subtitle: 'آخر توريد: قبل 4 أيام', trailing: '1,600 ${currentCurrencySymbol()}', icon: LucideIcons.truck, danger: true),
    ],
  ),

  // ── تقارير الموظفين والفروع ───────────────────────────────────
  ReportDefinition(
    id: 'employees',
    title: 'تقرير الموظفين',
    icon: LucideIcons.idCard,
    category: ReportCategory.employeesBranches,
    kpis: [
      ReportKpi(label: 'إجمالي الموظفين', value: '6'),
      ReportKpi(label: 'أعلى مبيعات', value: 'سارة علي'),
    ],
    rowsTitle: 'أداء الموظفين',
    rows: [
      ReportRow(title: 'سارة علي', subtitle: '68 فاتورة هذا الأسبوع', trailing: '12,400 ${currentCurrencySymbol()}', icon: LucideIcons.user),
      ReportRow(title: 'محمد راشد', subtitle: '52 فاتورة هذا الأسبوع', trailing: '9,850 ${currentCurrencySymbol()}', icon: LucideIcons.user),
    ],
  ),
  ReportDefinition(
    id: 'cashier',
    title: 'تقرير الكاشير',
    icon: LucideIcons.store,
    category: ReportCategory.employeesBranches,
    kpis: [
      ReportKpi(label: 'عمليات حذف الفواتير', value: '4', trend: 'أعلى من المعتاد', trendUp: false),
      ReportKpi(label: 'إجمالي الخصومات المعطاة', value: '620 ${currentCurrencySymbol()}'),
    ],
    rowsTitle: 'نشاط الكاشير',
    rows: [
      ReportRow(title: 'محمد راشد', subtitle: '4 عمليات حذف فواتير اليوم', trailing: 'راجع السبب', icon: LucideIcons.alertTriangle, danger: true),
      ReportRow(title: 'سارة علي', subtitle: '0 عمليات حذف', trailing: 'طبيعي', icon: LucideIcons.checkCircle2),
    ],
  ),
  ReportDefinition(
    id: 'branches',
    title: 'تقرير الفروع',
    icon: LucideIcons.store,
    category: ReportCategory.employeesBranches,
    kpis: [
      ReportKpi(label: 'عدد الفروع', value: '2'),
      ReportKpi(label: 'أعلى فرع مبيعًا', value: 'الفرع الرئيسي'),
    ],
    rowsTitle: 'المبيعات حسب الفرع',
    rows: [
      ReportRow(title: 'الفرع الرئيسي', subtitle: '96 فاتورة اليوم', trailing: '24,200 ${currentCurrencySymbol()}', icon: LucideIcons.store),
      ReportRow(title: 'فرع الروضة', subtitle: '32 فاتورة اليوم', trailing: '8,450 ${currentCurrencySymbol()}', icon: LucideIcons.store),
    ],
  ),
];

ReportDefinition? findReport(String id) {
  for (final r in mockReports) {
    if (r.id == id) return r;
  }
  return null;
}

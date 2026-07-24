import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_models.dart';
import '../activity/activity_log_controller.dart';
import '../pos/sales_log_controller.dart';
import '../products/products_controller.dart';
import '../reports/live_reports.dart';
import 'package:dukani_app/core/business/currency.dart';

enum ProductAlertKind { expiry, slowMoving }

/// A single proactive, product-driven alert — computed live from the
/// catalog rather than pre-written, so it reflects whatever the merchant's
/// stock actually looks like right now.
class ProductAlert {
  const ProductAlert({
    required this.kind,
    required this.product,
    required this.severity,
    required this.title,
    required this.description,
  });

  final ProductAlertKind kind;
  final MockProduct product;
  final String severity; // 'danger' | 'warning' | 'info'
  final String title;
  final String description;
}

const _severityRank = {'danger': 0, 'warning': 1, 'info': 2};

/// Expiry and slow-moving alerts, recomputed from the live catalog on every
/// change so a restock or a sale immediately updates what's shown — unlike
/// a report you have to remember to open, these surface proactively as
/// soon as a product crosses a threshold, well before it becomes urgent.
final productAlertsProvider = Provider<List<ProductAlert>>((ref) {
  final products = ref.watch(productsProvider);
  final salesAggregates = productSalesAggregates(ref.watch(salesLogProvider));
  final now = DateTime.now();
  final alerts = <ProductAlert>[];

  for (final product in products) {
    final expiry = product.expiryDate;
    if (expiry != null) {
      final daysLeft = expiry.difference(now).inHours / 24;
      if (daysLeft <= 30) {
        alerts.add(_expiryAlert(product, daysLeft));
      }
    }

    // Computed from real completed sales, not a stored field on the
    // product — nothing ever kept that field up to date after a sale.
    final lastSoldAt = salesAggregates[product.id]?.lastSoldAt;
    final daysSinceLastSale = lastSoldAt == null ? null : now.difference(lastSoldAt).inDays;
    if (daysSinceLastSale != null && daysSinceLastSale >= 21 && product.stock > 0) {
      alerts.add(_slowMovingAlert(product, daysSinceLastSale));
    }
  }

  alerts.sort((a, b) => _severityRank[a.severity]!.compareTo(_severityRank[b.severity]!));
  return alerts;
});

ProductAlert _expiryAlert(MockProduct product, double daysLeft) {
  final severity = daysLeft < 0
      ? 'danger'
      : daysLeft <= 2
          ? 'danger'
          : daysLeft <= 7
              ? 'warning'
              : 'info';

  final description = daysLeft < 0
      ? 'انتهت صلاحيته منذ ${(-daysLeft).ceil()} يوم — ${product.stock} وحدة بالمخزون'
      : daysLeft < 1
          ? 'تنتهي صلاحيته خلال ساعات — ${product.stock} وحدة بالمخزون'
          : 'تنتهي صلاحيته خلال ${daysLeft.ceil()} ${daysLeft.ceil() == 1 ? "يوم" : "أيام"} — ${product.stock} وحدة بالمخزون';

  return ProductAlert(
    kind: ProductAlertKind.expiry,
    product: product,
    severity: severity,
    title: daysLeft < 0 ? 'منتهي الصلاحية: ${product.name}' : 'قارب على الانتهاء: ${product.name}',
    description: description,
  );
}

/// Total count backing the home-screen bell's badge — same tally
/// [AlertsScreen] uses to decide its empty state, not a fabricated number.
/// There's no persisted "seen" marker yet, so this counts everything
/// currently open rather than claiming to know what's "unread".
final alertsCountProvider = Provider<int>((ref) {
  final productAlerts = ref.watch(productAlertsProvider).length;
  final sensitiveEntries = ref.watch(activityLogProvider).where((e) => e.sensitive).length;
  return productAlerts + sensitiveEntries;
});

ProductAlert _slowMovingAlert(MockProduct product, int daysSinceLastSale) {
  final severity = daysSinceLastSale >= 45 ? 'danger' : 'warning';
  final tiedUpValue = product.price * product.stock;
  return ProductAlert(
    kind: ProductAlertKind.slowMoving,
    product: product,
    severity: severity,
    title: 'صنف راكد: ${product.name}',
    description: 'بدون بيع منذ $daysSinceLastSale يومًا — ${tiedUpValue.toStringAsFixed(0)} ${currentCurrencySymbol()} رأس مال معطّل',
  );
}

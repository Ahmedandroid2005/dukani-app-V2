import 'package:hive_flutter/hive_flutter.dart';

/// Single entry point for local, offline-first storage. Every screen that
/// needs to work without a network connection reads/writes through a Hive
/// box opened here — never talks to a remote API directly. This is the
/// seam where a real backend gets plugged in later: repositories keep
/// reading local-first and a sync worker reconciles with the server,
/// instead of every screen needing to be retrofitted for offline support.
class LocalDb {
  LocalDb._();

  static const settingsBox = 'dukani_settings';
  static const pendingSyncBox = 'dukani_pending_sync';
  static const cachedSalesBox = 'dukani_cached_sales';

  // One box per persisted entity list — each holds a `PersistedListNotifier`
  // snapshot (one Hive entry per list item), so every module's data
  // survives an app restart instead of resetting to demo data every time.
  static const productsBox = 'dukani_products';
  static const categoriesBox = 'dukani_categories';
  static const customersBox = 'dukani_customers';
  static const suppliersBox = 'dukani_suppliers';
  static const expensesBox = 'dukani_expenses';
  static const employeesBox = 'dukani_employees';
  static const branchesBox = 'dukani_branches';
  static const activityLogBox = 'dukani_activity_log';
  static const taxesBox = 'dukani_taxes';
  static const offersBox = 'dukani_offers';
  static const couponsBox = 'dukani_coupons';
  static const purchaseOrdersBox = 'dukani_purchase_orders';
  static const ordersBox = 'dukani_orders';
  static const returnsBox = 'dukani_returns';
  static const transfersBox = 'dukani_transfers';
  static const salesLogBox = 'dukani_sales_log';
  static const shiftsBox = 'dukani_shifts';
  static const heldOrdersBox = 'dukani_held_orders';
  static const stocktakesBox = 'dukani_stocktakes';

  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(settingsBox),
      Hive.openBox(pendingSyncBox),
      Hive.openBox(cachedSalesBox),
      Hive.openBox(productsBox),
      Hive.openBox(categoriesBox),
      Hive.openBox(customersBox),
      Hive.openBox(suppliersBox),
      Hive.openBox(expensesBox),
      Hive.openBox(employeesBox),
      Hive.openBox(branchesBox),
      Hive.openBox(activityLogBox),
      Hive.openBox(taxesBox),
      Hive.openBox(offersBox),
      Hive.openBox(couponsBox),
      Hive.openBox(purchaseOrdersBox),
      Hive.openBox(ordersBox),
      Hive.openBox(returnsBox),
      Hive.openBox(transfersBox),
      Hive.openBox(salesLogBox),
      Hive.openBox(shiftsBox),
      Hive.openBox(heldOrdersBox),
      Hive.openBox(stocktakesBox),
    ]);
    _ready = true;
  }

  static Box get settings => Hive.box(settingsBox);
  static Box get pendingSync => Hive.box(pendingSyncBox);
  static Box get cachedSales => Hive.box(cachedSalesBox);

  static Box get products => Hive.box(productsBox);
  static Box get categories => Hive.box(categoriesBox);
  static Box get customers => Hive.box(customersBox);
  static Box get suppliers => Hive.box(suppliersBox);
  static Box get expenses => Hive.box(expensesBox);
  static Box get employees => Hive.box(employeesBox);
  static Box get branches => Hive.box(branchesBox);
  static Box get activityLog => Hive.box(activityLogBox);
  static Box get taxes => Hive.box(taxesBox);
  static Box get offers => Hive.box(offersBox);
  static Box get coupons => Hive.box(couponsBox);
  static Box get purchaseOrders => Hive.box(purchaseOrdersBox);
  static Box get orders => Hive.box(ordersBox);
  static Box get returns => Hive.box(returnsBox);
  static Box get transfers => Hive.box(transfersBox);
  static Box get salesLog => Hive.box(salesLogBox);
  static Box get shifts => Hive.box(shiftsBox);
  static Box get heldOrders => Hive.box(heldOrdersBox);
  static Box get stocktakes => Hive.box(stocktakesBox);
}

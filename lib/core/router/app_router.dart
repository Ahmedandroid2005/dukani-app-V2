import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/employee_login_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/store_setup/store_setup_wizard.dart';
import '../../features/store_setup/preparing_store_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/invoices_list_screen.dart';
import '../../features/home/invoice_detail_screen.dart';
import '../../features/home/top_products_screen.dart';
import '../../features/alerts/alerts_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/reports/report_detail_screen.dart';
import '../../features/pos/pos_screen.dart';
import '../../features/pos/cart_screen.dart';
import '../../features/pos/payment_screen.dart';
import '../../features/pos/sale_success_screen.dart';
import '../../features/pos/held_orders_screen.dart';
import '../../features/products/products_screen.dart';
import '../../features/products/product_form_screen.dart';
import '../../features/products/barcode_labels_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/inventory/stocktake_screen.dart';
import '../../features/customers/customers_screen.dart';
import '../../features/customers/customer_detail_screen.dart';
import '../../features/customers/customer_form_screen.dart';
import '../../features/suppliers/suppliers_screen.dart';
import '../../features/suppliers/supplier_detail_screen.dart';
import '../../features/suppliers/supplier_form_screen.dart';
import '../../features/expenses/expenses_screen.dart';
import '../../features/employees/employees_screen.dart';
import '../../features/employees/employee_form_screen.dart';
import '../../features/branches/branches_screen.dart';
import '../../features/branches/branch_form_screen.dart';
import '../../features/shift/shift_screen.dart';
import '../../features/activity/activity_log_screen.dart';
import '../../features/activity/audit_log_screen.dart';
import '../../features/returns/returns_screen.dart';
import '../../features/returns/return_new_screen.dart';
import '../../features/pricing/taxes_screen.dart';
import '../../features/pricing/offers_screen.dart';
import '../../features/pricing/coupons_screen.dart';
import '../../features/backup/backup_screen.dart';
import '../../features/subscription/subscription_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/support/support_screen.dart';
import '../../features/purchases/purchase_orders_screen.dart';
import '../../features/purchases/purchase_order_new_screen.dart';
import '../../features/transfers/transfers_screen.dart';
import '../../features/transfers/transfer_new_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/orders/order_new_screen.dart';
import '../../features/settings/printer_settings_screen.dart';
import '../../features/settings/payment_gateway_link_screen.dart';
import '../../features/import/import_screen.dart';
import '../../features/loyalty/loyalty_screen.dart';
import '../../features/forecast/forecast_screen.dart';
import '../../features/reports/day_summary_screen.dart';
import '../../features/placeholder/section_placeholder_screen.dart';
import '../../data/mock/mock_models.dart';
import '../animations/dukani_transitions.dart';
import '../session/session_controller.dart';
import 'root_container.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Route names used with context.pushNamed / goNamed instead of hardcoded
/// path strings, so a rename here doesn't ripple through every screen.
class R {
  R._();
  static const splash = 'splash';
  static const login = 'login';
  static const register = 'register';
  static const employeeLogin = 'employeeLogin';
  static const forgotPassword = 'forgotPassword';
  static const otp = 'otp';
  static const storeSetup = 'storeSetup';
  static const preparingStore = 'preparingStore';
  static const home = 'home';
  static const invoices = 'invoices';
  static const invoiceDetail = 'invoiceDetail';
  static const topProducts = 'topProducts';
  static const alerts = 'alerts';
  static const settings = 'settings';
  static const reports = 'reports';
  static const reportDetail = 'reportDetail';
  static const pos = 'pos';
  static const cart = 'cart';
  static const payment = 'payment';
  static const saleSuccess = 'saleSuccess';
  static const heldOrders = 'heldOrders';
  static const products = 'products';
  static const productNew = 'productNew';
  static const productEdit = 'productEdit';
  static const barcodeLabels = 'barcodeLabels';
  static const inventory = 'inventory';
  static const stocktake = 'stocktake';
  static const customers = 'customers';
  static const customerNew = 'customerNew';
  static const customerDetail = 'customerDetail';
  static const customerEdit = 'customerEdit';
  static const suppliers = 'suppliers';
  static const supplierNew = 'supplierNew';
  static const supplierDetail = 'supplierDetail';
  static const supplierEdit = 'supplierEdit';
  static const expenses = 'expenses';
  static const employees = 'employees';
  static const employeeNew = 'employeeNew';
  static const employeeEdit = 'employeeEdit';
  static const branches = 'branches';
  static const branchNew = 'branchNew';
  static const branchEdit = 'branchEdit';
  static const shift = 'shift';
  static const activityLog = 'activityLog';
  static const auditLog = 'auditLog';
  static const returns = 'returns';
  static const returnNew = 'returnNew';
  static const taxes = 'taxes';
  static const offers = 'offers';
  static const coupons = 'coupons';
  static const backup = 'backup';
  static const subscription = 'subscription';
  static const profile = 'profile';
  static const support = 'support';
  static const purchaseOrders = 'purchaseOrders';
  static const purchaseOrderNew = 'purchaseOrderNew';
  static const branchTransfer = 'branchTransfer';
  static const transferNew = 'transferNew';
  static const warehouses = 'warehouses';
  static const orders = 'orders';
  static const orderNew = 'orderNew';
  static const printerSettings = 'printerSettings';
  static const paymentGatewayLink = 'paymentGatewayLink';
  static const dataImport = 'dataImport';
  static const loyalty = 'loyalty';
  static const forecast = 'forecast';
  static const daySummary = 'daySummary';
  static const section = 'section';
}

/// Sections reachable from the home dashboard / drawer that are scaffolded
/// with a branded placeholder for now and will be built out screen-by-screen
/// in the next phases (per the agreed roadmap) — every button still
/// navigates somewhere real, nothing is a dead end.
enum DukaniSection {
  pos('نقطة البيع', LucideIcons.store),
  products('المنتجات', LucideIcons.package),
  inventory('المخزون', LucideIcons.warehouse),
  stocktake('الجرد', LucideIcons.clipboardCheck),
  customers('العملاء', LucideIcons.users),
  suppliers('الموردون', LucideIcons.truck),
  debts('الديون', LucideIcons.fileText),
  profits('الأرباح', LucideIcons.trendingUp),
  expenses('المصروفات', LucideIcons.receipt),
  reports('التقارير', LucideIcons.barChart3),
  alerts('التنبيهات', LucideIcons.bellRing),
  settings('الإعدادات', LucideIcons.settings),
  employees('الموظفون', LucideIcons.idCard),
  permissions('الصلاحيات', LucideIcons.shieldCheck),
  branches('الفروع', LucideIcons.store),
  taxes('الضرائب', LucideIcons.percent),
  offers('العروض', LucideIcons.tag),
  discounts('الخصومات', LucideIcons.badgePercent),
  returns('المرتجعات', LucideIcons.undo2),
  coupons('الكوبونات', LucideIcons.ticket),
  cashManagement('إدارة النقد', LucideIcons.wallet),
  shift('فتح وإغلاق الوردية', LucideIcons.clock),
  activityLog('سجل النشاط', LucideIcons.history),
  auditLog('سجل التدقيق', LucideIcons.fingerprint),
  orders('الطلبات', LucideIcons.listChecks),
  purchaseOrders('طلبات الشراء', LucideIcons.fileText),
  purchases('المشتريات', LucideIcons.shoppingCart),
  branchTransfer('التحويل بين الفروع', LucideIcons.arrowLeftRight),
  warehouses('إدارة المخازن', LucideIcons.warehouse),
  backup('النسخ الاحتياطي', LucideIcons.cloudCog),
  subscription('الاشتراك', LucideIcons.award),
  profile('الملف الشخصي', LucideIcons.circleUser),
  support('الدعم الفني', LucideIcons.headset);

  const DukaniSection(this.titleAr, this.icon);
  final String titleAr;
  final IconData icon;
}

/// Route name -> the [MockPermissions] flag an employee needs to reach it.
/// Only covers the flags actually collected on the employee form — the
/// store owner (session role == 'مالك') always has full access, same as an
/// owner-attributed session already gets everywhere else in the app.
final Map<String, bool Function(MockPermissions)> _permissionGatedRoutes = {
  R.reports: (p) => p.viewReports,
  R.reportDetail: (p) => p.viewReports,
  R.daySummary: (p) => p.viewReports,
  R.invoices: (p) => p.viewReports,
  R.invoiceDetail: (p) => p.viewReports,
  R.topProducts: (p) => p.viewReports,
  R.forecast: (p) => p.viewReports,
  R.employees: (p) => p.manageEmployees,
  R.employeeNew: (p) => p.manageEmployees,
  R.employeeEdit: (p) => p.manageEmployees,
  R.settings: (p) => p.manageSettings,
  R.taxes: (p) => p.manageSettings,
  R.offers: (p) => p.manageSettings,
  R.coupons: (p) => p.manageSettings,
  R.backup: (p) => p.manageSettings,
  R.subscription: (p) => p.manageSettings,
  R.paymentGatewayLink: (p) => p.manageSettings,
  R.returns: (p) => p.processRefund,
  R.returnNew: (p) => p.processRefund,
};

/// A logged-in employee who lacks the permission a route needs is bounced
/// back to the dashboard instead of just having the button hidden — hiding
/// the entry point alone never stopped a direct/remembered link from
/// working, which is exactly the gap "صلاحيات حقيقية" is about closing.
String? _permissionRedirect(BuildContext context, GoRouterState state) {
  final session = rootContainer.read(sessionProvider);
  if (session == null || session.role == 'مالك') return null;
  final allowed = _permissionGatedRoutes[state.name];
  if (allowed == null || allowed(session.permissions)) return null;
  return '/home';
}

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: _permissionRedirect,
  routes: [
    GoRoute(
      path: '/',
      name: R.splash,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const SplashScreen()),
    ),
    GoRoute(
      path: '/login',
      name: R.login,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const LoginScreen()),
    ),
    GoRoute(
      path: '/register',
      name: R.register,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const RegisterScreen()),
    ),
    GoRoute(
      path: '/employee-login',
      name: R.employeeLogin,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const EmployeeLoginScreen()),
    ),
    GoRoute(
      path: '/forgot-password',
      name: R.forgotPassword,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const ForgotPasswordScreen()),
    ),
    GoRoute(
      path: '/otp',
      name: R.otp,
      pageBuilder: (context, state) {
        final destination = state.uri.queryParameters['next'] ?? '/store-setup';
        return dukaniPage(state: state, child: OtpScreen(nextRoute: destination));
      },
    ),
    GoRoute(
      path: '/store-setup',
      name: R.storeSetup,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const StoreSetupWizard()),
    ),
    GoRoute(
      path: '/preparing-store',
      name: R.preparingStore,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const PreparingStoreScreen()),
    ),
    GoRoute(
      path: '/invoices',
      name: R.invoices,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const InvoicesListScreen()),
    ),
    GoRoute(
      path: '/invoices/:id',
      name: R.invoiceDetail,
      pageBuilder: (context, state) => dukaniPage(state: state, child: InvoiceDetailScreen(invoiceId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/top-products',
      name: R.topProducts,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const TopProductsScreen()),
    ),
    GoRoute(
      path: '/alerts',
      name: R.alerts,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const AlertsScreen()),
    ),
    GoRoute(
      path: '/settings',
      name: R.settings,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const SettingsScreen()),
    ),
    GoRoute(
      path: '/reports',
      name: R.reports,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const ReportsScreen()),
    ),
    GoRoute(
      path: '/reports/:id',
      name: R.reportDetail,
      pageBuilder: (context, state) => dukaniPage(state: state, child: ReportDetailScreen(reportId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/forecast',
      name: R.forecast,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const ForecastScreen()),
    ),
    GoRoute(
      path: '/day-summary',
      name: R.daySummary,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const DaySummaryScreen()),
    ),
    GoRoute(
      path: '/pos',
      name: R.pos,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const PosScreen()),
    ),
    GoRoute(
      path: '/pos/cart',
      name: R.cart,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const CartScreen()),
    ),
    GoRoute(
      path: '/pos/payment',
      name: R.payment,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const PaymentScreen()),
    ),
    GoRoute(
      path: '/pos/success',
      name: R.saleSuccess,
      pageBuilder: (context, state) => dukaniPage(state: state, child: SaleSuccessScreen(args: state.extra as SaleSuccessArgs)),
    ),
    GoRoute(
      path: '/pos/held',
      name: R.heldOrders,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const HeldOrdersScreen()),
    ),
    GoRoute(
      path: '/products',
      name: R.products,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const ProductsScreen()),
    ),
    GoRoute(
      path: '/products/new',
      name: R.productNew,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const ProductFormScreen()),
    ),
    GoRoute(
      path: '/products/barcode-labels',
      name: R.barcodeLabels,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const BarcodeLabelsScreen()),
    ),
    GoRoute(
      path: '/products/:id',
      name: R.productEdit,
      pageBuilder: (context, state) => dukaniPage(state: state, child: ProductFormScreen(productId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/inventory',
      name: R.inventory,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const InventoryScreen()),
    ),
    GoRoute(
      path: '/inventory/stocktake',
      name: R.stocktake,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const StocktakeScreen()),
    ),
    GoRoute(
      path: '/customers',
      name: R.customers,
      pageBuilder: (context, state) => dukaniPage(state: state, child: CustomersScreen(initialDebtOnly: state.uri.queryParameters['debt'] == 'true')),
    ),
    GoRoute(
      path: '/customers/new',
      name: R.customerNew,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const CustomerFormScreen()),
    ),
    GoRoute(
      path: '/customers/:id',
      name: R.customerDetail,
      pageBuilder: (context, state) => dukaniPage(state: state, child: CustomerDetailScreen(customerId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/customers/:id/edit',
      name: R.customerEdit,
      pageBuilder: (context, state) => dukaniPage(state: state, child: CustomerFormScreen(customerId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/suppliers',
      name: R.suppliers,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const SuppliersScreen()),
    ),
    GoRoute(
      path: '/suppliers/new',
      name: R.supplierNew,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const SupplierFormScreen()),
    ),
    GoRoute(
      path: '/suppliers/:id',
      name: R.supplierDetail,
      pageBuilder: (context, state) => dukaniPage(state: state, child: SupplierDetailScreen(supplierId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/suppliers/:id/edit',
      name: R.supplierEdit,
      pageBuilder: (context, state) => dukaniPage(state: state, child: SupplierFormScreen(supplierId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/expenses',
      name: R.expenses,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const ExpensesScreen()),
    ),
    GoRoute(
      path: '/employees',
      name: R.employees,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const EmployeesScreen()),
    ),
    GoRoute(
      path: '/employees/new',
      name: R.employeeNew,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const EmployeeFormScreen()),
    ),
    GoRoute(
      path: '/employees/:id',
      name: R.employeeEdit,
      pageBuilder: (context, state) => dukaniPage(state: state, child: EmployeeFormScreen(employeeId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/branches',
      name: R.branches,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const BranchesScreen()),
    ),
    GoRoute(
      path: '/warehouses',
      name: R.warehouses,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const BranchesScreen(warehousesOnly: true)),
    ),
    GoRoute(
      path: '/orders',
      name: R.orders,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const OrdersScreen()),
    ),
    GoRoute(
      path: '/orders/new',
      name: R.orderNew,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const OrderNewScreen()),
    ),
    GoRoute(
      path: '/printer-settings',
      name: R.printerSettings,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const PrinterSettingsScreen()),
    ),
    GoRoute(
      path: '/payment-gateway-link',
      name: R.paymentGatewayLink,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const PaymentGatewayLinkScreen()),
    ),
    GoRoute(
      path: '/import',
      name: R.dataImport,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const ImportScreen()),
    ),
    GoRoute(
      path: '/loyalty',
      name: R.loyalty,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const LoyaltyScreen()),
    ),
    GoRoute(
      path: '/branches/new',
      name: R.branchNew,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const BranchFormScreen()),
    ),
    GoRoute(
      path: '/branches/:id',
      name: R.branchEdit,
      pageBuilder: (context, state) => dukaniPage(state: state, child: BranchFormScreen(branchId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/shift',
      name: R.shift,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const ShiftScreen()),
    ),
    GoRoute(
      path: '/activity-log',
      name: R.activityLog,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const ActivityLogScreen()),
    ),
    GoRoute(
      path: '/audit-log',
      name: R.auditLog,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const AuditLogScreen()),
    ),
    GoRoute(
      path: '/returns',
      name: R.returns,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const ReturnsScreen()),
    ),
    GoRoute(
      path: '/returns/new',
      name: R.returnNew,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const ReturnNewScreen()),
    ),
    GoRoute(
      path: '/taxes',
      name: R.taxes,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const TaxesScreen()),
    ),
    GoRoute(
      path: '/offers',
      name: R.offers,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const OffersScreen()),
    ),
    GoRoute(
      path: '/coupons',
      name: R.coupons,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const CouponsScreen()),
    ),
    GoRoute(
      path: '/backup',
      name: R.backup,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const BackupScreen()),
    ),
    GoRoute(
      path: '/subscription',
      name: R.subscription,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const SubscriptionScreen()),
    ),
    GoRoute(
      path: '/profile',
      name: R.profile,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const ProfileScreen()),
    ),
    GoRoute(
      path: '/support',
      name: R.support,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const SupportScreen()),
    ),
    GoRoute(
      path: '/purchase-orders',
      name: R.purchaseOrders,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const PurchaseOrdersScreen()),
    ),
    GoRoute(
      path: '/purchase-orders/new',
      name: R.purchaseOrderNew,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const PurchaseOrderNewScreen()),
    ),
    GoRoute(
      path: '/branch-transfer',
      name: R.branchTransfer,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const TransfersScreen()),
    ),
    GoRoute(
      path: '/branch-transfer/new',
      name: R.transferNew,
      pageBuilder: (context, state) => dukaniPage(state: state, child: const TransferNewScreen()),
    ),
    GoRoute(
      path: '/section/:name',
      name: R.section,
      pageBuilder: (context, state) {
        final section = DukaniSection.values.firstWhere(
          (s) => s.name == state.pathParameters['name'],
          orElse: () => DukaniSection.pos,
        );
        return dukaniPage(state: state, child: SectionPlaceholderScreen(section: section));
      },
    ),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: R.home,
          pageBuilder: (context, state) => dukaniPage(state: state, child: const HomeScreen()),
        ),
      ],
    ),
  ],
);

/// Helper to navigate to a not-yet-built section from anywhere in the app.
void goToSection(BuildContext context, DukaniSection section) {
  context.pushNamed(R.section, pathParameters: {'name': section.name});
}

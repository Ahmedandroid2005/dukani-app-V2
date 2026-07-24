/// Lightweight demo-data models. The whole app runs on mock data for now —
/// no backend is wired up in this phase, so every screen can be reviewed
/// end-to-end without a network connection.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:dukani_app/core/offline/firestore_json.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// How a product is actually sold at the register:
/// - [each]: normal whole-unit item (the default — most of the catalog).
/// - [weight]: continuous loose weight, no container state (halva, cheese,
///   lunch meat, spices) — [pricePerKg]/[openStockKg] carry the sale.
/// - [bulkContainer]: sold loose by weight out of sealed sacks (rice, flour,
///   lentils) — [stock] is the sealed-sack count, [openStockKg] is what's
///   left in the currently-opened sack, [containerSizeKg] is a sack's size.
/// - [multiPack]: a sealed pack/case at one price and loose pieces at
///   another (egg cartons, cigarette packs vs. single sticks) — [stock] is
///   sealed packs, [looseUnits] is loose pieces, both sellable at once.
enum ProductUnitMode { each, weight, bulkContainer, multiPack }

/// Every icon a [MockProduct.icon] can ever hold (seed catalog + the add
/// product form's category fallback map). Persisting a product stores an
/// *index* into this fixed, all-const list rather than rebuilding an
/// `IconData` from a saved codepoint at runtime — the Flutter web/release
/// build's icon tree-shaker refuses to compile if it finds any non-const
/// `IconData(...)` call anywhere in the app, since it can't statically
/// prove which glyphs a dynamically-built one might need.
const List<IconData> mockProductIconPalette = [
  LucideIcons.package,
  LucideIcons.coffee,
  LucideIcons.coffee,
  LucideIcons.droplet,
  LucideIcons.cupSoda,
  LucideIcons.coffee,
  LucideIcons.croissant,
  LucideIcons.cake,
  LucideIcons.sandwich,
  LucideIcons.cookie,
  LucideIcons.wheat,
  LucideIcons.droplet,
  LucideIcons.hexagon,
  LucideIcons.egg,
  LucideIcons.cigarette,
  LucideIcons.shoppingBasket,
  LucideIcons.beef,
  LucideIcons.fish,
  LucideIcons.leaf,
  LucideIcons.snowflake,
  LucideIcons.iceCreamCone,
  LucideIcons.sprayCan,
  LucideIcons.flower2,
  LucideIcons.baby,
  LucideIcons.refrigerator,
  LucideIcons.pencil,
  LucideIcons.pawPrint,
];

/// One purchasable size/color combination of a variant-tracked product —
/// "قميص" isn't one stock count, it's one per size×color, and selling the
/// last "L أزرق" must not silently draw down a totally different variant's
/// stock. [size]/[color] are free text so this fits jewelry ("مقاس الخاتم"),
/// shoes, or anything else that varies along one or two axes — either can
/// be left blank to use just one.
class MockProductVariant {
  const MockProductVariant({
    required this.id,
    this.size = '',
    this.color = '',
    required this.stock,
    this.barcode = '',
    this.priceDelta = 0,
  });

  final String id;
  final String size;
  final String color;
  final int stock;
  final String barcode;
  /// Added to (or subtracted from) the product's base price — e.g. an XXL
  /// that costs a bit more than the base size.
  final double priceDelta;

  /// Display label for pickers and cart lines, e.g. "L / أزرق" — or just
  /// "L" or "أزرق" when the product only varies along one axis.
  String get label => [size, color].where((s) => s.isNotEmpty).join(' / ');

  MockProductVariant copyWith({int? stock}) => MockProductVariant(
        id: id,
        size: size,
        color: color,
        stock: stock ?? this.stock,
        barcode: barcode,
        priceDelta: priceDelta,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'size': size,
        'color': color,
        'stock': stock,
        'barcode': barcode,
        'priceDelta': priceDelta,
      };

  factory MockProductVariant.fromJson(Map<String, dynamic> json) => MockProductVariant(
        id: json['id'] as String,
        size: json['size'] as String,
        color: json['color'] as String,
        stock: json['stock'] as int,
        barcode: json['barcode'] as String,
        priceDelta: (json['priceDelta'] as num).toDouble(),
      );
}

class MockProduct {
  const MockProduct({
    this.id = '',
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.icon,
    this.barcode = '',
    this.soldQty = 0,
    this.revenue = 0,
    this.cost = 0,
    this.photoBytes,
    this.expiryDate,
    this.daysSinceLastSale,
    this.unitMode = ProductUnitMode.each,
    this.pricePerKg = 0,
    this.openStockKg = 0,
    this.containerSizeKg = 0,
    this.packSize = 0,
    this.packPrice = 0,
    this.piecePrice = 0,
    this.looseUnits = 0,
    this.variants = const [],
    this.serialNumber = '',
    this.warrantyMonths = 0,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  /// Fallback avatar shown whenever the merchant hasn't attached a real
  /// [photoBytes] photo yet (e.g. every seeded demo product).
  final IconData icon;
  final String barcode;
  final int soldQty;
  final double revenue;
  final double cost;
  /// Serial number / IMEI — only ever shown or edited for
  /// [BusinessType.electronics] (see [BusinessCapabilities.tracksSerialWarranty]).
  /// A single field rather than a per-unit ledger: enough for a small shop
  /// to note down "this exact phone" without a full stock-serialization
  /// system.
  final String serialNumber;
  /// Manufacturer/store warranty length in months, same electronics-only
  /// gating as [serialNumber]. Zero means "no warranty noted."
  final int warrantyMonths;
  /// Merchant-attached product photo (camera or gallery). Kept in memory as
  /// bytes rather than a file path so it renders identically on web and
  /// native without touching dart:io.
  final Uint8List? photoBytes;
  /// When set, drives the proactive expiry alerts — surfaced well before
  /// the date arrives, not just once it's already urgent.
  final DateTime? expiryDate;
  /// Days since this product last sold — drives the slow-moving alerts.
  final int? daysSinceLastSale;

  final ProductUnitMode unitMode;
  final double pricePerKg;
  final double openStockKg;
  final double containerSizeKg;
  final int packSize;
  final double packPrice;
  final double piecePrice;
  final int looseUnits;
  /// Size/color breakdown for variant-tracked products (clothing, shoes...).
  /// Empty for every other product — [stock] is then the real count, same
  /// as always.
  final List<MockProductVariant> variants;

  MockProduct copyWith({
    int? stock,
    Uint8List? photoBytes,
    bool clearPhoto = false,
    double? openStockKg,
    int? looseUnits,
    List<MockProductVariant>? variants,
  }) =>
      MockProduct(
        id: id,
        name: name,
        category: category,
        price: price,
        stock: stock ?? this.stock,
        icon: icon,
        barcode: barcode,
        soldQty: soldQty,
        revenue: revenue,
        cost: cost,
        photoBytes: clearPhoto ? null : (photoBytes ?? this.photoBytes),
        expiryDate: expiryDate,
        daysSinceLastSale: daysSinceLastSale,
        unitMode: unitMode,
        pricePerKg: pricePerKg,
        openStockKg: openStockKg ?? this.openStockKg,
        containerSizeKg: containerSizeKg,
        packSize: packSize,
        packPrice: packPrice,
        piecePrice: piecePrice,
        looseUnits: looseUnits ?? this.looseUnits,
        variants: variants ?? this.variants,
        serialNumber: serialNumber,
        warrantyMonths: warrantyMonths,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'stock': stock,
        'iconIndex': mockProductIconPalette.indexOf(icon).clamp(0, mockProductIconPalette.length - 1),
        'barcode': barcode,
        'soldQty': soldQty,
        'revenue': revenue,
        'cost': cost,
        'photoBytes': photoBytes,
        'expiryDate': expiryDate,
        'daysSinceLastSale': daysSinceLastSale,
        'unitMode': unitMode.name,
        'pricePerKg': pricePerKg,
        'openStockKg': openStockKg,
        'containerSizeKg': containerSizeKg,
        'packSize': packSize,
        'packPrice': packPrice,
        'piecePrice': piecePrice,
        'looseUnits': looseUnits,
        'variants': variants.map((v) => v.toJson()).toList(),
        'serialNumber': serialNumber,
        'warrantyMonths': warrantyMonths,
      };

  factory MockProduct.fromJson(Map<String, dynamic> json) => MockProduct(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        price: (json['price'] as num).toDouble(),
        stock: json['stock'] as int,
        icon: mockProductIconPalette[(json['iconIndex'] as int).clamp(0, mockProductIconPalette.length - 1)],
        barcode: json['barcode'] as String,
        soldQty: json['soldQty'] as int,
        revenue: (json['revenue'] as num).toDouble(),
        cost: (json['cost'] as num).toDouble(),
        photoBytes: asBytes(json['photoBytes']),
        expiryDate: asDateTime(json['expiryDate']),
        daysSinceLastSale: json['daysSinceLastSale'] as int?,
        unitMode: ProductUnitMode.values.byName(json['unitMode'] as String),
        pricePerKg: (json['pricePerKg'] as num).toDouble(),
        openStockKg: (json['openStockKg'] as num).toDouble(),
        containerSizeKg: (json['containerSizeKg'] as num).toDouble(),
        packSize: json['packSize'] as int,
        packPrice: (json['packPrice'] as num).toDouble(),
        piecePrice: (json['piecePrice'] as num).toDouble(),
        looseUnits: json['looseUnits'] as int,
        // Absent on products persisted before variants existed — treated
        // as "no variants", same as any other product.
        variants: (json['variants'] as List?)?.map((v) => MockProductVariant.fromJson(Map<String, dynamic>.from(v as Map))).toList() ?? const [],
        // Absent on products persisted before serial/warranty tracking
        // existed — treated as "not set", same as any other product.
        serialNumber: json['serialNumber'] as String? ?? '',
        warrantyMonths: json['warrantyMonths'] as int? ?? 0,
      );
}

/// Shared "how much is left" / "sell price" display used everywhere a
/// product shows up (POS grid, products list, inventory) so every screen
/// describes bulk/weight/multi-pack items the same, consistent way.
extension MockProductDisplay on MockProduct {
  bool get hasVariants => variants.isNotEmpty;
  int get totalVariantStock => variants.fold(0, (s, v) => s + v.stock);

  // The number always comes first — an Arabic label immediately before a
  // decimal point (e.g. "متوفر: 108.0 كغم") gets its digit groups swapped
  // around the "." by the bidi algorithm, even with forced LTR direction.
  // Leading with the number and following with the (undotted-integer-free)
  // label sidesteps it entirely.
  String get stockSummary => switch (unitMode) {
        ProductUnitMode.each => hasVariants ? 'مخزون: $totalVariantStock عبر ${variants.length} خيار' : 'مخزون: $stock',
        ProductUnitMode.weight => '${openStockKg.toStringAsFixed(1)} كغم متوفرة',
        ProductUnitMode.bulkContainer => '${(openStockKg + stock * containerSizeKg).toStringAsFixed(1)} كغم متوفرة',
        ProductUnitMode.multiPack => '$stock كرتون + $looseUnits فرط',
      };

  String get priceSummary => switch (unitMode) {
        ProductUnitMode.each => '${price.toStringAsFixed(0)} ${currentCurrencySymbol()}',
        ProductUnitMode.weight || ProductUnitMode.bulkContainer => '${pricePerKg.toStringAsFixed(2)} ${currentCurrencySymbol()}/كغم',
        ProductUnitMode.multiPack => '${packPrice.toStringAsFixed(0)}/${piecePrice.toStringAsFixed(2)} ${currentCurrencySymbol()}',
      };

  bool get isLowStock => switch (unitMode) {
        ProductUnitMode.each => hasVariants ? totalVariantStock <= 20 : stock <= 20,
        ProductUnitMode.weight => openStockKg <= 2,
        ProductUnitMode.bulkContainer => (openStockKg + stock * containerSizeKg) <= containerSizeKg,
        ProductUnitMode.multiPack => stock <= 2 && looseUnits <= (packSize / 2),
      };

  bool get isOutOfStock => switch (unitMode) {
        ProductUnitMode.each => hasVariants ? totalVariantStock == 0 : stock == 0,
        ProductUnitMode.weight => openStockKg == 0,
        ProductUnitMode.bulkContainer => openStockKg == 0 && stock == 0,
        ProductUnitMode.multiPack => stock == 0 && looseUnits == 0,
      };

  /// Compact unit-aware quantity for tight spaces (badges/pills) — the
  /// number first, then the unit, e.g. "108 كغم" or "12+14".
  String get shortStockLabel => switch (unitMode) {
        ProductUnitMode.each => hasVariants ? '$totalVariantStock' : '$stock',
        ProductUnitMode.weight => '${openStockKg.toStringAsFixed(1)} كغم',
        ProductUnitMode.bulkContainer => '${(openStockKg + stock * containerSizeKg).toStringAsFixed(1)} كغم',
        ProductUnitMode.multiPack => '$stock+$looseUnits',
      };
}

class MockInvoiceItem {
  const MockInvoiceItem({required this.name, required this.qty, required this.price});
  final String name;
  final int qty;
  final double price;

  Map<String, dynamic> toJson() => {'name': name, 'qty': qty, 'price': price};

  factory MockInvoiceItem.fromJson(Map<String, dynamic> json) =>
      MockInvoiceItem(name: json['name'] as String, qty: json['qty'] as int, price: (json['price'] as num).toDouble());
}

class MockCustomer {
  const MockCustomer({
    this.id = '',
    required this.name,
    required this.phone,
    required this.debt,
    required this.lastPurchase,
    this.notes = '',
    this.loyaltyPoints = 0,
    this.referralCode = '',
    this.referredBy = '',
  });
  final String id;
  final String name;
  final String phone;
  final double debt;
  final String lastPurchase;
  final String notes;
  final int loyaltyPoints;
  final String referralCode;
  final String referredBy;

  MockCustomer copyWith({
    String? name,
    String? phone,
    double? debt,
    String? notes,
    int? loyaltyPoints,
    String? referralCode,
    String? referredBy,
  }) =>
      MockCustomer(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        debt: debt ?? this.debt,
        lastPurchase: lastPurchase,
        notes: notes ?? this.notes,
        loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
        referralCode: referralCode ?? this.referralCode,
        referredBy: referredBy ?? this.referredBy,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'debt': debt,
        'lastPurchase': lastPurchase,
        'notes': notes,
        'loyaltyPoints': loyaltyPoints,
        'referralCode': referralCode,
        'referredBy': referredBy,
      };

  factory MockCustomer.fromJson(Map<String, dynamic> json) => MockCustomer(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        debt: (json['debt'] as num).toDouble(),
        lastPurchase: json['lastPurchase'] as String,
        notes: json['notes'] as String,
        loyaltyPoints: json['loyaltyPoints'] as int,
        referralCode: json['referralCode'] as String,
        referredBy: json['referredBy'] as String,
      );
}

class MockSupplier {
  const MockSupplier({
    this.id = '',
    required this.name,
    required this.phone,
    required this.category,
    this.payable = 0,
    this.lastOrder = 'لا يوجد',
    this.notes = '',
  });

  final String id;
  final String name;
  final String phone;
  final String category;
  final double payable;
  final String lastOrder;
  final String notes;

  MockSupplier copyWith({String? name, String? phone, String? category, double? payable, String? notes}) => MockSupplier(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        category: category ?? this.category,
        payable: payable ?? this.payable,
        lastOrder: lastOrder,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'category': category,
        'payable': payable,
        'lastOrder': lastOrder,
        'notes': notes,
      };

  factory MockSupplier.fromJson(Map<String, dynamic> json) => MockSupplier(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        category: json['category'] as String,
        payable: (json['payable'] as num).toDouble(),
        lastOrder: json['lastOrder'] as String,
        notes: json['notes'] as String,
      );
}

class MockExpense {
  const MockExpense({this.id = '', required this.category, required this.amount, this.note = '', required this.date});
  final String id;
  final String category;
  final double amount;
  final String note;
  final String date;

  Map<String, dynamic> toJson() => {'id': id, 'category': category, 'amount': amount, 'note': note, 'date': date};

  factory MockExpense.fromJson(Map<String, dynamic> json) => MockExpense(
        id: json['id'] as String,
        category: json['category'] as String,
        amount: (json['amount'] as num).toDouble(),
        note: json['note'] as String,
        date: json['date'] as String,
      );
}

const mockExpenseCategories = ['إيجار', 'رواتب', 'فواتير', 'صيانة', 'تسويق', 'نقل وشحن', 'أخرى'];

class MockPermissions {
  const MockPermissions({
    this.applyDiscount = true,
    this.processRefund = false,
    this.viewReports = false,
    this.manageSettings = false,
    this.manageEmployees = false,
  });

  final bool applyDiscount;
  final bool processRefund;
  final bool viewReports;
  final bool manageSettings;
  final bool manageEmployees;

  MockPermissions copyWith({bool? applyDiscount, bool? processRefund, bool? viewReports, bool? manageSettings, bool? manageEmployees}) => MockPermissions(
        applyDiscount: applyDiscount ?? this.applyDiscount,
        processRefund: processRefund ?? this.processRefund,
        viewReports: viewReports ?? this.viewReports,
        manageSettings: manageSettings ?? this.manageSettings,
        manageEmployees: manageEmployees ?? this.manageEmployees,
      );

  Map<String, dynamic> toJson() => {
        'applyDiscount': applyDiscount,
        'processRefund': processRefund,
        'viewReports': viewReports,
        'manageSettings': manageSettings,
        'manageEmployees': manageEmployees,
      };

  factory MockPermissions.fromJson(Map<String, dynamic> json) => MockPermissions(
        applyDiscount: json['applyDiscount'] as bool,
        processRefund: json['processRefund'] as bool,
        viewReports: json['viewReports'] as bool,
        manageSettings: json['manageSettings'] as bool,
        manageEmployees: json['manageEmployees'] as bool,
      );
}

class MockEmployee {
  const MockEmployee({
    this.id = '',
    required this.name,
    required this.phone,
    required this.role,
    this.branch = 'الفرع الرئيسي',
    this.active = true,
    this.permissions = const MockPermissions(),
    this.photoBytes,
    this.password = '',
  });

  final String id;
  final String name;
  final String phone;
  final String role;
  final String branch;
  final bool active;
  final MockPermissions permissions;
  /// Set by the store owner when creating the employee's account — shown on
  /// the employee-login identity check and on audit-log entries for actions
  /// that employee takes.
  final Uint8List? photoBytes;
  /// Generated by the store owner when creating the account and shared with
  /// the employee directly (WhatsApp/SMS) — the employee never signs
  /// themselves up.
  final String password;

  MockEmployee copyWith({
    String? name,
    String? phone,
    String? role,
    String? branch,
    bool? active,
    MockPermissions? permissions,
    Uint8List? photoBytes,
    bool clearPhoto = false,
    String? password,
  }) =>
      MockEmployee(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        branch: branch ?? this.branch,
        active: active ?? this.active,
        permissions: permissions ?? this.permissions,
        photoBytes: clearPhoto ? null : (photoBytes ?? this.photoBytes),
        password: password ?? this.password,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role,
        'branch': branch,
        'active': active,
        'permissions': permissions.toJson(),
        'photoBytes': photoBytes,
        'password': password,
      };

  factory MockEmployee.fromJson(Map<String, dynamic> json) => MockEmployee(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        role: json['role'] as String,
        branch: json['branch'] as String,
        active: json['active'] as bool,
        permissions: MockPermissions.fromJson(Map<String, dynamic>.from(json['permissions'] as Map)),
        photoBytes: asBytes(json['photoBytes']),
        password: json['password'] as String,
      );
}

const mockEmployeeRoles = ['مالك', 'مدير فرع', 'مشرف', 'كاشير'];

class MockBranch {
  const MockBranch({
    this.id = '',
    required this.name,
    this.address = '',
    this.phone = '',
    this.managerName = '',
    this.active = true,
    this.isMain = false,
    this.isWarehouse = false,
  });

  final String id;
  final String name;
  final String address;
  final String phone;
  final String managerName;
  final bool active;
  final bool isMain;
  final bool isWarehouse;

  MockBranch copyWith({String? name, String? address, String? phone, String? managerName, bool? active, bool? isWarehouse}) => MockBranch(
        id: id,
        name: name ?? this.name,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        managerName: managerName ?? this.managerName,
        active: active ?? this.active,
        isMain: isMain,
        isWarehouse: isWarehouse ?? this.isWarehouse,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'managerName': managerName,
        'active': active,
        'isMain': isMain,
        'isWarehouse': isWarehouse,
      };

  factory MockBranch.fromJson(Map<String, dynamic> json) => MockBranch(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        phone: json['phone'] as String,
        managerName: json['managerName'] as String,
        active: json['active'] as bool,
        isMain: json['isMain'] as bool,
        isWarehouse: json['isWarehouse'] as bool,
      );
}

/// Comprehensive supermarket/grocery section taxonomy — covers every common
/// department so a real بقالة/سوبرماركت never needs an "أخرى" catch-all
/// for a normal product.
const mockPosCategories = [
  'الكل',
  'مشروبات',
  'مخبوزات',
  'وجبات خفيفة',
  'بقالة',
  'أرز ومعكرونة وحبوب',
  'زيوت وسمن',
  'توابل وبهارات',
  'ألبان وأجبان وبيض',
  'لحوم ودواجن',
  'أسماك ومأكولات بحرية',
  'خضروات وفواكه',
  'مجمدات',
  'معلبات',
  'حلويات وشوكولاتة',
  'آيسكريم ومثلجات',
  'عصائر طازجة',
  'منظفات ومستلزمات المنزل',
  'العناية الشخصية',
  'منتجات الأطفال',
  'أدوات منزلية',
  'قرطاسية',
  'حيوانات أليفة',
  'سجائر ودخان',
  'أخرى',
];

/// Starter category taxonomy for a ملابس (clothing) store — a grocery
/// section list like "لحوم ودواجن" is meaningless here, so this is its own
/// set rather than reusing [mockPosCategories].
const mockClothingCategories = [
  'الكل',
  'رجالي',
  'حريمي',
  'أطفال',
  'أحذية',
  'حقائب وإكسسوارات',
  'ملابس داخلية',
  'ملابس رياضية',
  'ملابس شتوية',
  'ملابس صيفية',
  'أخرى',
];

/// Starter category taxonomy for an إلكترونيات (electronics) store.
const mockElectronicsCategories = [
  'الكل',
  'موبايلات',
  'أجهزة كمبيوتر ولابتوب',
  'أجهزة منزلية',
  'شاشات وتلفزيونات',
  'سماعات وصوتيات',
  'إكسسوارات إلكترونية',
  'ألعاب فيديو',
  'كاميرات',
  'قطع غيار وصيانة',
  'أخرى',
];

/// Starter category taxonomy for a general retail store selling a mix of
/// goods that doesn't fit grocery, clothing, or electronics specifically.
const mockGeneralRetailCategories = [
  'الكل',
  'مواد غذائية',
  'مستلزمات منزلية',
  'العناية الشخصية',
  'ملابس وإكسسوارات',
  'إلكترونيات صغيرة',
  'قرطاسية',
  'ألعاب وهدايا',
  'أخرى',
];

class MockActivityEntry {
  const MockActivityEntry({
    this.id = '',
    required this.action,
    required this.employeeName,
    required this.category,
    required this.time,
    required this.date,
    required this.timestamp,
    this.sensitive = false,
    this.employeePhoto,
    this.branch = '',
    this.device = '',
    this.ipStatus = '',
    this.reason = '',
    this.beforeSnapshot,
    this.afterSnapshot,
  });

  final String id;
  final String action;
  final String employeeName;
  final String category;
  final String time;
  final String date;
  /// The real moment this happened — drives any date-based filtering (e.g.
  /// picking an arbitrary day in the Day Summary report). [date]/[time]
  /// stay as friendly display strings so existing rows don't change look.
  final DateTime timestamp;
  final bool sensitive;
  /// Set by the store owner when creating the employee's account — carried
  /// through to every log entry that employee produces.
  final Uint8List? employeePhoto;
  final String branch;
  final String device;
  final String ipStatus;
  /// Mandatory for sensitive delete/edit actions — captured before the
  /// action is allowed to proceed, never backfilled after the fact.
  final String reason;
  /// Plain-text snapshots of the record before/after an edit (e.g. an
  /// invoice's details), so a reviewer can see exactly what changed.
  final String? beforeSnapshot;
  final String? afterSnapshot;

  Map<String, dynamic> toJson() => {
        'id': id,
        'action': action,
        'employeeName': employeeName,
        'category': category,
        'time': time,
        'date': date,
        'timestamp': timestamp,
        'sensitive': sensitive,
        'employeePhoto': employeePhoto,
        'branch': branch,
        'device': device,
        'ipStatus': ipStatus,
        'reason': reason,
        'beforeSnapshot': beforeSnapshot,
        'afterSnapshot': afterSnapshot,
      };

  factory MockActivityEntry.fromJson(Map<String, dynamic> json) => MockActivityEntry(
        id: json['id'] as String,
        action: json['action'] as String,
        employeeName: json['employeeName'] as String,
        category: json['category'] as String,
        time: json['time'] as String,
        date: json['date'] as String,
        timestamp: asDateTime(json['timestamp']) ?? DateTime.now(),
        sensitive: json['sensitive'] as bool,
        employeePhoto: asBytes(json['employeePhoto']),
        branch: json['branch'] as String,
        device: json['device'] as String,
        ipStatus: json['ipStatus'] as String,
        reason: json['reason'] as String,
        beforeSnapshot: json['beforeSnapshot'] as String?,
        afterSnapshot: json['afterSnapshot'] as String?,
      );
}

const mockActivityCategories = ['مبيعات', 'مخزون', 'موظفون', 'إعدادات', 'صلاحيات', 'حذف'];

class MockTaxRate {
  const MockTaxRate({this.id = '', required this.name, required this.percentage, this.isDefault = false, this.active = true});
  final String id;
  final String name;
  final double percentage;
  final bool isDefault;
  final bool active;

  MockTaxRate copyWith({String? name, double? percentage, bool? active}) =>
      MockTaxRate(id: id, name: name ?? this.name, percentage: percentage ?? this.percentage, isDefault: isDefault, active: active ?? this.active);

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'percentage': percentage, 'isDefault': isDefault, 'active': active};

  factory MockTaxRate.fromJson(Map<String, dynamic> json) => MockTaxRate(
        id: json['id'] as String,
        name: json['name'] as String,
        percentage: (json['percentage'] as num).toDouble(),
        isDefault: json['isDefault'] as bool,
        active: json['active'] as bool,
      );
}

class MockOffer {
  const MockOffer({
    this.id = '',
    required this.title,
    required this.discountPercent,
    this.scope = 'الكل',
    this.active = true,
    this.startDate = '',
    this.endDate = '',
  });

  final String id;
  final String title;
  final double discountPercent;
  final String scope;
  final bool active;
  final String startDate;
  final String endDate;

  MockOffer copyWith({String? title, double? discountPercent, String? scope, bool? active, String? startDate, String? endDate}) => MockOffer(
        id: id,
        title: title ?? this.title,
        discountPercent: discountPercent ?? this.discountPercent,
        scope: scope ?? this.scope,
        active: active ?? this.active,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'discountPercent': discountPercent,
        'scope': scope,
        'active': active,
        'startDate': startDate,
        'endDate': endDate,
      };

  factory MockOffer.fromJson(Map<String, dynamic> json) => MockOffer(
        id: json['id'] as String,
        title: json['title'] as String,
        discountPercent: (json['discountPercent'] as num).toDouble(),
        scope: json['scope'] as String,
        active: json['active'] as bool,
        startDate: json['startDate'] as String,
        endDate: json['endDate'] as String,
      );
}

class MockCoupon {
  const MockCoupon({
    this.id = '',
    required this.code,
    required this.discountPercent,
    this.usageLimit = 0,
    this.usedCount = 0,
    this.active = true,
    this.expiry = '',
  });

  final String id;
  final String code;
  final double discountPercent;
  final int usageLimit;
  final int usedCount;
  final bool active;
  final String expiry;

  MockCoupon copyWith({String? code, double? discountPercent, int? usageLimit, bool? active, String? expiry}) => MockCoupon(
        id: id,
        code: code ?? this.code,
        discountPercent: discountPercent ?? this.discountPercent,
        usageLimit: usageLimit ?? this.usageLimit,
        usedCount: usedCount,
        active: active ?? this.active,
        expiry: expiry ?? this.expiry,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'discountPercent': discountPercent,
        'usageLimit': usageLimit,
        'usedCount': usedCount,
        'active': active,
        'expiry': expiry,
      };

  factory MockCoupon.fromJson(Map<String, dynamic> json) => MockCoupon(
        id: json['id'] as String,
        code: json['code'] as String,
        discountPercent: (json['discountPercent'] as num).toDouble(),
        usageLimit: json['usageLimit'] as int,
        usedCount: json['usedCount'] as int,
        active: json['active'] as bool,
        expiry: json['expiry'] as String,
      );
}


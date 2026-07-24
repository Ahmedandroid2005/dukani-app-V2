import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/business/business_capabilities.dart';
import '../../core/business/business_type_controller.dart';
import '../../core/media/product_photo_picker.dart';
import '../../core/products/categories_controller.dart';
import '../../core/products/products_controller.dart';
import '../../core/scanning/barcode_scanner_sheet.dart';
import '../../core/subscription/plan_limits.dart';
import '../../core/subscription/subscription_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'manage_categories_sheet.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Assigned automatically by category as a fallback avatar for products with
/// no attached photo — never shown as a manual picker (photos are the norm
/// now, this only keeps old/undocumented products from looking blank).
IconData _fallbackIcon(String category) {
  const byCategory = <String, IconData>{
    'مشروبات': LucideIcons.coffee, 'مخبوزات': LucideIcons.croissant,
    'وجبات خفيفة': LucideIcons.sandwich, 'بقالة': LucideIcons.shoppingBasket,
    'أرز ومعكرونة وحبوب': LucideIcons.wheat, 'زيوت وسمن': LucideIcons.droplet,
    'توابل وبهارات': LucideIcons.wheat, 'ألبان وأجبان وبيض': LucideIcons.egg,
    'لحوم ودواجن': LucideIcons.beef, 'أسماك ومأكولات بحرية': LucideIcons.fish,
    'خضروات وفواكه': LucideIcons.leaf, 'مجمدات': LucideIcons.snowflake,
    'معلبات': LucideIcons.package, 'حلويات وشوكولاتة': LucideIcons.cookie,
    'آيسكريم ومثلجات': LucideIcons.iceCreamCone, 'عصائر طازجة': LucideIcons.cupSoda,
    'منظفات ومستلزمات المنزل': LucideIcons.sprayCan,
    'العناية الشخصية': LucideIcons.flower2, 'منتجات الأطفال': LucideIcons.baby,
    'أدوات منزلية': LucideIcons.refrigerator, 'قرطاسية': LucideIcons.pencil,
    'حيوانات أليفة': LucideIcons.pawPrint, 'سجائر ودخان': LucideIcons.cigarette,
  };
  return byCategory[category] ?? LucideIcons.package;
}

const _unitModeLabels = <ProductUnitMode, String>{
  ProductUnitMode.each: 'قطعة',
  ProductUnitMode.weight: 'وزن (بدون عبوة)',
  ProductUnitMode.bulkContainer: 'شكارة بالوزن',
  ProductUnitMode.multiPack: 'كرتون وفرط',
};

/// One in-progress variant row in the form — mutable, unlike
/// [MockProductVariant], so its text fields can be edited freely and only
/// turned into real variants (or dropped, if left blank) on save.
class _VariantDraft {
  _VariantDraft({required this.id, String size = '', String color = '', int stock = 0})
      : sizeController = TextEditingController(text: size),
        colorController = TextEditingController(text: color),
        stockController = TextEditingController(text: stock.toString());

  factory _VariantDraft.fromVariant(MockProductVariant v) => _VariantDraft(id: v.id, size: v.size, color: v.color, stock: v.stock);

  final String id;
  final TextEditingController sizeController;
  final TextEditingController colorController;
  final TextEditingController stockController;

  void dispose() {
    sizeController.dispose();
    colorController.dispose();
    stockController.dispose();
  }
}

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});
  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  late final _nameController = TextEditingController(text: _editing?.name ?? '');
  late final _priceController = TextEditingController(text: _editing != null ? _editing!.price.toStringAsFixed(2) : '');
  late final _costController = TextEditingController(text: _editing != null && _editing!.cost > 0 ? _editing!.cost.toStringAsFixed(2) : '');
  late final _stockController = TextEditingController(text: _editing != null ? _editing!.stock.toString() : '');
  late final _barcodeController = TextEditingController(text: _editing?.barcode ?? '');

  late final _pricePerKgController = TextEditingController(text: _editing != null && _editing!.pricePerKg > 0 ? _editing!.pricePerKg.toStringAsFixed(2) : '');
  late final _containerSizeController = TextEditingController(text: _editing != null && _editing!.containerSizeKg > 0 ? _editing!.containerSizeKg.toStringAsFixed(1) : '');
  late final _openStockKgController = TextEditingController(text: _editing != null ? _editing!.openStockKg.toStringAsFixed(2) : '0');
  late final _packSizeController = TextEditingController(text: _editing != null && _editing!.packSize > 0 ? _editing!.packSize.toString() : '');
  late final _packPriceController = TextEditingController(text: _editing != null && _editing!.packPrice > 0 ? _editing!.packPrice.toStringAsFixed(2) : '');
  late final _piecePriceController = TextEditingController(text: _editing != null && _editing!.piecePrice > 0 ? _editing!.piecePrice.toStringAsFixed(2) : '');
  late final _looseUnitsController = TextEditingController(text: _editing != null ? _editing!.looseUnits.toString() : '0');
  late final _serialController = TextEditingController(text: _editing?.serialNumber ?? '');
  late final _warrantyController = TextEditingController(text: _editing != null && _editing!.warrantyMonths > 0 ? _editing!.warrantyMonths.toString() : '');

  late String _category = _editing?.category ?? ref.read(categoriesProvider).first;
  late Uint8List? _photoBytes = _editing?.photoBytes;
  late ProductUnitMode _unitMode = _availableUnitModes.contains(_editing?.unitMode) ? _editing!.unitMode : ProductUnitMode.each;
  late DateTime? _expiryDate = _editing?.expiryDate;
  late bool _hasVariants = _editing?.hasVariants ?? ref.read(businessTypeProvider).variantsEmphasized;
  late final List<_VariantDraft> _variantDrafts = _editing != null
      ? [for (final v in _editing!.variants) _VariantDraft.fromVariant(v)]
      : (_hasVariants ? [_VariantDraft(id: DateTime.now().microsecondsSinceEpoch.toString())] : []);

  MockProduct? get _editing => widget.productId == null ? null : ref.read(productsProvider.notifier).byId(widget.productId!);
  bool get _isEditing => widget.productId != null;

  /// Sale modes worth offering for this merchant's activity — a restaurant
  /// or clothing shop never needs "sold by the carton" cluttering a menu
  /// item or a t-shirt's form.
  List<ProductUnitMode> get _availableUnitModes => ref.read(businessTypeProvider).availableUnitModes;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    _pricePerKgController.dispose();
    _containerSizeController.dispose();
    _openStockKgController.dispose();
    _packSizeController.dispose();
    _packPriceController.dispose();
    _piecePriceController.dispose();
    _looseUnitsController.dispose();
    _serialController.dispose();
    _warrantyController.dispose();
    for (final v in _variantDrafts) {
      v.dispose();
    }
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final cost = double.tryParse(_costController.text.trim()) ?? 0;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل اسم المنتج')));
      return;
    }

    if (!_isEditing) {
      final limits = planLimitsFor(ref.read(currentPlanProvider).valueOrNull);
      final maxProducts = limits.maxProducts;
      if (maxProducts != null && ref.read(productsProvider).length >= maxProducts) {
        showUpgradeRequiredDialog(context, 'باقتك الحالية تسمح بحتى $maxProducts منتج. قم بالترقية لإضافة المزيد.');
        return;
      }
    }

    double price;
    int stock = 0;
    final pricePerKg = double.tryParse(_pricePerKgController.text.trim()) ?? 0;
    final containerSizeKg = double.tryParse(_containerSizeController.text.trim()) ?? 0;
    final openStockKg = double.tryParse(_openStockKgController.text.trim()) ?? 0;
    final packSize = int.tryParse(_packSizeController.text.trim()) ?? 0;
    final packPrice = double.tryParse(_packPriceController.text.trim()) ?? 0;
    final piecePrice = double.tryParse(_piecePriceController.text.trim()) ?? 0;
    final looseUnits = int.tryParse(_looseUnitsController.text.trim()) ?? 0;

    switch (_unitMode) {
      case ProductUnitMode.each:
        final entered = double.tryParse(_priceController.text.trim());
        if (entered == null || entered <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل سعرًا صحيحًا')));
          return;
        }
        price = entered;
        stock = _hasVariants ? 0 : (int.tryParse(_stockController.text.trim()) ?? 0);
      case ProductUnitMode.weight:
        if (pricePerKg <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل سعر الكيلوجرام')));
          return;
        }
        price = pricePerKg;
      case ProductUnitMode.bulkContainer:
        if (pricePerKg <= 0 || containerSizeKg <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل سعر الكيلوجرام وحجم الشكارة')));
          return;
        }
        price = pricePerKg * containerSizeKg;
        stock = int.tryParse(_stockController.text.trim()) ?? 0;
      case ProductUnitMode.multiPack:
        if (packSize <= 0 || packPrice <= 0 || piecePrice <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل عدد القطع بالكرتون وسعري الكرتون والقطعة')));
          return;
        }
        price = packPrice;
        stock = int.tryParse(_stockController.text.trim()) ?? 0;
    }

    var variants = const <MockProductVariant>[];
    if (_unitMode == ProductUnitMode.each && _hasVariants) {
      variants = [
        for (final d in _variantDrafts)
          if (d.sizeController.text.trim().isNotEmpty || d.colorController.text.trim().isNotEmpty)
            MockProductVariant(
              id: d.id,
              size: d.sizeController.text.trim(),
              color: d.colorController.text.trim(),
              stock: int.tryParse(d.stockController.text.trim()) ?? 0,
            ),
      ];
      if (variants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف مقاسًا أو لونًا واحدًا على الأقل')));
        return;
      }
    }

    final product = MockProduct(
      id: _editing?.id ?? ref.read(productsProvider.notifier).nextId(),
      name: name,
      category: _category,
      price: price,
      cost: cost,
      stock: stock,
      icon: _editing?.icon ?? _fallbackIcon(_category),
      photoBytes: _photoBytes,
      barcode: _barcodeController.text.trim(),
      soldQty: _editing?.soldQty ?? 0,
      revenue: _editing?.revenue ?? 0,
      unitMode: _unitMode,
      pricePerKg: pricePerKg,
      openStockKg: openStockKg,
      containerSizeKg: containerSizeKg,
      packSize: packSize,
      packPrice: packPrice,
      piecePrice: piecePrice,
      looseUnits: looseUnits,
      expiryDate: _expiryDate,
      variants: variants,
      serialNumber: _serialController.text.trim(),
      warrantyMonths: int.tryParse(_warrantyController.text.trim()) ?? 0,
    );

    if (_isEditing) {
      ref.read(productsProvider.notifier).update(product.id, product);
    } else {
      ref.read(productsProvider.notifier).add(product);
    }
    context.pop();
  }

  Future<void> _delete() async {
    final ok = await DukaniConfirmDialog.show(
      context,
      title: 'حذف المنتج؟',
      message: 'سيتم حذف "${_editing!.name}" نهائيًا من الكتالوج.',
      confirmLabel: 'حذف',
      destructive: true,
      icon: LucideIcons.trash2,
    );
    if (!ok) return;
    if (!mounted) return;
    final logged = await logSensitiveAction(
      context,
      ref,
      action: 'حذف المنتج "${_editing!.name}"',
      category: 'حذف',
    );
    if (!logged) return;
    ref.read(productsProvider.notifier).remove(_editing!.id);
    if (mounted) context.pop();
  }

  /// The full "إدارة الفئات" sheet is for bulk cleanup — deleting old
  /// categories, curating the list. Needing a brand-new one *right now*
  /// while adding this product is a different, more common moment: add it
  /// and select it in one step, no detour through a separate screen and
  /// back.
  Future<void> _quickAddCategory(WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('فئة جديدة'),
        content: DukaniTextField(hint: 'مثال: مستلزمات المكتب', controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    ref.read(categoriesProvider.notifier).add(name);
    setState(() => _category = name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DukaniAppBar(
        title: _isEditing ? 'تعديل المنتج' : 'منتج جديد',
        actions: [
          if (_isEditing) DukaniIconAction(icon: LucideIcons.trash2, onTap: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          Center(
            child: GestureDetector(
              onTap: () async {
                final bytes = await pickPhoto(context, title: 'صورة المنتج');
                if (bytes != null) setState(() => _photoBytes = bytes);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  DukaniProductImage(
                    icon: _editing?.icon ?? _fallbackIcon(_category),
                    photoBytes: _photoBytes,
                    size: 96,
                    radius: DukaniRadii.md,
                  ),
                  Positioned(
                    bottom: -4,
                    left: -4,
                    child: Material(
                      color: DukaniColors.forest700,
                      shape: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(_photoBytes == null ? LucideIcons.camera : LucideIcons.pencil, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DukaniSpacing.sm),
          Center(
            child: Text(
              _photoBytes == null ? 'أضف صورة حقيقية للمنتج' : 'اضغط لتغيير الصورة',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: DukaniColors.ink500),
            ),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniTextField(label: 'اسم المنتج', hint: 'مثال: قهوة تركية', controller: _nameController, autofocus: !_isEditing),
          const SizedBox(height: DukaniSpacing.lg),
          Row(
            children: [
              Text('الفئة', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              GestureDetector(
                onTap: () => showManageCategoriesSheet(context, ref),
                child: Row(
                  children: [
                    const Icon(LucideIcons.slidersHorizontal, size: 14, color: DukaniColors.forest600),
                    const SizedBox(width: 4),
                    Text('إدارة الفئات', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.forest600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: DukaniSpacing.sm),
          Consumer(
            builder: (context, ref, _) {
              final categories = ref.watch(categoriesProvider);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in categories) DukaniChoiceChip(label: c, selected: c == _category, onTap: () => setState(() => _category = c)),
                  DukaniChoiceChip(label: 'فئة جديدة', icon: LucideIcons.plus, selected: false, onTap: () => _quickAddCategory(ref)),
                ],
              );
            },
          ),
          // Only worth asking when this activity actually has more than one
          // real option — a single-mode chip row is a choice with nothing
          // to choose, which is its own kind of clutter.
          if (_availableUnitModes.length > 1) ...[
            const SizedBox(height: DukaniSpacing.lg),
            Text('طريقة البيع', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: DukaniSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mode in _availableUnitModes)
                  DukaniChoiceChip(label: _unitModeLabels[mode]!, selected: _unitMode == mode, onTap: () => setState(() => _unitMode = mode)),
              ],
            ),
          ],
          const SizedBox(height: DukaniSpacing.lg),
          ..._pricingFields(),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(
            label: 'الباركود (اختياري)',
            hint: '629...',
            controller: _barcodeController,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            suffix: IconButton(
              icon: const Icon(LucideIcons.camera, size: 20),
              tooltip: 'مسح الباركود بالكاميرا',
              onPressed: () async {
                final code = await showBarcodeScannerScreen(context);
                if (code != null) setState(() => _barcodeController.text = code);
              },
            ),
          ),
          if (ref.watch(businessTypeProvider).tracksSerialWarranty) ...[
            const SizedBox(height: DukaniSpacing.lg),
            Text('الرقم التسلسلي / IMEI (اختياري)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: DukaniSpacing.sm),
            DukaniTextField(hint: 'مثال: 358240051111110', controller: _serialController, textDirection: TextDirection.ltr),
            const SizedBox(height: DukaniSpacing.lg),
            Text('مدة الضمان بالشهور (اختياري)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: DukaniSpacing.sm),
            DukaniTextField(hint: 'مثال: 12', controller: _warrantyController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr),
          ],
          const SizedBox(height: DukaniSpacing.lg),
          Text('تاريخ الصلاحية (اختياري)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: DukaniSpacing.sm),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (picked != null) setState(() => _expiryDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(color: DukaniColors.forest50, borderRadius: BorderRadius.circular(DukaniRadii.md)),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 18, color: DukaniColors.ink500),
                  const SizedBox(width: DukaniSpacing.sm),
                  Expanded(
                    child: Text(
                      _expiryDate == null ? 'بلا تاريخ انتهاء' : '${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (_expiryDate != null)
                    IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => setState(() => _expiryDate = null)),
                ],
              ),
            ),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(label: _isEditing ? 'حفظ التعديلات' : 'إضافة المنتج', icon: LucideIcons.checkCircle2, onPressed: _save),
        ],
      ),
    );
  }

  List<Widget> _pricingFields() {
    switch (_unitMode) {
      case ProductUnitMode.each:
        return [
          Row(
            children: [
              Expanded(child: DukaniTextField(label: 'سعر البيع', hint: '0.00', controller: _priceController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
              const SizedBox(width: DukaniSpacing.md),
              Expanded(child: DukaniTextField(label: 'سعر التكلفة (اختياري)', hint: '0.00', controller: _costController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
            ],
          ),
          const SizedBox(height: DukaniSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text('له مقاسات أو ألوان مختلفة؟', style: Theme.of(context).textTheme.titleSmall),
              ),
              Switch(
                value: _hasVariants,
                onChanged: (v) => setState(() {
                  _hasVariants = v;
                  if (v && _variantDrafts.isEmpty) _variantDrafts.add(_VariantDraft(id: DateTime.now().microsecondsSinceEpoch.toString()));
                }),
                activeColor: DukaniColors.forest700,
              ),
            ],
          ),
          if (_hasVariants) ...[
            Text(
              'كل مقاس/لون له مخزونه الخاص — بيع آخر قطعة L أزرق ما يمسّش مخزون M أحمر',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500),
            ),
            const SizedBox(height: DukaniSpacing.md),
            for (final draft in _variantDrafts) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: DukaniTextField(hint: 'المقاس (مثال: L)', controller: draft.sizeController)),
                  const SizedBox(width: DukaniSpacing.sm),
                  Expanded(child: DukaniTextField(hint: 'اللون (مثال: أزرق)', controller: draft.colorController)),
                  const SizedBox(width: DukaniSpacing.sm),
                  SizedBox(
                    width: 80,
                    child: DukaniTextField(hint: 'المخزون', controller: draft.stockController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 18, color: DukaniColors.ink500),
                    onPressed: () => setState(() {
                      draft.dispose();
                      _variantDrafts.remove(draft);
                    }),
                  ),
                ],
              ),
              const SizedBox(height: DukaniSpacing.sm),
            ],
            DukaniOutlineButton(
              label: 'إضافة مقاس / لون',
              icon: LucideIcons.plus,
              onPressed: () => setState(() => _variantDrafts.add(_VariantDraft(id: DateTime.now().microsecondsSinceEpoch.toString()))),
            ),
          ] else
            DukaniTextField(label: 'الكمية بالمخزون', hint: '0', controller: _stockController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr),
        ];
      case ProductUnitMode.weight:
        return [
          Text('يُباع بالوزن مباشرة — بدون عبوة أو شكارة (حلاوة، جبنة، لانشون، بهارات...)', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
          const SizedBox(height: DukaniSpacing.sm),
          Row(
            children: [
              Expanded(child: DukaniTextField(label: 'سعر الكيلوجرام', hint: '0.00', controller: _pricePerKgController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
              const SizedBox(width: DukaniSpacing.md),
              Expanded(child: DukaniTextField(label: 'الكمية المتوفرة (كغم)', hint: '0.00', controller: _openStockKgController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
            ],
          ),
        ];
      case ProductUnitMode.bulkContainer:
        return [
          Text('يُباع بالوزن من شكارة — عند نفاد الشكارة المفتوحة تُفتح واحدة جديدة تلقائيًا (رز، دقيق، عدس...)', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
          const SizedBox(height: DukaniSpacing.sm),
          Row(
            children: [
              Expanded(child: DukaniTextField(label: 'سعر الكيلوجرام', hint: '0.00', controller: _pricePerKgController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
              const SizedBox(width: DukaniSpacing.md),
              Expanded(child: DukaniTextField(label: 'حجم الشكارة (كغم)', hint: '25', controller: _containerSizeController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
            ],
          ),
          const SizedBox(height: DukaniSpacing.lg),
          Row(
            children: [
              Expanded(child: DukaniTextField(label: 'عدد الشكائر المغلقة', hint: '0', controller: _stockController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
              const SizedBox(width: DukaniSpacing.md),
              Expanded(child: DukaniTextField(label: 'المفتوح حاليًا (كغم)', hint: '0.00', controller: _openStockKgController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
            ],
          ),
        ];
      case ProductUnitMode.multiPack:
        return [
          Text('يُباع كرتون/علبة كاملة أو بالفرط في نفس الوقت — كسر كرتون للفرط يتم تلقائيًا عند الحاجة (بيض، سجائر...)', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
          const SizedBox(height: DukaniSpacing.sm),
          DukaniTextField(label: 'عدد القطع بالكرتون الواحد', hint: '30', controller: _packSizeController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr),
          const SizedBox(height: DukaniSpacing.lg),
          Row(
            children: [
              Expanded(child: DukaniTextField(label: 'سعر الكرتون الكامل', hint: '0.00', controller: _packPriceController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
              const SizedBox(width: DukaniSpacing.md),
              Expanded(child: DukaniTextField(label: 'سعر القطعة بالفرط', hint: '0.00', controller: _piecePriceController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
            ],
          ),
          const SizedBox(height: DukaniSpacing.lg),
          Row(
            children: [
              Expanded(child: DukaniTextField(label: 'عدد الكراتين المغلقة', hint: '0', controller: _stockController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
              const SizedBox(width: DukaniSpacing.md),
              Expanded(child: DukaniTextField(label: 'عدد القطع بالفرط', hint: '0', controller: _looseUnitsController, keyboardType: TextInputType.number, textDirection: TextDirection.ltr)),
            ],
          ),
        ];
    }
  }
}

import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/customers/customers_controller.dart';
import '../../core/products/products_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum _ImportKind { products, customers }

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  _ImportKind _kind = _ImportKind.products;
  String? _fileName;
  List<List<dynamic>>? _rows;
  String? _error;
  bool _picking = false;

  List<String> get _expectedColumns => _kind == _ImportKind.products ? const ['name', 'category', 'price', 'stock'] : const ['name', 'phone', 'debt'];

  Future<void> _pickFile() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
      if (result == null || result.files.isEmpty) {
        setState(() => _picking = false);
        return;
      }
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _picking = false;
          _error = 'تعذّرت قراءة الملف';
        });
        return;
      }
      final content = utf8.decode(bytes);
      final rows = const CsvToListConverter(eol: '\n').convert(content);
      setState(() {
        _fileName = file.name;
        _rows = rows;
        _picking = false;
      });
    } catch (e) {
      setState(() {
        _picking = false;
        _error = 'ملف غير صالح — تأكد أنه بصيغة CSV بالأعمدة: ${_expectedColumns.join(', ')}';
      });
    }
  }

  List<List<dynamic>> get _dataRows => _rows == null || _rows!.isEmpty ? const [] : _rows!.skip(1).toList();

  void _import() {
    var imported = 0;
    var skipped = 0;
    if (_kind == _ImportKind.products) {
      final ctrl = ref.read(productsProvider.notifier);
      for (final row in _dataRows) {
        if (row.length < 4) {
          skipped++;
          continue;
        }
        final name = row[0].toString().trim();
        final category = row[1].toString().trim();
        final price = double.tryParse(row[2].toString().trim());
        final stock = int.tryParse(row[3].toString().trim());
        if (name.isEmpty || price == null || stock == null) {
          skipped++;
          continue;
        }
        ctrl.add(MockProduct(id: ctrl.nextId(), name: name, category: category.isEmpty ? 'أخرى' : category, price: price, stock: stock, icon: LucideIcons.package));
        imported++;
      }
    } else {
      final ctrl = ref.read(customersProvider.notifier);
      for (final row in _dataRows) {
        if (row.length < 2) {
          skipped++;
          continue;
        }
        final name = row[0].toString().trim();
        final phone = row[1].toString().trim();
        final debt = row.length > 2 ? double.tryParse(row[2].toString().trim()) ?? 0 : 0.0;
        if (name.isEmpty) {
          skipped++;
          continue;
        }
        ctrl.add(MockCustomer(id: ctrl.nextId(), name: name, phone: phone, debt: debt, lastPurchase: 'لا يوجد'));
        imported++;
      }
    }

    showDukaniSheet(
      context,
      title: 'اكتمل الاستيراد',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(LucideIcons.checkCircle2, size: 48, color: DukaniColors.success),
          const SizedBox(height: DukaniSpacing.md),
          Text('تم استيراد $imported سجل بنجاح', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          if (skipped > 0) ...[
            const SizedBox(height: 4),
            Text('تم تجاهل $skipped صف بسبب بيانات ناقصة أو غير صحيحة', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.danger), textAlign: TextAlign.center),
          ],
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(
            label: 'تم',
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _rows = null;
                _fileName = null;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const DukaniAppBar(title: 'استيراد البيانات'),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          Text('ماذا تريد أن تستورد؟', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: DukaniSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DukaniChoiceChip(
                  label: 'منتجات',
                  selected: _kind == _ImportKind.products,
                  onTap: () => setState(() {
                    _kind = _ImportKind.products;
                    _rows = null;
                    _fileName = null;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DukaniChoiceChip(
                  label: 'عملاء',
                  selected: _kind == _ImportKind.customers,
                  onTap: () => setState(() {
                    _kind = _ImportKind.customers;
                    _rows = null;
                    _fileName = null;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.info, size: 18, color: DukaniColors.info),
                    const SizedBox(width: 8),
                    Expanded(child: Text('أعمدة الملف المطلوبة (بهذا الترتيب):', style: Theme.of(context).textTheme.bodySmall)),
                  ],
                ),
                const SizedBox(height: 6),
                DukaniAmountText(_expectedColumns.join(', '), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.forest700, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(label: 'اختيار ملف CSV', icon: LucideIcons.fileUp, loading: _picking, onPressed: _pickFile),
          if (_error != null) ...[
            const SizedBox(height: DukaniSpacing.md),
            DukaniCard(color: DukaniColors.dangerBg, child: Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.danger))),
          ],
          if (_fileName != null) ...[
            const SizedBox(height: DukaniSpacing.xl),
            Text('معاينة: $_fileName (${_dataRows.length} صف)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: DukaniSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [for (final c in _expectedColumns) DataColumn(label: Text(c))],
                rows: [
                  for (final row in _dataRows.take(10))
                    DataRow(cells: [for (var i = 0; i < _expectedColumns.length; i++) DataCell(Text(i < row.length ? row[i].toString() : ''))]),
                ],
              ),
            ),
            const SizedBox(height: DukaniSpacing.xl),
            DukaniButton(label: 'استيراد ${_dataRows.length} سجل', icon: LucideIcons.checkCircle2, onPressed: _dataRows.isEmpty ? null : _import),
          ],
        ],
      ),
    );
  }
}

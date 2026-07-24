import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/suppliers/suppliers_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SupplierFormScreen extends ConsumerStatefulWidget {
  const SupplierFormScreen({super.key, this.supplierId});
  final String? supplierId;

  @override
  ConsumerState<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends ConsumerState<SupplierFormScreen> {
  late final _nameController = TextEditingController(text: _editing?.name ?? '');
  late final _phoneController = TextEditingController(text: _editing?.phone ?? '');
  late final _notesController = TextEditingController(text: _editing?.notes ?? '');
  late String _category = _editing?.category ?? mockPosCategories.skip(1).first;

  MockSupplier? get _editing => widget.supplierId == null ? null : ref.read(suppliersProvider.notifier).byId(widget.supplierId!);
  bool get _isEditing => widget.supplierId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل اسم المورد')));
      return;
    }

    final supplier = MockSupplier(
      id: _editing?.id ?? ref.read(suppliersProvider.notifier).nextId(),
      name: name,
      phone: _phoneController.text.trim(),
      category: _category,
      payable: _editing?.payable ?? 0,
      lastOrder: _editing?.lastOrder ?? 'لا يوجد',
      notes: _notesController.text.trim(),
    );

    if (_isEditing) {
      ref.read(suppliersProvider.notifier).update(supplier.id, supplier);
    } else {
      ref.read(suppliersProvider.notifier).add(supplier);
    }
    context.pop();
  }

  Future<void> _delete() async {
    final ok = await DukaniConfirmDialog.show(
      context,
      title: 'حذف المورد؟',
      message: 'سيتم حذف "${_editing!.name}" نهائيًا من قائمة الموردين.',
      confirmLabel: 'حذف',
      destructive: true,
      icon: LucideIcons.trash2,
    );
    if (!ok) return;
    if (!mounted) return;
    final logged = await logSensitiveAction(
      context,
      ref,
      action: 'حذف المورد "${_editing!.name}"',
      category: 'حذف',
    );
    if (!logged) return;
    ref.read(suppliersProvider.notifier).remove(_editing!.id);
    if (mounted) {
      context.pop();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DukaniAppBar(
        title: _isEditing ? 'تعديل المورد' : 'مورد جديد',
        actions: [
          if (_isEditing) DukaniIconAction(icon: LucideIcons.trash2, onTap: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          DukaniTextField(label: 'اسم المورد', hint: 'مثال: شركة القهوة العربية', controller: _nameController, autofocus: !_isEditing),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'رقم الجوال', hint: '05xxxxxxxx', controller: _phoneController, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr),
          const SizedBox(height: DukaniSpacing.lg),
          Text('الفئة الموردة', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: DukaniSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in mockPosCategories.skip(1)) DukaniChoiceChip(label: c, selected: c == _category, onTap: () => setState(() => _category = c)),
            ],
          ),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'ملاحظات (اختياري)', hint: 'مثال: يورّد كل يوم أحد', controller: _notesController),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(label: _isEditing ? 'حفظ التعديلات' : 'إضافة المورد', icon: LucideIcons.checkCircle2, onPressed: _save),
        ],
      ),
    );
  }
}

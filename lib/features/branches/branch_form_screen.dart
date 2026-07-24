import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/branches/branches_controller.dart';
import '../../core/subscription/plan_limits.dart';
import '../../core/subscription/subscription_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BranchFormScreen extends ConsumerStatefulWidget {
  const BranchFormScreen({super.key, this.branchId});
  final String? branchId;

  @override
  ConsumerState<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends ConsumerState<BranchFormScreen> {
  late final _nameController = TextEditingController(text: _editing?.name ?? '');
  late final _addressController = TextEditingController(text: _editing?.address ?? '');
  late final _phoneController = TextEditingController(text: _editing?.phone ?? '');
  late final _managerController = TextEditingController(text: _editing?.managerName ?? '');
  late bool _active = _editing?.active ?? true;
  late bool _isWarehouse = _editing?.isWarehouse ?? false;

  MockBranch? get _editing => widget.branchId == null ? null : ref.read(branchesProvider.notifier).byId(widget.branchId!);
  bool get _isEditing => widget.branchId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _managerController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل اسم الفرع')));
      return;
    }

    if (!_isEditing) {
      final limits = planLimitsFor(ref.read(currentPlanProvider).valueOrNull);
      final maxBranches = limits.maxBranches;
      if (maxBranches != null && ref.read(branchesProvider).length >= maxBranches) {
        showUpgradeRequiredDialog(context, 'باقتك الحالية تسمح بحتى $maxBranches فرع. قم بالترقية لإضافة المزيد.');
        return;
      }
    }

    final branch = MockBranch(
      id: _editing?.id ?? ref.read(branchesProvider.notifier).nextId(),
      name: name,
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      managerName: _managerController.text.trim(),
      active: _active,
      isMain: _editing?.isMain ?? false,
      isWarehouse: _isWarehouse,
    );

    if (_isEditing) {
      ref.read(branchesProvider.notifier).update(branch.id, branch);
    } else {
      ref.read(branchesProvider.notifier).add(branch);
    }
    context.pop();
  }

  Future<void> _delete() async {
    if (_editing!.isMain) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يمكن حذف الفرع الرئيسي')));
      return;
    }
    final ok = await DukaniConfirmDialog.show(
      context,
      title: 'حذف الفرع؟',
      message: 'سيتم حذف "${_editing!.name}" نهائيًا من قائمة الفروع.',
      confirmLabel: 'حذف',
      destructive: true,
      icon: LucideIcons.trash2,
    );
    if (!ok) return;
    if (!mounted) return;
    final logged = await logSensitiveAction(
      context,
      ref,
      action: 'حذف الفرع "${_editing!.name}"',
      category: 'حذف',
    );
    if (!logged) return;
    ref.read(branchesProvider.notifier).remove(_editing!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DukaniAppBar(
        title: _isEditing ? 'تعديل الفرع' : 'فرع جديد',
        actions: [
          if (_isEditing && !_editing!.isMain) DukaniIconAction(icon: LucideIcons.trash2, onTap: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          DukaniTextField(label: 'اسم الفرع', hint: 'مثال: فرع الروضة', controller: _nameController, autofocus: !_isEditing),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'العنوان', hint: 'مثال: الرياض — حي الروضة', controller: _addressController),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'رقم الهاتف', hint: '01xxxxxxxx', controller: _phoneController, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'اسم المدير (اختياري)', hint: 'مثال: سارة علي', controller: _managerController),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الفرع نشط', style: Theme.of(context).textTheme.titleSmall),
                    Text('إغلاق الفرع يوقف عمليات البيع فيه', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                  ],
                ),
                Switch(value: _active, onChanged: (v) => setState(() => _active = v), activeColor: DukaniColors.forest600),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('مخزن فقط', style: Theme.of(context).textTheme.titleSmall),
                    Text('موقع تخزين غير مخصص لاستقبال العملاء أو نقطة بيع', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                  ],
                ),
                Switch(value: _isWarehouse, onChanged: (v) => setState(() => _isWarehouse = v), activeColor: DukaniColors.forest600),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(label: _isEditing ? 'حفظ التعديلات' : 'إضافة الفرع', icon: LucideIcons.checkCircle2, onPressed: _save),
        ],
      ),
    );
  }
}

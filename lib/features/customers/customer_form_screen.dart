import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/customers/customers_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customerId});
  final String? customerId;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  late final _nameController = TextEditingController(text: _editing?.name ?? '');
  late final _phoneController = TextEditingController(text: _editing?.phone ?? '');
  late final _notesController = TextEditingController(text: _editing?.notes ?? '');
  late final _referralController = TextEditingController();

  MockCustomer? get _editing => widget.customerId == null ? null : ref.read(customersProvider.notifier).byId(widget.customerId!);
  bool get _isEditing => widget.customerId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل اسم العميل')));
      return;
    }

    final notifier = ref.read(customersProvider.notifier);

    MockCustomer? referrer;
    final referralInput = _referralController.text.trim();
    if (!_isEditing && referralInput.isNotEmpty) {
      referrer = notifier.byReferralCode(referralInput);
      if (referrer == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كود الإحالة غير صحيح')));
        return;
      }
    }

    final customer = MockCustomer(
      id: _editing?.id ?? notifier.nextId(),
      name: name,
      phone: _phoneController.text.trim(),
      debt: _editing?.debt ?? 0,
      lastPurchase: _editing?.lastPurchase ?? 'لا يوجد',
      notes: _notesController.text.trim(),
      loyaltyPoints: _editing?.loyaltyPoints ?? 0,
      referralCode: _editing?.referralCode ?? notifier.generateReferralCode(),
      referredBy: _editing?.referredBy ?? referrer?.id ?? '',
    );

    if (_isEditing) {
      notifier.update(customer.id, customer);
    } else {
      notifier.add(customer);
      if (referrer != null) notifier.applyReferralBonus(customer.id, referrer.id);
    }
    context.pop();
  }

  Future<void> _delete() async {
    final ok = await DukaniConfirmDialog.show(
      context,
      title: 'حذف العميل؟',
      message: 'سيتم حذف "${_editing!.name}" نهائيًا من قائمة العملاء.',
      confirmLabel: 'حذف',
      destructive: true,
      icon: LucideIcons.trash2,
    );
    if (!ok) return;
    if (!mounted) return;
    final logged = await logSensitiveAction(
      context,
      ref,
      action: 'حذف العميل "${_editing!.name}"',
      category: 'حذف',
    );
    if (!logged) return;
    ref.read(customersProvider.notifier).remove(_editing!.id);
    if (mounted) {
      context.pop();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DukaniAppBar(
        title: _isEditing ? 'تعديل العميل' : 'عميل جديد',
        actions: [
          if (_isEditing) DukaniIconAction(icon: LucideIcons.trash2, onTap: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          DukaniTextField(label: 'اسم العميل', hint: 'مثال: خالد المطيري', controller: _nameController, autofocus: !_isEditing),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'رقم الجوال', hint: '05xxxxxxxx', controller: _phoneController, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(label: 'ملاحظات (اختياري)', hint: 'مثال: عميل جملة', controller: _notesController),
          if (!_isEditing) ...[
            const SizedBox(height: DukaniSpacing.lg),
            DukaniTextField(
              label: 'كود الإحالة (اختياري)',
              hint: 'KHALID10',
              controller: _referralController,
              textDirection: TextDirection.ltr,
            ),
          ],
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(label: _isEditing ? 'حفظ التعديلات' : 'إضافة العميل', icon: LucideIcons.checkCircle2, onPressed: _save),
        ],
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/activity/activity_log_controller.dart';
import '../../core/employees/employee_credentials_share.dart';
import '../../core/employees/employees_controller.dart';
import '../../core/media/product_photo_picker.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  const EmployeeFormScreen({super.key, this.employeeId});
  final String? employeeId;

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  late final _nameController = TextEditingController(text: _editing?.name ?? '');
  late final _phoneController = TextEditingController(text: _editing?.phone ?? '');
  late String _role = _editing?.role ?? mockEmployeeRoles.last;
  late bool _active = _editing?.active ?? true;
  late MockPermissions _permissions = _editing?.permissions ?? const MockPermissions();
  late Uint8List? _photoBytes = _editing?.photoBytes;
  String? _phoneError;

  MockEmployee? get _editing => widget.employeeId == null ? null : ref.read(employeesProvider.notifier).byId(widget.employeeId!);
  bool get _isEditing => widget.employeeId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل اسم الموظف')));
      return;
    }
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل رقم جوال الموظف')));
      return;
    }
    // Username/phone must be unique across every employee in the system —
    // this only checks the current session's directory since there's no
    // backend yet, but the same rule will apply server-side.
    if (ref.read(employeesProvider.notifier).isPhoneTaken(phone, excludingId: _editing?.id)) {
      setState(() => _phoneError = 'رقم الجوال مستخدم بالفعل لموظف آخر');
      return;
    }

    final employee = MockEmployee(
      id: _editing?.id ?? ref.read(employeesProvider.notifier).nextId(),
      name: name,
      phone: phone,
      role: _role,
      active: _active,
      permissions: _permissions,
      photoBytes: _photoBytes,
      password: _editing?.password ?? generateEmployeePassword(),
    );

    if (_isEditing) {
      ref.read(employeesProvider.notifier).update(employee.id, employee);
      context.pop();
    } else {
      ref.read(employeesProvider.notifier).add(employee);
      shareEmployeeCredentials(context, employee, onDone: () {
        if (mounted) context.pop();
      });
    }
  }

  Future<void> _delete() async {
    final ok = await DukaniConfirmDialog.show(
      context,
      title: 'حذف الموظف؟',
      message: 'سيتم حذف "${_editing!.name}" نهائيًا من قائمة الموظفين.',
      confirmLabel: 'حذف',
      destructive: true,
      icon: LucideIcons.trash2,
    );
    if (!ok) return;
    if (!mounted) return;
    final logged = await logSensitiveAction(
      context,
      ref,
      action: 'حذف الموظف "${_editing!.name}"',
      category: 'حذف',
    );
    if (!logged) return;
    ref.read(employeesProvider.notifier).remove(_editing!.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DukaniAppBar(
        title: _isEditing ? 'تعديل الموظف' : 'موظف جديد',
        actions: [
          if (_isEditing) DukaniIconAction(icon: LucideIcons.share2, onTap: () => shareEmployeeCredentials(context, _editing!)),
          if (_isEditing) DukaniIconAction(icon: LucideIcons.trash2, onTap: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          Center(
            child: GestureDetector(
              onTap: () async {
                final bytes = await pickPhoto(context, title: 'صورة الموظف');
                if (bytes != null) setState(() => _photoBytes = bytes);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  DukaniAvatarImage(photoBytes: _photoBytes, size: 88),
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
              'صورة الموظف — تظهر عند تسجيل دخوله وفي سجل العمليات',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: DukaniColors.ink500),
            ),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniTextField(label: 'اسم الموظف', hint: 'مثال: سارة علي', controller: _nameController, autofocus: !_isEditing),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniTextField(
            label: 'رقم الجوال (اسم المستخدم لتسجيل الدخول)',
            hint: '05xxxxxxxx',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            errorText: _phoneError,
            onChanged: (_) {
              if (_phoneError != null) setState(() => _phoneError = null);
            },
          ),
          const SizedBox(height: DukaniSpacing.lg),
          Text('الدور الوظيفي', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: DukaniSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in mockEmployeeRoles) DukaniChoiceChip(label: r, selected: r == _role, onTap: () => setState(() => _role = r)),
            ],
          ),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الحساب نشط', style: Theme.of(context).textTheme.titleSmall),
                    Text('إيقاف الحساب يمنع الموظف من تسجيل الدخول', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                  ],
                ),
                Switch(value: _active, onChanged: (v) => setState(() => _active = v), activeColor: DukaniColors.forest600),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          Text('الصلاحيات', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: DukaniSpacing.md),
          DukaniCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _PermissionTile(label: 'تطبيق الخصومات', value: _permissions.applyDiscount, onChanged: (v) => setState(() => _permissions = _permissions.copyWith(applyDiscount: v))),
                const Divider(height: 1, indent: 16),
                _PermissionTile(label: 'المرتجعات والاستردادات', value: _permissions.processRefund, onChanged: (v) => setState(() => _permissions = _permissions.copyWith(processRefund: v))),
                const Divider(height: 1, indent: 16),
                _PermissionTile(label: 'عرض التقارير', value: _permissions.viewReports, onChanged: (v) => setState(() => _permissions = _permissions.copyWith(viewReports: v))),
                const Divider(height: 1, indent: 16),
                _PermissionTile(label: 'إدارة الإعدادات', value: _permissions.manageSettings, onChanged: (v) => setState(() => _permissions = _permissions.copyWith(manageSettings: v))),
                const Divider(height: 1, indent: 16),
                _PermissionTile(label: 'إدارة الموظفين', value: _permissions.manageEmployees, onChanged: (v) => setState(() => _permissions = _permissions.copyWith(manageEmployees: v))),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(label: _isEditing ? 'حفظ التعديلات' : 'إضافة الموظف', icon: LucideIcons.checkCircle2, onPressed: _save),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DukaniSpacing.lg, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Switch(value: value, onChanged: onChanged, activeColor: DukaniColors.forest600),
        ],
      ),
    );
  }
}

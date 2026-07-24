import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/employees/employees_controller.dart';
import '../../core/session/session_controller.dart';
import '../../core/support/support_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum _Step { phone, confirm, password }

/// Bank-app-style identity flow: enter phone/username → confirm "is this
/// you?" against the account's name+photo → enter password → in. A wrong
/// phone never even reaches a password prompt, and "not me" routes straight
/// into a support ticket instead of silently failing.
class EmployeeLoginScreen extends ConsumerStatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  ConsumerState<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends ConsumerState<EmployeeLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  _Step _step = _Step.phone;
  MockEmployee? _matched;
  String? _phoneError;
  String? _passwordError;
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _lookupPhone() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _phoneError = 'أدخل اسم المستخدم أو رقم الجوال');
      return;
    }
    final employee = ref.read(employeesProvider.notifier).byPhone(phone);
    if (employee == null) {
      setState(() => _phoneError = 'لا يوجد حساب موظف بهذا الرقم');
      return;
    }
    if (!employee.active) {
      setState(() => _phoneError = 'هذا الحساب موقوف — تواصل مع صاحب المتجر');
      return;
    }
    setState(() {
      _matched = employee;
      _phoneError = null;
      _step = _Step.confirm;
    });
  }

  void _notMe() {
    ref.read(supportChatControllerProvider).send(
          'تسجيل دخول موظف — الحساب ليس لي: حاولت الدخول برقم ${_phoneController.text.trim()} وظهر اسم "${_matched?.name}" وهو ليس أنا. الرجاء التحقق من بيانات الحساب.',
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال بلاغ لفريق الدعم، سنتواصل معك قريبًا')),
    );
    setState(() {
      _matched = null;
      _step = _Step.phone;
      _phoneController.clear();
    });
  }

  Future<void> _submitPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = 'أدخل كلمة المرور');
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    if (password == _matched!.password) {
      ref.read(sessionProvider.notifier).login(_matched!);
      context.goNamed('home');
    } else {
      setState(() {
        _loading = false;
        _passwordError = 'كلمة المرور غير صحيحة';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DukaniAppBar(
        title: 'دخول الموظفين',
        leading: _step == _Step.phone
            ? null
            : IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => setState(() {
                  _step = _step == _Step.password ? _Step.confirm : _Step.phone;
                  _passwordError = null;
                }),
              ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DukaniSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepProgress(step: _step),
              const SizedBox(height: DukaniSpacing.sm),
              Text(
                'الجوال ← تأكيد الهوية ← كلمة المرور',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500),
              ),
              Expanded(
                child: switch (_step) {
                  _Step.phone => _PhoneStep(
                      controller: _phoneController,
                      error: _phoneError,
                      onContinue: _lookupPhone,
                    ),
                  _Step.confirm => _ConfirmStep(
                      employee: _matched!,
                      onConfirm: () => setState(() => _step = _Step.password),
                      onNotMe: _notMe,
                    ),
                  _Step.password => _PasswordStep(
                      employee: _matched!,
                      controller: _passwordController,
                      obscure: _obscure,
                      error: _passwordError,
                      loading: _loading,
                      onToggleObscure: () => setState(() => _obscure = !_obscure),
                      onSubmit: _submitPassword,
                    ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three-segment progress row (phone → confirm → password) — matches the
/// mockup's step indicator exactly, one dash per stage of the identity flow.
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step});
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final index = _Step.values.indexOf(step);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _Step.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Container(
            width: 26,
            height: 3,
            decoration: BoxDecoration(
              color: i == index ? DukaniColors.forest700 : DukaniColors.ink100,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }
}

class _PhoneStep extends StatelessWidget {
  const _PhoneStep({required this.controller, required this.error, required this.onContinue});
  final TextEditingController controller;
  final String? error;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: DukaniSpacing.xl),
        const Icon(LucideIcons.idCard, size: 56, color: DukaniColors.forest600),
        const SizedBox(height: DukaniSpacing.lg),
        Text('دخول الموظفين', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: DukaniSpacing.sm),
        Text(
          'أدخل اسم المستخدم أو رقم الجوال الخاص بحسابك',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DukaniSpacing.xxl),
        DukaniTextField(
          label: 'اسم المستخدم أو رقم الجوال',
          hint: '05xxxxxxxx',
          controller: controller,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          prefixIcon: LucideIcons.user,
          errorText: error,
          autofocus: true,
          onSubmitted: (_) => onContinue(),
        ),
        const SizedBox(height: DukaniSpacing.xl),
        DukaniButton(label: 'التالي', icon: LucideIcons.arrowRight, onPressed: onContinue),
      ],
    );
  }
}

class _ConfirmStep extends StatelessWidget {
  const _ConfirmStep({required this.employee, required this.onConfirm, required this.onNotMe});
  final MockEmployee employee;
  final VoidCallback onConfirm;
  final VoidCallback onNotMe;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: DukaniSpacing.xl),
        Center(child: DukaniAvatarImage(photoBytes: employee.photoBytes, size: 96)),
        const SizedBox(height: DukaniSpacing.lg),
        Text(employee.name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          '${employee.role} — ${employee.branch}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DukaniSpacing.xxl),
        Text('هل هذا أنت؟', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: DukaniSpacing.lg),
        DukaniButton(label: 'نعم، هذا أنا', icon: LucideIcons.checkCircle2, onPressed: onConfirm),
        const SizedBox(height: DukaniSpacing.md),
        DukaniOutlineButton(label: 'ليس أنا', icon: LucideIcons.flag, onPressed: onNotMe),
      ],
    );
  }
}

class _PasswordStep extends StatelessWidget {
  const _PasswordStep({
    required this.employee,
    required this.controller,
    required this.obscure,
    required this.error,
    required this.loading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final MockEmployee employee;
  final TextEditingController controller;
  final bool obscure;
  final String? error;
  final bool loading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: DukaniSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DukaniAvatarImage(photoBytes: employee.photoBytes, size: 40),
            const SizedBox(width: DukaniSpacing.md),
            Text('مرحبًا ${employee.name}', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: DukaniSpacing.xxl),
        DukaniTextField(
          label: 'كلمة المرور',
          hint: '••••••••',
          controller: controller,
          obscureText: obscure,
          errorText: error,
          autofocus: true,
          suffix: IconButton(
            icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
            onPressed: onToggleObscure,
          ),
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: DukaniSpacing.xl),
        DukaniButton(label: 'تسجيل الدخول', icon: LucideIcons.logIn, loading: loading, onPressed: onSubmit),
      ],
    );
  }
}

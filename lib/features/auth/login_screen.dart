import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/business/business_type_controller.dart';
import '../../core/business/country_controller.dart';
import '../../core/employees/employees_controller.dart';
import '../../core/organizations/org_controller.dart';
import '../../core/session/session_controller.dart';
import '../../core/store/store_profile_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/or_divider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _error = null);
    final ok = await ref.read(authControllerProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(authControllerProvider).error;
      setState(() => _error = err is AuthException ? err.message : 'حصل خطأ غير متوقع، حاول تاني');
      return;
    }
    // Attributing the session to the local "مالك" seed employee is a
    // separate concern from auth — a real per-employee cloud profile is a
    // later phase, this just keeps the audit log/permissions working the
    // same way it already did.
    final owner = ref.read(employeesProvider).where((e) => e.role == 'مالك').toList();
    if (owner.isNotEmpty) ref.read(sessionProvider.notifier).login(owner.first);
    if (!mounted) return;

    // A returning owner already finished setup once — skip straight to the
    // dashboard instead of forcing them through it again on every sign-in.
    // Reads FirebaseAuth's synchronous currentUser (not authStateProvider's
    // stream, which can still be in its initial loading state this soon
    // after signIn() if nothing else has watched it yet) — otherwise a
    // returning owner's uid reads as null here, their real store profile
    // never gets fetched, and they get bounced back into store setup as if
    // they were a brand-new signup.
    final orgId = await ref.read(currentOrgIdProvider.future);
    final profile = orgId == null ? null : await ref.read(storeRepositoryProvider).fetch(orgId);
    if (!mounted) return;
    if (profile != null && profile.suspended) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (!mounted) return;
      setState(() => _error = 'تم إيقاف هذا الحساب من فريق دُكاني. تواصل مع الدعم الفني لمزيد من التفاصيل.');
      return;
    }
    if (profile != null) {
      ref.read(businessTypeProvider.notifier).set(
            BusinessType.values.firstWhere((t) => t.name == profile.businessType, orElse: () => BusinessType.generalRetail),
          );
      await ref.read(countryProvider.notifier).set(profile.countryCode);
      if (!mounted) return;
      context.goNamed('home');
      return;
    }
    context.goNamed('storeSetup');
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    return AuthScaffold(
      title: 'مرحبًا بعودتك',
      subtitle: 'سجّل الدخول لمتابعة إدارة متجرك',
      children: [
        DukaniTextField(
          label: 'البريد الإلكتروني',
          hint: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
          controller: _emailController,
        ),
        const SizedBox(height: DukaniSpacing.lg),
        DukaniTextField(
          label: 'كلمة المرور',
          hint: '••••••••',
          obscureText: _obscure,
          controller: _passwordController,
          suffix: IconButton(
            icon: Icon(_obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 20),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: DukaniSpacing.sm),
          Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.danger)),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.pushNamed('forgotPassword'),
            child: const Text('نسيت كلمة المرور؟'),
          ),
        ),
        const SizedBox(height: DukaniSpacing.xs),
        DukaniButton(label: 'تسجيل الدخول', loading: loading, onPressed: _login),
        const SizedBox(height: DukaniSpacing.md),
        const OrDivider(),
        const SizedBox(height: DukaniSpacing.md),
        DukaniSocialButton(provider: DukaniSocialProvider.apple, onPressed: null),
        const SizedBox(height: DukaniSpacing.sm),
        DukaniSocialButton(provider: DukaniSocialProvider.google, onPressed: null),
        const SizedBox(height: DukaniSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ليس لديك حساب؟'),
            TextButton(onPressed: () => context.pushNamed('register'), child: const Text('إنشاء حساب')),
          ],
        ),
        Center(
          child: TextButton.icon(
            onPressed: () => context.pushNamed('employeeLogin'),
            icon: const Icon(LucideIcons.idCard, size: 18),
            label: const Text('تسجيل دخول الموظفين'),
          ),
        ),
      ],
    );
  }
}

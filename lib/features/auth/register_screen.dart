import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/or_divider.dart';

const _termsUrl = 'https://trydukani.com/legal/terms';
const _privacyUrl = 'https://trydukani.com/legal/privacy';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _agree = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _error = null);
    final ok = await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(authControllerProvider).error;
      setState(() => _error = err is AuthException ? err.message : 'حصل خطأ غير متوقع، حاول تاني');
      return;
    }
    context.pushNamed('otp', queryParameters: {'next': '/store-setup'});
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    return AuthScaffold(
      title: 'إنشاء حساب جديد',
      subtitle: 'ابدأ رحلتك مع دُكاني في أقل من دقيقتين',
      children: [
        DukaniTextField(label: 'البريد الإلكتروني', hint: 'name@example.com', keyboardType: TextInputType.emailAddress, controller: _emailController),
        const SizedBox(height: DukaniSpacing.lg),
        DukaniTextField(label: 'كلمة المرور', hint: '••••••••', obscureText: true, controller: _passwordController),
        if (_error != null) ...[
          const SizedBox(height: DukaniSpacing.sm),
          Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.danger)),
        ],
        const SizedBox(height: DukaniSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(value: _agree, onChanged: (v) => setState(() => _agree = v ?? false)),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => setState(() => _agree = !_agree),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    children: [
                      const TextSpan(text: 'أوافق على '),
                      TextSpan(
                        text: 'الشروط والأحكام',
                        style: const TextStyle(color: DukaniColors.forest700, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(_termsUrl), mode: LaunchMode.externalApplication),
                      ),
                      const TextSpan(text: ' و'),
                      TextSpan(
                        text: 'سياسة الخصوصية',
                        style: const TextStyle(color: DukaniColors.forest700, decoration: TextDecoration.underline),
                        recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(_privacyUrl), mode: LaunchMode.externalApplication),
                      ),
                      const TextSpan(text: ' الخاصة بدُكاني'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DukaniSpacing.md),
        DukaniButton(label: 'إنشاء الحساب', loading: loading, onPressed: _agree ? _register : null),
        const SizedBox(height: DukaniSpacing.md),
        const OrDivider(),
        const SizedBox(height: DukaniSpacing.md),
        DukaniSocialButton(provider: DukaniSocialProvider.apple, onPressed: null),
        const SizedBox(height: DukaniSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('لديك حساب بالفعل؟'),
            TextButton(onPressed: () => context.pop(), child: const Text('تسجيل الدخول')),
          ],
        ),
      ],
    );
  }
}

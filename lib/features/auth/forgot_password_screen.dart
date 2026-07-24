import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/auth_scaffold.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  bool _loading = false;

  Future<void> _send() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);
    context.pushNamed('otp', queryParameters: {'next': '/login'});
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'نسيت كلمة المرور؟',
      subtitle: 'أدخل رقم هاتفك أو بريدك الإلكتروني وسنرسل لك رمز تحقق لإعادة التعيين',
      children: [
        const DukaniTextField(label: 'رقم الهاتف أو البريد الإلكتروني', hint: 'مثال: 05xxxxxxxx', prefixIcon: LucideIcons.atSign),
        const SizedBox(height: DukaniSpacing.xl),
        DukaniButton(label: 'إرسال رمز التحقق', loading: _loading, onPressed: _send),
      ],
    );
  }
}

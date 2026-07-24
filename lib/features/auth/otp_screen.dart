import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'widgets/auth_scaffold.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.nextRoute});
  final String nextRoute;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  bool _loading = false;
  String _code = '';
  int _secondsLeft = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsLeft = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else if (mounted) {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _loading = false);
    context.go(widget.nextRoute);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AuthScaffold(
      title: 'رمز التحقق',
      subtitle: 'أدخل الرمز المكوّن من 6 أرقام المرسل إلى هاتفك',
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: PinCodeTextField(
            appContext: context,
            length: 6,
            onChanged: (v) => setState(() => _code = v),
            onCompleted: (_) => _verify(),
            keyboardType: TextInputType.number,
            animationType: AnimationType.scale,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(DukaniRadii.md),
              fieldHeight: 52,
              fieldWidth: 44,
              activeColor: scheme.primary,
              selectedColor: scheme.primary,
              inactiveColor: DukaniColors.ink100,
              activeFillColor: DukaniColors.forest50,
              selectedFillColor: DukaniColors.forest50,
              inactiveFillColor: DukaniColors.forest50,
            ),
          ),
        ),
        const SizedBox(height: DukaniSpacing.xl),
        DukaniButton(label: 'تأكيد', loading: _loading, onPressed: _code.length == 6 ? _verify : null),
        const SizedBox(height: DukaniSpacing.lg),
        Center(
          child: _secondsLeft > 0
              ? Text('إعادة الإرسال بعد $_secondsLeft ثانية', style: const TextStyle(color: DukaniColors.ink500))
              : TextButton(onPressed: _startTimer, child: const Text('إعادة إرسال الرمز')),
        ),
      ],
    );
  }
}

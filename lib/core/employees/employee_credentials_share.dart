import 'dart:math';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/mock/mock_models.dart';
import '../theme/dukani_theme.dart';
import '../widgets/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A 4-digit numeric password — easy for a cashier to type on a POS
/// keypad, generated once by the store owner when creating the account
/// and never chosen by the employee themselves.
String generateEmployeePassword() => (1000 + Random().nextInt(9000)).toString();

/// Opens a WhatsApp/SMS chooser prefilled with the new employee's login
/// details — the owner reviews and taps send themselves, nothing is sent
/// automatically. Mirrors [shareDebtStatement]'s manual-send pattern.
void shareEmployeeCredentials(BuildContext context, MockEmployee employee, {VoidCallback? onDone}) {
  final message =
      'بيانات دخولك على تطبيق دُكاني:\nاسم المستخدم: ${employee.phone}\nكلمة المرور: ${employee.password}\n\nمن شاشة دخول الموظفين، أدخل رقمك وتأكد من هويتك ثم أدخل كلمة المرور.';
  final phoneDigits = employee.phone.replaceAll(RegExp(r'[^0-9]'), '');
  final waPhone = phoneDigits.startsWith('0') ? '966${phoneDigits.substring(1)}' : phoneDigits;

  showDukaniSheet(
    context,
    title: 'إرسال بيانات الدخول — ${employee.name}',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'كلمة المرور: ${employee.password}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: DukaniColors.forest700, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DukaniSpacing.lg),
        DukaniSheetAction(
          icon: LucideIcons.messageCircle,
          label: 'واتساب',
          color: DukaniColors.success,
          onTap: () async {
            Navigator.pop(context);
            final uri = Uri.parse('https://wa.me/$waPhone?text=${Uri.encodeComponent(message)}');
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        ),
        DukaniSheetAction(
          icon: LucideIcons.messageSquare,
          label: 'رسالة SMS',
          onTap: () async {
            Navigator.pop(context);
            final uri = Uri(scheme: 'sms', path: phoneDigits, queryParameters: {'body': message});
            await launchUrl(uri);
          },
        ),
      ],
    ),
  ).then((_) => onDone?.call());
}

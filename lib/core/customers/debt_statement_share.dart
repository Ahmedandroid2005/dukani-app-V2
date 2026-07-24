import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/dukani_theme.dart';
import '../widgets/widgets.dart';
import '../../data/mock/mock_models.dart';
import '../pos/sales_log_controller.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

String _twoDigits(int n) => n.toString().padLeft(2, '0');

/// Builds the plain-text debt statement shared with a customer — their
/// balance plus a short list of the purchases behind it.
String _statementMessage(MockCustomer customer, List<SaleRecord> purchases) {
  final buffer = StringBuffer()
    ..writeln('كشف حساب — دُكاني')
    ..writeln('العميل: ${customer.name}')
    ..writeln('الرصيد المستحق: ${customer.debt.toStringAsFixed(2)} ${currentCurrencySymbol()}')
    ..writeln();
  if (purchases.isNotEmpty) {
    buffer.writeln('آخر المشتريات:');
    for (final inv in purchases.take(5)) {
      final t = inv.createdAt;
      buffer.writeln('• ${inv.id} — ${inv.total.toStringAsFixed(2)} ${currentCurrencySymbol()} (${t.year}-${_twoDigits(t.month)}-${_twoDigits(t.day)})');
    }
    buffer.writeln();
  }
  buffer.write('نرجو سداد المبلغ في أقرب وقت ممكن، شاكرين تعاملكم معنا.');
  return buffer.toString();
}

/// Opens a WhatsApp/SMS chooser prefilled with the customer's debt
/// statement — the merchant reviews it and taps send themselves in the
/// external app; nothing is sent automatically from here.
void shareDebtStatement(BuildContext context, MockCustomer customer, List<SaleRecord> purchases) {
  final message = _statementMessage(customer, purchases);
  final phoneDigits = customer.phone.replaceAll(RegExp(r'[^0-9]'), '');
  // Saudi-style local numbers (05xxxxxxxx) need the country code for wa.me.
  final waPhone = phoneDigits.startsWith('0') ? '966${phoneDigits.substring(1)}' : phoneDigits;

  showDukaniSheet(
    context,
    title: 'إرسال كشف حساب — ${customer.name}',
    child: Column(
      children: [
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
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/business/country_controller.dart';
import '../../core/payments/connected_gateway_controller.dart';
import '../../core/payments/payment_gateway.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Lets the merchant plug in their own gateway account — their own Tap,
/// PayTabs, Paymob, or Stripe merchant credentials, entered here once so
/// their POS payment screen can use them. Dukani never opens an account
/// with any of these on the merchant's behalf; see [PaymentGatewayProvider]
/// for why the key still can't process a real charge without a backend.
class PaymentGatewayLinkScreen extends ConsumerStatefulWidget {
  const PaymentGatewayLinkScreen({super.key});

  @override
  ConsumerState<PaymentGatewayLinkScreen> createState() => _PaymentGatewayLinkScreenState();
}

/// Second credential some gateways need alongside the API key — PayTabs'
/// profile id, or Paymob's integration+iframe pair. Null means the gateway
/// only needs the one API key field (Stripe, Tap).
String? _extraFieldLabel(String gatewayId) => switch (gatewayId) {
      'paytabs' => 'معرّف البروفايل (Profile ID)',
      'paymob' => 'معرّف التكامل:معرّف الـ iframe (Integration ID:Iframe ID)',
      'telr' => 'معرّف المتجر (Store ID)',
      'hyperpay' => 'معرّف الكيان (Entity ID)',
      'aps' => 'معرّف التاجر:عبارة SHA السرية (Merchant Identifier:SHA Request Phrase)',
      'geidea' => 'كلمة مرور الـ API (API Password)',
      'fawry' => 'كود التاجر (Merchant Code)',
      'thawani' => 'المفتاح العلني (Publishable Key)',
      'ni' => 'معرّف المنفذ (Outlet Reference)',
      _ => null,
    };

class _PaymentGatewayLinkScreenState extends ConsumerState<PaymentGatewayLinkScreen> {
  String? _selectedGatewayId;
  final _apiKeyController = TextEditingController();
  final _extraController = TextEditingController();

  @override
  void dispose() {
    _apiKeyController.dispose();
    _extraController.dispose();
    super.dispose();
  }

  void _save(String gatewayId) {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل مفتاح API الخاص بك أولًا')));
      return;
    }
    final extraLabel = _extraFieldLabel(gatewayId);
    final extra = _extraController.text.trim();
    if (extraLabel != null && extra.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أدخل $extraLabel أولًا')));
      return;
    }
    ref.read(connectedGatewayProvider.notifier).connect(gatewayId, key, extra: extraLabel != null ? extra : null);
    _apiKeyController.clear();
    _extraController.clear();
    setState(() => _selectedGatewayId = null);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الربط بنجاح')));
  }

  void _disconnect() {
    showDukaniSheet(
      context,
      title: 'قطع الاتصال بالبوابة؟',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'طرق الدفع المرتبطة بهذه البوابة هتشتغل تاني كـ"قريبًا" لحد ما تربط بوابة جديدة.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(
            label: 'قطع الاتصال',
            icon: LucideIcons.unlink,
            onPressed: () {
              ref.read(connectedGatewayProvider.notifier).disconnect();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final countryCode = ref.watch(countryProvider);
    final connected = ref.watch(connectedGatewayProvider);
    final available = PaymentGatewayRegistry.availableFor(countryCode);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const DukaniAppBar(title: 'ربط بوابة الدفع'),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          if (connected != null)
            DukaniCard(
              border: DukaniColors.forest600,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.checkCircle2, color: DukaniColors.success, size: 20),
                      const SizedBox(width: 8),
                      Text('مربوط بـ ${connected.provider?.displayName ?? connected.gatewayId}', style: textTheme.titleSmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'طرق الدفع اللي البوابة دي بتدعمها بقت شغالة فعليًا في شاشة الدفع.',
                    style: textTheme.bodySmall?.copyWith(color: DukaniColors.ink500),
                  ),
                  const SizedBox(height: DukaniSpacing.md),
                  DukaniOutlineButton(label: 'قطع الاتصال', icon: LucideIcons.unlink, onPressed: _disconnect),
                ],
              ),
            )
          else
            DukaniCard(
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: DukaniColors.ink500, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'مفيش بوابة مربوطة دلوقتي — نقدًا هو طريقة الدفع الوحيدة الشغالة فعليًا.',
                      style: textTheme.bodySmall?.copyWith(color: DukaniColors.ink500),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: DukaniSpacing.xl),
          Text('اختر بوابة عندك حساب فيها', style: textTheme.titleSmall),
          const SizedBox(height: DukaniSpacing.sm),
          Text(
            'لازم يكون عندك حساب تاجر حقيقي مسجل مسبقًا عند البوابة دي — دُكاني مش بتفتح حساب نيابة عنك.',
            style: textTheme.bodySmall?.copyWith(color: DukaniColors.ink500),
          ),
          const SizedBox(height: DukaniSpacing.md),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final g in available)
                DukaniChoiceChip(
                  label: g.displayName,
                  selected: _selectedGatewayId == g.id,
                  onTap: () => setState(() => _selectedGatewayId = g.id),
                ),
            ],
          ),
          if (_selectedGatewayId != null) ...[
            const SizedBox(height: DukaniSpacing.xl),
            DukaniTextField(
              label: 'مفتاح API الخاص بك',
              hint: 'الصق المفتاح من حسابك عند البوابة',
              controller: _apiKeyController,
              obscureText: true,
              prefixIcon: LucideIcons.keyRound,
            ),
            if (_extraFieldLabel(_selectedGatewayId!) != null) ...[
              const SizedBox(height: DukaniSpacing.md),
              DukaniTextField(
                label: _extraFieldLabel(_selectedGatewayId!)!,
                hint: 'من نفس حساب البوابة',
                controller: _extraController,
                prefixIcon: LucideIcons.tag,
              ),
            ],
            const SizedBox(height: DukaniSpacing.lg),
            DukaniButton(label: 'حفظ وربط', icon: LucideIcons.link, onPressed: () => _save(_selectedGatewayId!)),
          ],
        ],
      ),
    );
  }
}

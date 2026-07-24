import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/business/country_controller.dart';
import '../../core/subscription/subscription_controller.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'subscription_checkout_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _Plan {
  const _Plan({required this.id, required this.name, required this.suitedFor, required this.features, this.recommended = false});
  final String id;
  final String name;
  final String suitedFor;
  final List<String> features;
  final bool recommended;
}

const _plans = [
  _Plan(
    id: 'starter',
    name: 'Starter',
    suitedFor: 'بقالة صغيرة',
    features: ['فرع واحد', 'حتى 100 منتج', 'تقارير أساسية'],
  ),
  _Plan(
    id: 'pro',
    name: 'Pro',
    suitedFor: 'سوبرماركت متوسط',
    recommended: true,
    features: ['حتى 3 فروع', 'منتجات غير محدودة', 'كل التقارير', 'دعم فني أولوية'],
  ),
  _Plan(
    id: 'business',
    name: 'Business',
    suitedFor: 'متجر كبير + موظفين + فروع',
    features: ['فروع غير محدودة', 'صلاحيات موظفين متقدمة', 'تكامل API', 'مدير حساب مخصص'],
  ),
];

/// Monthly price per plan, in each supported country's own currency —
/// matches dukaniCountries' 8 codes exactly, so a merchant only ever sees
/// the price in their own money, never someone else's.
const Map<String, Map<String, String>> _pricesByCountry = {
  'SA': {'starter': '49 ر.س', 'pro': '99 ر.س', 'business': '199 ر.س'},
  'AE': {'starter': '49 درهم', 'pro': '99 درهم', 'business': '199 درهم'},
  'KW': {'starter': '4.9 د.ك', 'pro': '9.9 د.ك', 'business': '19.9 د.ك'},
  'OM': {'starter': '5 ر.ع', 'pro': '10 ر.ع', 'business': '20 ر.ع'},
  'QA': {'starter': '49 ر.ق', 'pro': '99 ر.ق', 'business': '199 ر.ق'},
  'BH': {'starter': '5 د.ب', 'pro': '10 د.ب', 'business': '20 د.ب'},
  'JO': {'starter': '10 د.أ', 'pro': '20 د.أ', 'business': '40 د.أ'},
  'EG': {'starter': '299 جنيه', 'pro': '599 جنيه', 'business': '1199 جنيه'},
};

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  void _upgrade(BuildContext context, _Plan plan) {
    showDukaniSheet(
      context,
      title: 'الترقية إلى ${plan.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('سيتم تفعيل الباقة الجديدة فور إتمام الدفع.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500), textAlign: TextAlign.center),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniButton(
            label: 'المتابعة للدفع',
            icon: LucideIcons.award,
            onPressed: () async {
              Navigator.pop(context);
              final upgraded = await showSubscriptionCheckoutScreen(context, planId: plan.id);
              if (upgraded && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تفعيل باقة ${plan.name}')));
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countryCode = ref.watch(countryProvider);
    final prices = _pricesByCountry[countryCode] ?? _pricesByCountry['SA']!;
    final currentPlan = ref.watch(currentPlanProvider).valueOrNull;

    return Scaffold(
      appBar: const DukaniAppBar(title: 'الاشتراك'),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          for (final plan in _plans) ...[
            DukaniCard(
              border: plan.recommended ? DukaniColors.forest600 : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(plan.name, style: Theme.of(context).textTheme.titleMedium),
                          if (plan.recommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: DukaniColors.forest100, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
                              child: Text('الأكثر اختيارًا', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.forest700)),
                            ),
                          ],
                        ],
                      ),
                      DukaniAmountText('${prices[plan.id]} / شهريًا', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.forest700)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('مناسبة لـ ${plan.suitedFor}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
                  const SizedBox(height: DukaniSpacing.md),
                  for (final f in plan.features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.checkCircle2, size: 16, color: DukaniColors.success),
                          const SizedBox(width: 8),
                          Text(f, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  const SizedBox(height: DukaniSpacing.sm),
                  if (currentPlan == plan.id)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.checkCircle2, size: 16, color: DukaniColors.success),
                        const SizedBox(width: 6),
                        Text('باقتك الحالية', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.success)),
                      ],
                    )
                  else
                    DukaniOutlineButton(label: 'الترقية لهذه الباقة', onPressed: () => _upgrade(context, plan)),
                ],
              ),
            ),
            const SizedBox(height: DukaniSpacing.md),
          ],
        ],
      ),
    );
  }
}

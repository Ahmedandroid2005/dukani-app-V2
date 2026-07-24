import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/customers/customers_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersProvider);
    final totalPoints = customers.fold<int>(0, (s, c) => s + c.loyaltyPoints);
    final leaderboard = [...customers.where((c) => c.loyaltyPoints > 0)]..sort((a, b) => b.loyaltyPoints.compareTo(a.loyaltyPoints));

    return Scaffold(
      appBar: const DukaniAppBar(title: 'برنامج الولاء'),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          DukaniCard(
            color: DukaniColors.forest700,
            child: Column(
              children: [
                Text('إجمالي النقاط الممنوحة', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                const SizedBox(height: 6),
                DukaniAmountText('$totalPoints نقطة', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.award, color: DukaniColors.gold600),
                    const SizedBox(width: 8),
                    Text('قواعد البرنامج', style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: DukaniSpacing.md),
                _RuleRow(label: 'الكسب', value: 'نقطة واحدة لكل 10 ${currentCurrencySymbol()} من قيمة الشراء'),
                const Divider(height: DukaniSpacing.xl),
                _RuleRow(label: 'الاستبدال', value: '10 نقاط = 1 ${currentCurrencySymbol()} خصم'),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          Text('الأعلى نقاطًا', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: DukaniSpacing.md),
          if (leaderboard.isEmpty)
            const DukaniEmptyState(title: 'لا يوجد عملاء لديهم نقاط بعد', icon: LucideIcons.award)
          else
            for (var i = 0; i < leaderboard.length; i++) ...[
              DukaniCard(
                onTap: () => context.pushNamed(R.customerDetail, pathParameters: {'id': leaderboard[i].id}),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: i == 0 ? DukaniColors.gold100 : DukaniColors.forest50, shape: BoxShape.circle),
                      child: Text('${i + 1}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: i == 0 ? DukaniColors.gold700 : DukaniColors.forest600)),
                    ),
                    const SizedBox(width: DukaniSpacing.md),
                    Expanded(child: Text(leaderboard[i].name, style: Theme.of(context).textTheme.titleSmall)),
                    DukaniAmountText('${leaderboard[i].loyaltyPoints} نقطة', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.gold700)),
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

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
        Flexible(child: Text(value, style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.end)),
      ],
    );
  }
}

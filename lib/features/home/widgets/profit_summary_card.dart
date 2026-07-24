import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/pos/sales_log_controller.dart';
import '../../../core/reports/live_reports.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/dukani_theme.dart';
import '../../../core/widgets/dukani_amount_text.dart';
import '../../../core/widgets/dukani_card.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfitSummaryCard extends ConsumerWidget {
  const ProfitSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final sales = ref.watch(salesLogProvider);
    final today = LiveProfitFigures.from(salesToday(sales));
    final todayRevenue = LiveSalesFigures.from(salesToday(sales)).totalRevenue;
    final yesterday = LiveProfitFigures.from(salesYesterday(sales));
    final trend = percentChange(yesterday.netProfit, today.netProfit);
    final marginRatio = (today.marginPercent / 100).clamp(0.0, 1.0);

    return DukaniCard(
      onTap: () => context.pushNamed(R.reportDetail, pathParameters: {'id': 'profits'}),
      padding: const EdgeInsets.all(DukaniSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('صافي الربح اليوم', style: textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
                    const SizedBox(height: 6),
                    DukaniAmountText('${today.netProfit.toStringAsFixed(2)} ${currentCurrencySymbol()}', style: DukaniTypography.statFigure(Theme.of(context).colorScheme.onSurface, size: 26)),
                    if (trend != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: trend >= 0 ? DukaniColors.successBg : DukaniColors.dangerBg, borderRadius: BorderRadius.circular(DukaniRadii.pill)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(trend >= 0 ? LucideIcons.arrowUp : LucideIcons.arrowDown, size: 12, color: trend >= 0 ? DukaniColors.success : DukaniColors.danger),
                            const SizedBox(width: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DukaniAmountText('${trend.abs().toStringAsFixed(1)}%', style: textTheme.labelSmall?.copyWith(color: trend >= 0 ? DukaniColors.success : DukaniColors.danger)),
                                Text(' عن أمس', style: textTheme.labelSmall?.copyWith(color: trend >= 0 ? DukaniColors.success : DukaniColors.danger)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _MarginRing(margin: marginRatio, label: '${today.marginPercent.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: DukaniSpacing.lg),
          const Divider(),
          const SizedBox(height: DukaniSpacing.md),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'الإيرادات', value: todayRevenue.toStringAsFixed(0))),
              const _VDivider(),
              Expanded(child: _MiniStat(label: 'تكلفة البضاعة', value: today.cogs.toStringAsFixed(0))),
              const _VDivider(),
              Expanded(child: _MiniStat(label: 'هامش الربح', value: '${today.marginPercent.toStringAsFixed(1)}%')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MarginRing extends StatelessWidget {
  const _MarginRing({required this.margin, required this.label});
  final double margin;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: margin,
            strokeWidth: 6,
            backgroundColor: DukaniColors.ink100,
            valueColor: const AlwaysStoppedAnimation(DukaniColors.gold500),
          ),
          DukaniAmountText(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        DukaniAmountText(value, style: textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(label, style: textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
      ],
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 28, color: DukaniColors.ink100);
}

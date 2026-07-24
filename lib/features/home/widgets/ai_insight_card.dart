import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/alerts/product_alerts.dart';
import '../../../core/pos/sales_log_controller.dart';
import '../../../core/reports/live_reports.dart';
import '../../../core/theme/dukani_theme.dart';
import '../../../core/widgets/dukani_card.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _Insight {
  const _Insight(this.icon, this.text, this.tone);
  final IconData icon;
  final String text;
  final Color tone;
}

/// Real, rule-based observations computed from the store's actual sales
/// and stock — no fabricated "AI" text. Caps at 3 so the card stays short;
/// severity (danger alerts first) decides which ones win when there are
/// more real things to say than room to say them.
List<_Insight> _buildInsights(List<SaleRecord> sales, List<ProductAlert> alerts) {
  final insights = <_Insight>[];

  final todayProfit = LiveProfitFigures.from(salesToday(sales)).netProfit;
  final yesterdayProfit = LiveProfitFigures.from(salesYesterday(sales)).netProfit;
  final trend = percentChange(yesterdayProfit, todayProfit);
  if (trend != null && trend.abs() >= 1) {
    insights.add(_Insight(
      trend >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
      trend >= 0 ? 'ارتفع ربحك اليوم ${trend.toStringAsFixed(1)}% مقارنة بالأمس' : 'انخفض ربحك اليوم ${trend.abs().toStringAsFixed(1)}% مقارنة بالأمس',
      trend >= 0 ? DukaniColors.success : DukaniColors.danger,
    ));
  }

  final dangerAlerts = alerts.where((a) => a.severity == 'danger').toList();
  final warningAlerts = alerts.where((a) => a.severity == 'warning').toList();
  if (dangerAlerts.isNotEmpty) {
    insights.add(_Insight(LucideIcons.alertTriangle, dangerAlerts.first.title, DukaniColors.danger));
  } else if (warningAlerts.isNotEmpty) {
    insights.add(_Insight(LucideIcons.alertTriangle, warningAlerts.first.title, DukaniColors.gold600));
  }

  if (alerts.length > 1) {
    insights.add(_Insight(LucideIcons.bellRing, '${alerts.length} تنبيهًا يحتاج مراجعتك — الصلاحية والركود', DukaniColors.info));
  }

  return insights.take(3).toList();
}

/// "ملخص اليوم" — a few genuinely computed observations from today's
/// sales and stock alerts, not a fixed script. Empty when there's nothing
/// real to report yet, rather than always showing something.
class AiInsightCard extends ConsumerWidget {
  const AiInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesLogProvider);
    final alerts = ref.watch(productAlertsProvider);
    final insights = _buildInsights(sales, alerts);
    final textTheme = Theme.of(context).textTheme;

    if (insights.isEmpty) return const SizedBox.shrink();

    return DukaniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(gradient: DukaniColors.goldGradient, borderRadius: BorderRadius.circular(DukaniRadii.sm)),
                child: const Icon(LucideIcons.sparkles, size: 18, color: Colors.white),
              ),
              const SizedBox(width: DukaniSpacing.md),
              Text('ملخص اليوم', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: DukaniSpacing.lg),
          for (final insight in insights) ...[
            _InsightRow(insight: insight),
            if (insight != insights.last) const SizedBox(height: DukaniSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});
  final _Insight insight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: insight.tone.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(insight.icon, size: 14, color: insight.tone),
        ),
        const SizedBox(width: DukaniSpacing.md),
        Expanded(child: Text(insight.text, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }
}

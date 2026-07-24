import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/forecast/forecast_helper.dart';
import '../../core/pos/sales_log_controller.dart';
import '../../core/reports/live_reports.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import 'package:dukani_app/core/business/currency.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const projectedDays = 3;
    final weekly = weeklyProfitSeries(ref.watch(salesLogProvider));

    if (weekly.values.every((v) => v == 0)) {
      return const Scaffold(
        appBar: DukaniAppBar(title: 'توقعات المبيعات'),
        body: DukaniEmptyState(
          title: 'لا توجد مبيعات كافية بعد',
          message: 'التوقع يحتاج أسبوعًا واحدًا على الأقل من المبيعات الحقيقية ليكون له معنى.',
          icon: LucideIcons.trendingUp,
        ),
      );
    }

    final projected = projectNextDays(weekly.values, projectedDays);
    final chartValues = [...weekly.values, ...projected];
    final chartLabels = [...weekly.labels, for (var i = 1; i <= projectedDays; i++) 'توقع $i'];

    final projectedTotal = projected.fold<double>(0, (s, v) => s + v);
    final historyAvg = weekly.values.reduce((a, b) => a + b) / weekly.values.length;
    final projectedAvg = projectedTotal / projected.length;
    final growthPercent = historyAvg == 0 ? 0.0 : ((projectedAvg - historyAvg) / historyAvg) * 100;

    return Scaffold(
      appBar: const DukaniAppBar(title: 'توقعات المبيعات'),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          DukaniCard(
            color: DukaniColors.forest700,
            child: Column(
              children: [
                Text('إجمالي المتوقع خلال $projectedDays أيام القادمة', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                const SizedBox(height: 6),
                DukaniAmountText('${projectedTotal.toStringAsFixed(0)} ${currentCurrencySymbol()}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.lg),
          Row(
            children: [
              Expanded(
                child: DukaniStatTile(
                  label: 'متوسط الربح اليومي',
                  value: '${historyAvg.toStringAsFixed(0)} ${currentCurrencySymbol()}',
                  icon: LucideIcons.calendarRange,
                  iconColor: DukaniColors.forest600,
                ),
              ),
              const SizedBox(width: DukaniSpacing.md),
              Expanded(
                child: DukaniStatTile(
                  label: 'اتجاه التوقع',
                  value: '${growthPercent >= 0 ? '+' : ''}${growthPercent.toStringAsFixed(1)}%',
                  icon: growthPercent >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                  iconColor: growthPercent >= 0 ? DukaniColors.success : DukaniColors.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: DukaniSpacing.xl),
          DukaniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DukaniSectionHeader(title: 'الأرباح: فعلي + توقع'),
                const SizedBox(height: DukaniSpacing.md),
                DukaniLineChart(values: chartValues, labels: chartLabels),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.lg),
          DukaniCard(
            color: DukaniColors.gold100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(LucideIcons.info, color: DukaniColors.gold700, size: 20),
                const SizedBox(width: DukaniSpacing.md),
                Expanded(
                  child: Text(
                    'هذا تقدير تقريبي مبني على اتجاه الأسبوع الماضي فقط، وليس تحليلاً إحصائيًا دقيقًا. كلما زادت بيانات المبيعات المتوفرة، زادت دقة التوقع.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.gold700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pos/sales_log_controller.dart';
import '../../../core/reports/live_reports.dart';
import '../../../core/theme/dukani_theme.dart';
import '../../../core/widgets/dukani_card.dart';
import '../../../core/widgets/dukani_chart.dart';

class WeeklyChartCard extends ConsumerWidget {
  const WeeklyChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = weeklyProfitSeries(ref.watch(salesLogProvider));
    return DukaniCard(
      padding: const EdgeInsets.all(DukaniSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DukaniSectionHeader(title: 'الأرباح خلال الأسبوع'),
          const SizedBox(height: DukaniSpacing.md),
          DukaniLineChart(values: series.values, labels: series.labels),
        ],
      ),
    );
  }
}

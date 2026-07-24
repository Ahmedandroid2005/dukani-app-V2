import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/alerts/product_alerts.dart';
import '../../../core/pos/sales_log_controller.dart';
import '../../../core/reports/live_reports.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/dukani_theme.dart';
import '../../../core/widgets/dukani_amount_text.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class QuickStatsRow extends ConsumerWidget {
  const QuickStatsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsCount = ref.watch(productAlertsProvider).length;
    final today = salesToday(ref.watch(salesLogProvider));
    final todayFigures = LiveSalesFigures.from(today);

    return Row(
      children: [
        Expanded(
          child: _QuickStat(
            label: 'تنبيهات',
            value: '$alertsCount',
            color: DukaniColors.danger,
            icon: LucideIcons.bellRing,
            onTap: () => context.pushNamed(R.alerts),
          ),
        ),
        const SizedBox(width: DukaniSpacing.md),
        Expanded(
          child: _QuickStat(
            label: 'فواتير اليوم',
            value: '${todayFigures.invoiceCount}',
            color: DukaniColors.info,
            icon: LucideIcons.receipt,
            onTap: () => context.pushNamed(R.invoices),
          ),
        ),
        const SizedBox(width: DukaniSpacing.md),
        Expanded(
          child: _QuickStat(
            label: 'مبيعات اليوم',
            value: todayFigures.totalRevenue.toStringAsFixed(0),
            color: DukaniColors.forest600,
            icon: LucideIcons.store,
            onTap: () => context.pushNamed(R.invoices),
          ),
        ),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({required this.label, required this.value, required this.color, required this.icon, required this.onTap});
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DukaniRadii.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: DukaniSpacing.md, horizontal: DukaniSpacing.sm),
        decoration: BoxDecoration(
          color: dark ? DukaniColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(DukaniRadii.md),
          border: Border.all(color: dark ? DukaniColors.darkBorder : DukaniColors.ink100),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            DukaniAmountText(value, style: Theme.of(context).textTheme.titleMedium),
            Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
          ],
        ),
      ),
    );
  }
}

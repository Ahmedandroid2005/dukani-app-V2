import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/business/feature_flags.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/dukani_theme.dart';
import '../../core/widgets/widgets.dart';
import '../../data/mock/mock_reports.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim();
    final filtered = q.isEmpty ? mockReports : mockReports.where((r) => r.title.contains(q)).toList();
    final byCategory = <ReportCategory, List<ReportDefinition>>{};
    for (final r in filtered) {
      byCategory.putIfAbsent(r.category, () => []).add(r);
    }

    return Scaffold(
      appBar: const DukaniAppBar(title: 'التقارير'),
      body: ListView(
        padding: const EdgeInsets.all(DukaniSpacing.lg),
        children: [
          DukaniSearchField(hint: 'بحث في التقارير', onChanged: (v) => setState(() => _query = v)),
          const SizedBox(height: DukaniSpacing.lg),
          if (isFeatureEnabled('sales_forecast')) ...[
            DukaniCard(
              color: DukaniColors.gold100,
              onTap: () => context.pushNamed(R.forecast),
              child: Row(
                children: [
                  const Icon(LucideIcons.trendingUp, color: DukaniColors.gold700),
                  const SizedBox(width: DukaniSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('توقعات المبيعات', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.gold700)),
                        Text('توقع تقريبي للأرباح خلال الأيام القادمة', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.gold700)),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronLeft, color: DukaniColors.gold700),
                ],
              ),
            ),
            const SizedBox(height: DukaniSpacing.md),
          ],
          DukaniCard(
            color: DukaniColors.forest50,
            onTap: () => context.pushNamed(R.daySummary),
            child: Row(
              children: [
                const Icon(LucideIcons.calendarDays, color: DukaniColors.forest700),
                const SizedBox(width: DukaniSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ملخص اليوم', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: DukaniColors.forest700)),
                      Text('كل شي حصل اليوم أو أمس بالتفصيل، بلمحة واحدة', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.forest700)),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronLeft, color: DukaniColors.forest700),
              ],
            ),
          ),
          const SizedBox(height: DukaniSpacing.xl),
          if (filtered.isEmpty)
            const DukaniEmptyState(title: 'لا توجد نتائج', icon: LucideIcons.searchX)
          else
            for (final category in ReportCategory.values)
              if (byCategory[category]?.isNotEmpty ?? false) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: DukaniSpacing.md, top: DukaniSpacing.sm),
                  child: Row(
                    children: [
                      Icon(category.icon, size: 16, color: DukaniColors.forest600),
                      const SizedBox(width: 8),
                      Text(category.label, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: DukaniSpacing.md,
                  crossAxisSpacing: DukaniSpacing.md,
                  childAspectRatio: 0.92,
                  children: [
                    for (final report in byCategory[category]!)
                      _ReportTile(
                        report: report,
                        onTap: () => context.pushNamed(R.reportDetail, pathParameters: {'id': report.id}),
                      ),
                  ],
                ),
                const SizedBox(height: DukaniSpacing.xl),
              ],
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report, required this.onTap});
  final ReportDefinition report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DukaniCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: DukaniSpacing.md, horizontal: DukaniSpacing.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: DukaniColors.forest50, borderRadius: BorderRadius.circular(DukaniRadii.sm)),
            child: Icon(report.icon, size: 20, color: DukaniColors.forest600),
          ),
          const SizedBox(height: DukaniSpacing.sm),
          Text(
            report.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

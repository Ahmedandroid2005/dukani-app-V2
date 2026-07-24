import 'package:flutter/material.dart';

import '../../core/theme/dukani_theme.dart';
import 'widgets/ai_insight_card.dart';
import 'widgets/home_header.dart';
import 'widgets/invoices_section.dart';
import 'widgets/profit_summary_card.dart';
import 'widgets/quick_stats_row.dart';
import 'widgets/stat_grid.dart';
import 'widgets/top_products_section.dart';
import 'widgets/weekly_chart_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HomeHeader(),
            Transform.translate(
              offset: const Offset(0, -28),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: DukaniSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfitSummaryCard(),
                    SizedBox(height: DukaniSpacing.lg),
                    QuickStatsRow(),
                    SizedBox(height: DukaniSpacing.xl),
                    HomeStatGrid(),
                    SizedBox(height: DukaniSpacing.xl),
                    AiInsightCard(),
                    SizedBox(height: DukaniSpacing.xl),
                    WeeklyChartCard(),
                    SizedBox(height: DukaniSpacing.xl),
                    TopProductsSection(),
                    SizedBox(height: DukaniSpacing.xl),
                    InvoicesSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

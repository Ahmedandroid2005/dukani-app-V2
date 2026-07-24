import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/dukani_theme.dart';

/// Smooth filled line chart (profit/sales trend) matching the brand look:
/// a soft gradient fill under a rounded, gold-accented stroke.
class DukaniLineChart extends StatelessWidget {
  const DukaniLineChart({super.key, required this.values, required this.labels, this.height = 180});

  final List<double> values;
  final List<String> labels;
  final double height;

  /// Compact axis labels (1.2k / 3.4M) so real currency figures don't force
  /// a wide reserved-size or wrap — the previous chart hid the Y axis
  /// entirely, which left the line with no numeric reference at all.
  static String _compact(double v) {
    final sign = v < 0 ? '-' : '';
    final n = v.abs();
    if (n >= 1000000) return '$sign${(n / 1000000).toStringAsFixed(n >= 10000000 ? 0 : 1)}M';
    if (n >= 1000) return '$sign${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k';
    return '$sign${n.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rawMax = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final maxY = rawMax <= 0 ? 1.0 : rawMax * 1.3;
    final interval = maxY / 4;
    final lastIndex = values.length - 1;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval == 0 ? 1 : interval,
            getDrawingHorizontalLine: (_) => FlLine(color: DukaniColors.ink500.withOpacity(0.08), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: interval == 0 ? 1 : interval,
                getTitlesWidget: (value, meta) => Text(
                  _compact(value),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(labels[i], style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => DukaniColors.forest800,
              tooltipRoundedRadius: 10,
              getTooltipItems: (spots) => [
                for (final s in spots) LineTooltipItem(_compact(s.y), const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              color: scheme.primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) => spot.x.toInt() == lastIndex,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 5,
                  color: scheme.primary,
                  strokeWidth: 3,
                  strokeColor: scheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [scheme.primary.withOpacity(0.28), scheme.primary.withOpacity(0.0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple bar chart (e.g. sales by day / expenses by category).
class DukaniBarChart extends StatelessWidget {
  const DukaniBarChart({super.key, required this.values, required this.labels, this.height = 180});

  final List<double> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rawMax = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final maxY = rawMax <= 0 ? 1.0 : rawMax * 1.3;
    final interval = maxY / 4;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval == 0 ? 1 : interval,
            getDrawingHorizontalLine: (_) => FlLine(color: DukaniColors.ink500.withOpacity(0.08), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: interval == 0 ? 1 : interval,
                getTitlesWidget: (value, meta) => Text(
                  DukaniLineChart._compact(value),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(labels[i], style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DukaniColors.ink500)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < values.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: scheme.primary,
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

/// Donut/pie chart used for category breakdowns (top departments by profit).
class DukaniPieChart extends StatelessWidget {
  const DukaniPieChart({super.key, required this.slices, this.size = 160});

  final List<DukaniPieSlice> slices;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: size * 0.28,
          sections: [
            for (final s in slices)
              PieChartSectionData(
                value: s.value,
                color: s.color,
                title: '',
                radius: size * 0.2,
              ),
          ],
        ),
      ),
    );
  }
}

class DukaniPieSlice {
  const DukaniPieSlice({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;
}

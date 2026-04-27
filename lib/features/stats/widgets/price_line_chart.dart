import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../stats_period.dart';

class PriceLineChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;
  final StatsPeriod period;

  const PriceLineChart({
    super.key,
    required this.data,
    required this.period,
  });

  List<FlSpot> get _spots => data
      .asMap()
      .entries
      .where((e) => e.value.value > 0)
      .map((e) => FlSpot(e.key.toDouble(), e.value.value))
      .toList();

  @override
  Widget build(BuildContext context) {
    final spots = _spots;
    if (spots.length < 2) return const SizedBox.shrink();

    final color = Theme.of(context).colorScheme.secondary;
    final ys = spots.map((s) => s.y).toList();
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range == 0 ? 0.3 : range * 0.3;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: spots.length > 3,
              color: color,
              barWidth: 2.5,
              dotData: FlDotData(show: spots.length <= 12),
              belowBarData: BarAreaData(
                show: true,
                color: color.withAlpha(25),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max || value == meta.min) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '\$${value.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: period.reservedBottom.toDouble(),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      period.formatLabel(data[idx].key),
                      style: const TextStyle(fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
        ),
      ),
    );
  }
}

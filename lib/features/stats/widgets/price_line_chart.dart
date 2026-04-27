import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class PriceLineChart extends StatelessWidget {
  final List<FlSpot> spots;

  const PriceLineChart({super.key, required this.spots});

  @override
  Widget build(BuildContext context) {
    if (spots.length < 2) return const SizedBox.shrink();

    final color = Theme.of(context).colorScheme.secondary;
    final ys = spots.map((s) => s.y).toList();
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range == 0 ? 0.5 : range * 0.3;

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: minY - padding,
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
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
                getTitlesWidget: (value, meta) => Text(
                  '\$${value.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(
              show: true, drawVerticalLine: false),
        ),
      ),
    );
  }
}

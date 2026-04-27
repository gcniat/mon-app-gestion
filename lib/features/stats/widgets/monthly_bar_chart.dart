import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<MapEntry<String, double>> data;

  const MonthlyBarChart({super.key, required this.data});

  static const _months = [
    '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
    'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
  ];

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final values = data.map((e) => e.value).toList();
    final maxY = values.isEmpty ? 100.0 : values.reduce((a, b) => a > b ? a : b);
    final adjustedMax = maxY == 0 ? 100.0 : maxY * 1.25;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: adjustedMax,
          barTouchData: const BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final monthNum =
                      int.tryParse(data[idx].key.split('-')[1]) ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_months[monthNum],
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: e.value.value == 0
                      ? color.withAlpha(50)
                      : color,
                  width: 22,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

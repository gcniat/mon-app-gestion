import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

enum ConsumptionPeriod { weekly, monthly }

class ConsumptionChart extends StatefulWidget {
  final List<MapEntry<String, double>> monthlyData;
  final List<MapEntry<String, double>> weeklyData;

  const ConsumptionChart({
    super.key,
    required this.monthlyData,
    required this.weeklyData,
  });

  @override
  State<ConsumptionChart> createState() => _ConsumptionChartState();
}

class _ConsumptionChartState extends State<ConsumptionChart> {
  ConsumptionPeriod _period = ConsumptionPeriod.monthly;

  static const _monthNames = [
    '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
    'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
  ];
  static const _dayNames = [
    '', 'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
    'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
  ];

  List<MapEntry<String, double>> get _data =>
      _period == ConsumptionPeriod.monthly
          ? widget.monthlyData
          : widget.weeklyData;

  String _formatLabel(String key) {
    if (_period == ConsumptionPeriod.monthly) {
      final month = int.tryParse(key.split('-')[1]) ?? 0;
      return _monthNames[month];
    } else {
      final dt = DateTime.tryParse(key);
      if (dt == null) return '';
      return '${dt.day}\n${_dayNames[dt.month]}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    final hasData = _data.any((e) => e.value > 0);

    return Column(
      children: [
        // Toggle semaine / mois
        SegmentedButton<ConsumptionPeriod>(
          segments: const [
            ButtonSegment(
              value: ConsumptionPeriod.weekly,
              label: Text('Par semaine'),
              icon: Icon(Icons.view_week_outlined),
            ),
            ButtonSegment(
              value: ConsumptionPeriod.monthly,
              label: Text('Par mois'),
              icon: Icon(Icons.calendar_month_outlined),
            ),
          ],
          selected: {_period},
          onSelectionChanged: (s) => setState(() => _period = s.first),
        ),
        const SizedBox(height: 16),

        if (!hasData)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Données insuffisantes.\nAjoutez le kilométrage dans vos relevés pour calculer la consommation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13),
            ),
          )
        else
          _buildChart(color),
      ],
    );
  }

  Widget _buildChart(Color color) {
    final values = _data.map((e) => e.value).toList();
    final maxY = values.fold(0.0, (m, v) => v > m ? v : m);
    final adjustedMax = maxY == 0 ? 20.0 : maxY * 1.3;
    final barWidth = _period == ConsumptionPeriod.weekly ? 14.0 : 22.0;

    return SizedBox(
      height: 210,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: adjustedMax,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _a, rod, _b) {
                if (rod.toY == 0) return null;
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(1)} L/100',
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max) return const SizedBox.shrink();
                  return Text('${value.toStringAsFixed(0)}L',
                      style: const TextStyle(fontSize: 10));
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
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatLabel(_data[idx].key),
                      style: const TextStyle(fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(
              show: true, drawVerticalLine: false),
          barGroups: _data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: e.value.value == 0
                      ? color.withAlpha(40)
                      : color,
                  width: barWidth,
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

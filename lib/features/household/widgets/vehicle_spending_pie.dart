import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../data/models/vehicle.dart';

const _palette = [
  Color(0xFF1565C0),
  Color(0xFFE91E63),
  Color(0xFF2E7D32),
  Color(0xFFEF6C00),
  Color(0xFF6A1B9A),
  Color(0xFF00838F),
  Color(0xFFBF360C),
  Color(0xFF37474F),
];

Color vehicleColor(int index) => _palette[index % _palette.length];

class VehicleSpendingPie extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Map<int, double> spentByVehicle;

  const VehicleSpendingPie({
    super.key,
    required this.vehicles,
    required this.spentByVehicle,
  });

  @override
  State<VehicleSpendingPie> createState() => _VehicleSpendingPieState();
}

class _VehicleSpendingPieState extends State<VehicleSpendingPie> {
  int _touchedIndex = -1;

  double get _total =>
      widget.spentByVehicle.values.fold(0, (s, v) => s + v);

  @override
  Widget build(BuildContext context) {
    if (_total == 0) {
      return const Center(
          child: Text('Aucune dépense enregistrée.',
              style: TextStyle(color: Colors.grey)));
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        response == null ||
                        response.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        response.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              centerSpaceRadius: 48,
              sectionsSpace: 2,
              sections: widget.vehicles.asMap().entries.map((entry) {
                final i = entry.key;
                final v = entry.value;
                final spent = widget.spentByVehicle[v.id!] ?? 0;
                final pct = _total == 0 ? 0.0 : spent / _total * 100;
                final isTouched = i == _touchedIndex;
                return PieChartSectionData(
                  value: spent,
                  color: vehicleColor(i),
                  radius: isTouched ? 70 : 58,
                  title: pct < 5 ? '' : '${pct.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Légende
        Wrap(
          spacing: 16,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: widget.vehicles.asMap().entries.map((entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: vehicleColor(entry.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(entry.value.name, style: const TextStyle(fontSize: 12)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

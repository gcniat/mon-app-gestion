import 'package:flutter/material.dart';
import '../../../core/formatters.dart';
import '../../../data/models/vehicle.dart';
import 'vehicle_spending_pie.dart';

class VehicleStatCard extends StatelessWidget {
  final Vehicle vehicle;
  final int colorIndex;
  final double totalSpent;
  final double totalLiters;
  final int entryCount;
  final double householdTotal;

  const VehicleStatCard({
    super.key,
    required this.vehicle,
    required this.colorIndex,
    required this.totalSpent,
    required this.totalLiters,
    required this.entryCount,
    required this.householdTotal,
  });

  @override
  Widget build(BuildContext context) {
    final color = vehicleColor(colorIndex);
    final pct = householdTotal == 0 ? 0.0 : totalSpent / householdTotal * 100;
    final avgPrice = totalLiters == 0 ? 0.0 : totalSpent / totalLiters;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête véhicule
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(vehicle.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Text('${pct.toStringAsFixed(1)} %',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            Text('${vehicle.brand} ${vehicle.model} • ${vehicle.licensePlate}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 10),

            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: householdTotal == 0 ? 0 : totalSpent / householdTotal,
                backgroundColor: color.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),

            // Stats en ligne
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Metric('Total', AppFormatters.currency(totalSpent)),
                _Metric('Litres', '${totalLiters.toStringAsFixed(1)} L'),
                _Metric('Prix moy./L', AppFormatters.currency(avgPrice)),
                _Metric('Relevés', '$entryCount'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }
}

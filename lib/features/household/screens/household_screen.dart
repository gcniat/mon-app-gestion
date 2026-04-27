import 'package:flutter/material.dart';
import '../../../core/formatters.dart';
import '../../../data/models/fuel_entry.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/fuel_entry_repository.dart';
import '../../../data/repositories/vehicle_repository.dart';
import '../widgets/vehicle_spending_pie.dart';
import '../widgets/vehicle_stat_card.dart';

class HouseholdScreen extends StatefulWidget {
  const HouseholdScreen({super.key});

  @override
  State<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends State<HouseholdScreen> {
  final _vehicleRepo = VehicleRepository();
  final _entryRepo = FuelEntryRepository();

  List<Vehicle> _vehicles = [];
  List<FuelEntry> _entries = [];
  bool _loading = true;

  Map<int, double> get _spentByVehicle {
    final map = {for (final v in _vehicles) v.id!: 0.0};
    for (final e in _entries) {
      map[e.vehicleId] = (map[e.vehicleId] ?? 0) + e.totalCost;
    }
    return map;
  }

  Map<int, double> get _litersByVehicle {
    final map = {for (final v in _vehicles) v.id!: 0.0};
    for (final e in _entries) {
      map[e.vehicleId] = (map[e.vehicleId] ?? 0) + e.liters;
    }
    return map;
  }

  Map<int, int> get _countByVehicle {
    final map = {for (final v in _vehicles) v.id!: 0};
    for (final e in _entries) {
      map[e.vehicleId] = (map[e.vehicleId] ?? 0) + 1;
    }
    return map;
  }

  double get _totalHousehold =>
      _spentByVehicle.values.fold(0.0, (s, v) => s + v);

  double get _totalLiters =>
      _litersByVehicle.values.fold(0.0, (s, v) => s + v);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vehicles = await _vehicleRepo.getAll();
    final entries = await _entryRepo.getAll();
    if (!mounted) return;
    setState(() {
      _vehicles = vehicles;
      _entries = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Trier les véhicules par dépenses décroissantes
    final sorted = [..._vehicles]..sort((a, b) =>
        (_spentByVehicle[b.id!] ?? 0)
            .compareTo(_spentByVehicle[a.id!] ?? 0));

    return Scaffold(
      appBar: AppBar(title: const Text('Foyer')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun véhicule enregistré.\nAjoutez des véhicules depuis l\'onglet Véhicules.',
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Carte total foyer
                      _HouseholdTotalCard(
                        total: _totalHousehold,
                        totalLiters: _totalLiters,
                        vehicleCount: _vehicles.length,
                        entryCount: _entries.length,
                      ),
                      const SizedBox(height: 24),

                      // Camembert répartition (si > 1 véhicule)
                      if (_vehicles.length > 1 && _totalHousehold > 0) ...[
                        _SectionTitle('Répartition des dépenses'),
                        const SizedBox(height: 12),
                        VehicleSpendingPie(
                          vehicles: _vehicles,
                          spentByVehicle: _spentByVehicle,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Détail par véhicule
                      _SectionTitle('Détail par véhicule'),
                      const SizedBox(height: 12),
                      ...sorted.asMap().entries.map((entry) {
                        final v = entry.value;
                        final originalIndex = _vehicles.indexOf(v);
                        return VehicleStatCard(
                          vehicle: v,
                          colorIndex: originalIndex,
                          totalSpent: _spentByVehicle[v.id!] ?? 0,
                          totalLiters: _litersByVehicle[v.id!] ?? 0,
                          entryCount: _countByVehicle[v.id!] ?? 0,
                          householdTotal: _totalHousehold,
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}

class _HouseholdTotalCard extends StatelessWidget {
  final double total;
  final double totalLiters;
  final int vehicleCount;
  final int entryCount;

  const _HouseholdTotalCard({
    required this.total,
    required this.totalLiters,
    required this.vehicleCount,
    required this.entryCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Dépenses totales du foyer',
                style: TextStyle(
                    color: colors.onPrimaryContainer, fontSize: 13)),
            const SizedBox(height: 6),
            Text(AppFormatters.currency(total),
                style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SmallStat(
                    '${totalLiters.toStringAsFixed(1)} L', 'Litres totaux',
                    colors.onPrimaryContainer),
                _SmallStat('$vehicleCount', 'Véhicule(s)',
                    colors.onPrimaryContainer),
                _SmallStat('$entryCount', 'Relevé(s)',
                    colors.onPrimaryContainer),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _SmallStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 15)),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}

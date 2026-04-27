import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/formatters.dart';
import '../../../data/models/fuel_entry.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/fuel_entry_repository.dart';
import '../../../data/repositories/vehicle_repository.dart';
import '../widgets/consumption_chart.dart';
import '../widgets/monthly_bar_chart.dart';
import '../widgets/price_line_chart.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final _vehicleRepo = VehicleRepository();
  final _entryRepo = FuelEntryRepository();

  List<Vehicle> _vehicles = [];
  List<FuelEntry> _allEntries = [];
  Vehicle? _selectedVehicle;
  bool _loading = true;

  List<FuelEntry> get _entries => _selectedVehicle == null
      ? _allEntries
      : _allEntries
          .where((e) => e.vehicleId == _selectedVehicle!.id)
          .toList();

  double get _totalSpent =>
      _entries.fold(0.0, (s, e) => s + e.totalCost);

  double get _totalLiters =>
      _entries.fold(0.0, (s, e) => s + e.liters);

  double get _avgPrice => _entries.isEmpty
      ? 0.0
      : _entries.fold(0.0, (s, e) => s + e.pricePerLiter) /
          _entries.length;

  List<MapEntry<String, double>> get _monthlyData {
    final now = DateTime.now();
    final map = <String, double>{};
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      map['${m.year}-${m.month.toString().padLeft(2, '0')}'] = 0;
    }
    for (final e in _entries) {
      final key = e.date.substring(0, 7);
      if (map.containsKey(key)) map[key] = map[key]! + e.totalCost;
    }
    return map.entries.toList();
  }

  List<FlSpot> get _priceTrend {
    final sorted = [..._entries]..sort((a, b) => a.date.compareTo(b.date));
    return sorted
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.pricePerLiter))
        .toList();
  }

  // Calcule les points (date, L/100km) par véhicule entre pleins consécutifs
  List<(String, double)> get _consumptionPoints {
    final result = <(String, double)>[];
    // Grouper par véhicule pour conserver la séquence d'odomètre
    final byVehicle = <int, List<FuelEntry>>{};
    for (final e in _entries.where((e) => e.odometer != null)) {
      byVehicle.putIfAbsent(e.vehicleId, () => []).add(e);
    }
    for (final entries in byVehicle.values) {
      entries.sort((a, b) => a.date.compareTo(b.date));
      for (int i = 1; i < entries.length; i++) {
        final prev = entries[i - 1];
        final curr = entries[i];
        final distance = curr.odometer! - prev.odometer!;
        if (distance > 0 && curr.liters > 0) {
          final conso = (curr.liters / distance) * 100;
          if (conso > 0 && conso < 50) result.add((curr.date, conso));
        }
      }
    }
    return result;
  }

  List<MapEntry<String, double>> get _monthlyConsumption {
    final now = DateTime.now();
    final map = <String, List<double>>{};
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      map['${m.year}-${m.month.toString().padLeft(2, '0')}'] = [];
    }
    for (final (date, conso) in _consumptionPoints) {
      final key = date.substring(0, 7);
      if (map.containsKey(key)) map[key]!.add(conso);
    }
    return map.entries.map((e) {
      final avg = e.value.isEmpty
          ? 0.0
          : e.value.reduce((a, b) => a + b) / e.value.length;
      return MapEntry(e.key, avg);
    }).toList();
  }

  List<MapEntry<String, double>> get _weeklyConsumption {
    final now = DateTime.now();
    // Lundi de la semaine courante
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));
    final map = <String, List<double>>{};
    for (int i = 7; i >= 0; i--) {
      final monday = thisMonday.subtract(Duration(days: i * 7));
      final key =
          '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
      map[key] = [];
    }
    for (final (date, conso) in _consumptionPoints) {
      final dt = DateTime.parse(date);
      final monday = dt.subtract(Duration(days: dt.weekday - 1));
      final key =
          '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
      if (map.containsKey(key)) map[key]!.add(conso);
    }
    return map.entries.map((e) {
      final avg = e.value.isEmpty
          ? 0.0
          : e.value.reduce((a, b) => a + b) / e.value.length;
      return MapEntry(e.key, avg);
    }).toList();
  }

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
      _allEntries = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistiques')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allEntries.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun relevé enregistré.\nAjoutez des relevés depuis l\'onglet Véhicules.',
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Filtre véhicule
                      if (_vehicles.length > 1) ...[
                        DropdownButtonFormField<Vehicle?>(
                          value: _selectedVehicle,
                          decoration: const InputDecoration(
                            labelText: 'Véhicule',
                            prefixIcon: Icon(Icons.directions_car),
                          ),
                          items: [
                            const DropdownMenuItem(
                                value: null,
                                child: Text('Tous les véhicules')),
                            ..._vehicles.map((v) => DropdownMenuItem(
                                value: v, child: Text(v.name))),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedVehicle = v),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Cartes résumé
                      _SummaryRow(
                        totalSpent: _totalSpent,
                        totalLiters: _totalLiters,
                        avgPrice: _avgPrice,
                        count: _entries.length,
                      ),
                      const SizedBox(height: 24),

                      // Graphique dépenses mensuelles
                      _SectionTitle('Dépenses mensuelles (\$)'),
                      const SizedBox(height: 8),
                      MonthlyBarChart(data: _monthlyData),
                      const SizedBox(height: 24),

                      // Graphique évolution prix/L
                      if (_entries.length >= 2) ...[
                        _SectionTitle('Évolution du prix au litre (\$/L)'),
                        const SizedBox(height: 8),
                        PriceLineChart(spots: _priceTrend),
                        const SizedBox(height: 24),
                      ],

                      // Graphique consommation L/100km
                      _SectionTitle('Consommation moy. (L/100 km)'),
                      const SizedBox(height: 8),
                      ConsumptionChart(
                        monthlyData: _monthlyConsumption,
                        weeklyData: _weeklyConsumption,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
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

class _SummaryRow extends StatelessWidget {
  final double totalSpent;
  final double totalLiters;
  final double avgPrice;
  final int count;

  const _SummaryRow({
    required this.totalSpent,
    required this.totalLiters,
    required this.avgPrice,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'Total dépensé',
                value: AppFormatters.currency(totalSpent),
                icon: Icons.payments_outlined)),
        const SizedBox(width: 8),
        Expanded(
            child: _StatCard(
                label: 'Litres',
                value: '${totalLiters.toStringAsFixed(1)} L',
                icon: Icons.local_gas_station_outlined)),
        const SizedBox(width: 8),
        Expanded(
            child: _StatCard(
                label: 'Prix moy./L',
                value: AppFormatters.currency(avgPrice),
                icon: Icons.trending_up)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: colors.primary, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: colors.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

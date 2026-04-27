import 'package:flutter/material.dart';
import '../../../core/formatters.dart';
import '../../../data/models/fuel_entry.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/fuel_entry_repository.dart';
import '../../../data/repositories/vehicle_repository.dart';
import '../stats_period.dart';
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
  StatsPeriod _period = StatsPeriod.monthly;
  DateTimeRange? _customRange;
  bool _loading = true;

  List<FuelEntry> get _entries => _selectedVehicle == null
      ? _allEntries
      : _allEntries.where((e) => e.vehicleId == _selectedVehicle!.id).toList();

  // ── Entrées filtrées par date range ou période courante ──────────────
  List<FuelEntry> get _summaryEntries {
    if (_customRange != null) {
      final start = AppFormatters.dateToStorage(_customRange!.start);
      final end = AppFormatters.dateToStorage(_customRange!.end);
      return _entries.where((e) =>
          e.date.compareTo(start) >= 0 && e.date.compareTo(end) <= 0).toList();
    }
    // Période courante (dernier bucket)
    final now = DateTime.now();
    switch (_period) {
      case StatsPeriod.weekly:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final key = _mondayKey(monday);
        return _entries
            .where((e) => _mondayKey(DateTime.parse(e.date)) == key)
            .toList();
      case StatsPeriod.monthly:
        final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        return _entries.where((e) => e.date.startsWith(key)).toList();
      case StatsPeriod.yearly:
        return _entries.where((e) => e.date.startsWith('${now.year}')).toList();
    }
  }

  double get _summarySpent =>
      _summaryEntries.fold(0.0, (s, e) => s + e.totalCost);

  double get _summaryLiters =>
      _summaryEntries.fold(0.0, (s, e) => s + e.liters);

  double get _summaryConsumption =>
      _avgConsumptionFrom(_summaryEntries);

  double _avgConsumptionFrom(List<FuelEntry> entries) {
    final byVehicle = <int, List<FuelEntry>>{};
    for (final e in entries.where((e) => e.odometer != null)) {
      byVehicle.putIfAbsent(e.vehicleId, () => []).add(e);
    }
    final consos = <double>[];
    for (final list in byVehicle.values) {
      list.sort((a, b) => a.date.compareTo(b.date));
      for (int i = 1; i < list.length; i++) {
        final dist = list[i].odometer! - list[i - 1].odometer!;
        if (dist > 0 && list[i].liters > 0) {
          final c = (list[i].liters / dist) * 100;
          if (c > 0 && c < 50) consos.add(c);
        }
      }
    }
    if (consos.isEmpty) return 0;
    return consos.reduce((a, b) => a + b) / consos.length;
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
    );
    if (range != null) setState(() => _customRange = range);
  }

  // ── Helpers période ──────────────────────────────────────────────────
  static String _mondayKey(DateTime dt) {
    final m = dt.subtract(Duration(days: dt.weekday - 1));
    return '${m.year}-${m.month.toString().padLeft(2, '0')}-${m.day.toString().padLeft(2, '0')}';
  }

  List<String> _periodKeys(StatsPeriod p) {
    final now = DateTime.now();
    switch (p) {
      case StatsPeriod.weekly:
        final base = now.subtract(Duration(days: now.weekday - 1));
        return List.generate(8, (i) => _mondayKey(base.subtract(Duration(days: (7 - i) * 7))));
      case StatsPeriod.monthly:
        return List.generate(6, (i) {
          final m = DateTime(now.year, now.month - (5 - i));
          return '${m.year}-${m.month.toString().padLeft(2, '0')}';
        });
      case StatsPeriod.yearly:
        return List.generate(5, (i) => '${now.year - (4 - i)}');
    }
  }

  String _entryKey(String date, StatsPeriod p) {
    switch (p) {
      case StatsPeriod.weekly: return _mondayKey(DateTime.parse(date));
      case StatsPeriod.monthly: return date.substring(0, 7);
      case StatsPeriod.yearly: return date.substring(0, 4);
    }
  }

  // ── Dépenses ─────────────────────────────────────────────────────────
  List<MapEntry<String, double>> _spendingData(StatsPeriod p) {
    final keys = _periodKeys(p);
    final map = {for (final k in keys) k: 0.0};
    for (final e in _entries) {
      final key = _entryKey(e.date, p);
      if (map.containsKey(key)) map[key] = map[key]! + e.totalCost;
    }
    return keys.map((k) => MapEntry(k, map[k]!)).toList();
  }

  // ── Prix moyen/L ─────────────────────────────────────────────────────
  List<MapEntry<String, double>> _priceData(StatsPeriod p) {
    final keys = _periodKeys(p);
    final map = {for (final k in keys) k: <double>[]};
    for (final e in _entries) {
      final key = _entryKey(e.date, p);
      if (map.containsKey(key)) map[key]!.add(e.pricePerLiter);
    }
    return keys.map((k) {
      final vals = map[k]!;
      final avg = vals.isEmpty ? 0.0 : vals.reduce((a, b) => a + b) / vals.length;
      return MapEntry(k, avg);
    }).toList();
  }

  // ── Consommation L/100km ─────────────────────────────────────────────
  List<(String, double)> get _consumptionPoints {
    final result = <(String, double)>[];
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

  List<MapEntry<String, double>> _consumptionData(StatsPeriod p) {
    final keys = _periodKeys(p);
    final map = {for (final k in keys) k: <double>[]};
    for (final (date, conso) in _consumptionPoints) {
      final key = _entryKey(date, p);
      if (map.containsKey(key)) map[key]!.add(conso);
    }
    return keys.map((k) {
      final vals = map[k]!;
      final avg = vals.isEmpty ? 0.0 : vals.reduce((a, b) => a + b) / vals.length;
      return MapEntry(k, avg);
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
                            ..._vehicles.map((v) =>
                                DropdownMenuItem(value: v, child: Text(v.name))),
                          ],
                          onChanged: (v) => setState(() => _selectedVehicle = v),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Toggle période global
                      SegmentedButton<StatsPeriod>(
                        segments: const [
                          ButtonSegment(
                            value: StatsPeriod.weekly,
                            label: Text('Semaine'),
                            icon: Icon(Icons.view_week_outlined),
                          ),
                          ButtonSegment(
                            value: StatsPeriod.monthly,
                            label: Text('Mois'),
                            icon: Icon(Icons.calendar_month_outlined),
                          ),
                          ButtonSegment(
                            value: StatsPeriod.yearly,
                            label: Text('Année'),
                            icon: Icon(Icons.calendar_today_outlined),
                          ),
                        ],
                        selected: {_period},
                        onSelectionChanged: (s) => setState(() {
                          _period = s.first;
                          _customRange = null;
                        }),
                      ),
                      const SizedBox(height: 8),

                      // Sélecteur de plage personnalisée
                      _DateRangeBar(
                        range: _customRange,
                        onPick: _pickDateRange,
                        onClear: () => setState(() => _customRange = null),
                      ),
                      const SizedBox(height: 12),

                      // Cartes résumé (période ou plage courante)
                      _SummaryRow(
                        totalSpent: _summarySpent,
                        totalLiters: _summaryLiters,
                        avgConsumption: _summaryConsumption,
                        period: _customRange == null ? _period : null,
                        customRange: _customRange,
                      ),
                      const SizedBox(height: 24),

                      // Dépenses
                      _SectionTitle('Dépenses (\$)'),
                      const SizedBox(height: 8),
                      MonthlyBarChart(
                        data: _spendingData(_period),
                        period: _period,
                      ),
                      const SizedBox(height: 24),

                      // Prix moyen/L
                      if (_entries.length >= 2) ...[
                        _SectionTitle('Prix moyen au litre (\$/L)'),
                        const SizedBox(height: 8),
                        PriceLineChart(
                          data: _priceData(_period),
                          period: _period,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Consommation L/100km
                      _SectionTitle('Consommation moy. (L/100 km)'),
                      const SizedBox(height: 8),
                      ConsumptionChart(
                        data: _consumptionData(_period),
                        period: _period,
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

class _DateRangeBar extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _DateRangeBar(
      {required this.range, required this.onPick, required this.onClear});

  @override
  Widget build(BuildContext context) {
    if (range == null) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.date_range, size: 18),
        label: const Text('Période personnalisée'),
        onPressed: onPick,
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Du ${AppFormatters.dateToDisplay(AppFormatters.dateToStorage(range!.start))}'
              ' au ${AppFormatters.dateToDisplay(AppFormatters.dateToStorage(range!.end))}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double totalSpent;
  final double totalLiters;
  final double avgConsumption;
  final StatsPeriod? period;
  final DateTimeRange? customRange;

  const _SummaryRow({
    required this.totalSpent,
    required this.totalLiters,
    required this.avgConsumption,
    this.period,
    this.customRange,
  });

  String get _label {
    if (customRange != null) {
      return 'Du ${AppFormatters.dateToDisplay(AppFormatters.dateToStorage(customRange!.start))}'
          ' au ${AppFormatters.dateToDisplay(AppFormatters.dateToStorage(customRange!.end))}';
    }
    switch (period) {
      case StatsPeriod.weekly: return 'Cette semaine';
      case StatsPeriod.monthly: return 'Ce mois-ci';
      case StatsPeriod.yearly: return 'Cette année';
      case null: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Dépenses',
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
                    label: 'Conso. moy.',
                    value: avgConsumption == 0
                        ? '— L/100'
                        : '${avgConsumption.toStringAsFixed(1)} L/100',
                    icon: Icons.speed_outlined)),
          ],
        ),
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

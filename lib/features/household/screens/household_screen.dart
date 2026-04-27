import 'package:flutter/material.dart';
import '../../../core/formatters.dart';
import '../../../data/models/fuel_entry.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/fuel_entry_repository.dart';
import '../../../data/repositories/vehicle_repository.dart';
import '../../stats/stats_period.dart';
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

  List<Vehicle> _allVehicles = [];
  List<FuelEntry> _allEntries = [];
  Set<int> _selectedVehicleIds = {};  // vide = tous sélectionnés
  StatsPeriod _period = StatsPeriod.monthly;
  DateTimeRange? _customRange;
  bool _loading = true;

  // ── Filtres ───────────────────────────────────────────────────────────
  List<Vehicle> get _vehicles => _selectedVehicleIds.isEmpty
      ? _allVehicles
      : _allVehicles.where((v) => _selectedVehicleIds.contains(v.id)).toList();

  List<FuelEntry> get _entries {
    final vehicleIds = _vehicles.map((v) => v.id!).toSet();
    var entries = _allEntries.where((e) => vehicleIds.contains(e.vehicleId));

    if (_customRange != null) {
      final start = AppFormatters.dateToStorage(_customRange!.start);
      final end = AppFormatters.dateToStorage(_customRange!.end);
      entries = entries.where((e) =>
          e.date.compareTo(start) >= 0 && e.date.compareTo(end) <= 0);
    } else {
      final now = DateTime.now();
      switch (_period) {
        case StatsPeriod.weekly:
          final monday = now.subtract(Duration(days: now.weekday - 1));
          final mondayKey = _mondayKey(monday);
          entries = entries.where(
              (e) => _mondayKey(DateTime.parse(e.date)) == mondayKey);
        case StatsPeriod.monthly:
          final key =
              '${now.year}-${now.month.toString().padLeft(2, '0')}';
          entries = entries.where((e) => e.date.startsWith(key));
        case StatsPeriod.yearly:
          entries = entries.where((e) => e.date.startsWith('${now.year}'));
      }
    }
    return entries.toList();
  }

  static String _mondayKey(DateTime dt) {
    final m = dt.subtract(Duration(days: dt.weekday - 1));
    return '${m.year}-${m.month.toString().padLeft(2, '0')}-${m.day.toString().padLeft(2, '0')}';
  }

  // ── Agrégats ─────────────────────────────────────────────────────────
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

  double get _totalSpent =>
      _spentByVehicle.values.fold(0.0, (s, v) => s + v);
  double get _totalLiters =>
      _litersByVehicle.values.fold(0.0, (s, v) => s + v);

  String get _periodLabel {
    if (_customRange != null) {
      return 'Du ${AppFormatters.dateToDisplay(AppFormatters.dateToStorage(_customRange!.start))}'
          ' au ${AppFormatters.dateToDisplay(AppFormatters.dateToStorage(_customRange!.end))}';
    }
    switch (_period) {
      case StatsPeriod.weekly: return 'Cette semaine';
      case StatsPeriod.monthly: return 'Ce mois-ci';
      case StatsPeriod.yearly: return 'Cette année';
    }
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
      _allVehicles = vehicles;
      _allEntries = entries;
      _loading = false;
    });
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _customRange,
      locale: const Locale('fr'),
    );
    if (range != null) setState(() => _customRange = range);
  }

  Future<void> _openVehicleFilter() async {
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) => _VehicleFilterDialog(
        vehicles: _allVehicles,
        selected: _selectedVehicleIds,
      ),
    );
    if (result != null) setState(() => _selectedVehicleIds = result);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [..._vehicles]..sort((a, b) =>
        (_spentByVehicle[b.id!] ?? 0)
            .compareTo(_spentByVehicle[a.id!] ?? 0));

    final filterCount = _selectedVehicleIds.length;
    final filterLabel = filterCount == 0
        ? 'Tous (${_allVehicles.length})'
        : '$filterCount / ${_allVehicles.length}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flotte'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.directions_car, size: 18),
            label: Text(filterLabel),
            onPressed: _allVehicles.length > 1 ? _openVehicleFilter : null,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _allVehicles.isEmpty
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
                      // Toggle période
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

                      // Plage personnalisée
                      _customRange == null
                          ? OutlinedButton.icon(
                              icon: const Icon(Icons.date_range, size: 18),
                              label: const Text('Période personnalisée'),
                              onPressed: _pickDateRange,
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.date_range, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _periodLabel,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => setState(
                                        () => _customRange = null),
                                  ),
                                ],
                              ),
                            ),
                      const SizedBox(height: 16),

                      // Carte total flotte
                      _FlotteTotalCard(
                        label: _periodLabel,
                        total: _totalSpent,
                        totalLiters: _totalLiters,
                        vehicleCount: _vehicles.length,
                        entryCount: _entries.length,
                      ),
                      const SizedBox(height: 24),

                      // Camembert répartition
                      if (_vehicles.length > 1 && _totalSpent > 0) ...[
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
                      if (_entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Aucun relevé pour cette période.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                          ),
                        )
                      else
                        ...sorted.asMap().entries.map((entry) {
                          final v = entry.value;
                          final originalIndex = _allVehicles.indexOf(v);
                          return VehicleStatCard(
                            vehicle: v,
                            colorIndex: originalIndex,
                            totalSpent: _spentByVehicle[v.id!] ?? 0,
                            totalLiters: _litersByVehicle[v.id!] ?? 0,
                            entryCount: _countByVehicle[v.id!] ?? 0,
                            householdTotal: _totalSpent,
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

// ── Dialogue filtre véhicules ─────────────────────────────────────────
class _VehicleFilterDialog extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Set<int> selected;

  const _VehicleFilterDialog(
      {required this.vehicles, required this.selected});

  @override
  State<_VehicleFilterDialog> createState() => _VehicleFilterDialogState();
}

class _VehicleFilterDialogState extends State<_VehicleFilterDialog> {
  late Set<int> _current;

  @override
  void initState() {
    super.initState();
    _current = Set.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtrer les véhicules'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Tous les véhicules',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              value: _current.isEmpty,
              onChanged: (_) => setState(() => _current.clear()),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Divider(),
            ...widget.vehicles.map((v) => CheckboxListTile(
                  title: Text(v.name),
                  subtitle:
                      Text('${v.brand} ${v.model} • ${v.licensePlate}'),
                  value: _current.isEmpty || _current.contains(v.id),
                  onChanged: (checked) {
                    setState(() {
                      if (_current.isEmpty) {
                        // Passer de "tous" à sélection individuelle
                        _current = widget.vehicles
                            .map((x) => x.id!)
                            .toSet();
                      }
                      if (checked == true) {
                        _current.add(v.id!);
                      } else {
                        _current.remove(v.id!);
                      }
                      // Si tout coché, revenir à "tous"
                      if (_current.length == widget.vehicles.length) {
                        _current.clear();
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                )),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _current),
            child: const Text('Appliquer')),
      ],
    );
  }
}

// ── Widgets locaux ────────────────────────────────────────────────────
class _FlotteTotalCard extends StatelessWidget {
  final String label;
  final double total;
  final double totalLiters;
  final int vehicleCount;
  final int entryCount;

  const _FlotteTotalCard({
    required this.label,
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
            Text(label,
                style:
                    TextStyle(color: colors.onPrimaryContainer, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Dépenses de la flotte',
                style:
                    TextStyle(color: colors.onPrimaryContainer, fontSize: 13)),
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
                _SmallStat('${totalLiters.toStringAsFixed(1)} L',
                    'Litres', colors.onPrimaryContainer),
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

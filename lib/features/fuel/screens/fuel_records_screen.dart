import 'package:flutter/material.dart';
import '../../../core/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/fuel_entry.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/fuel_entry_repository.dart';
import '../widgets/fuel_entry_card.dart';
import 'fuel_entry_form_screen.dart';

class FuelRecordsScreen extends StatefulWidget {
  final Vehicle vehicle;

  const FuelRecordsScreen({super.key, required this.vehicle});

  @override
  State<FuelRecordsScreen> createState() => _FuelRecordsScreenState();
}

class _FuelRecordsScreenState extends State<FuelRecordsScreen> {
  final _repo = FuelEntryRepository();
  List<FuelEntry> _entries = [];
  double _totalSpent = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await _repo.getByVehicle(widget.vehicle.id!);
    final total = await _repo.getTotalCostByVehicle(widget.vehicle.id!);
    if (!mounted) return;
    setState(() {
      _entries = entries;
      _totalSpent = total;
      _loading = false;
    });
  }

  Future<void> _openForm({FuelEntry? entry}) async {
    final isEdit = entry != null;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            FuelEntryFormScreen(vehicle: widget.vehicle, entry: entry),
      ),
    );
    if (result == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEdit ? 'Relevé modifié' : 'Relevé enregistré'),
        ));
      }
    }
  }

  Future<void> _confirmDelete(FuelEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le relevé'),
        content: Text(
            'Supprimer le relevé du ${AppFormatters.dateToDisplay(entry.date)} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repo.delete(entry.id!);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relevé supprimé')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle.name),
        subtitle: Text('${widget.vehicle.brand} ${widget.vehicle.model}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_entries.isNotEmpty)
                  _SummaryBanner(
                      count: _entries.length, totalSpent: _totalSpent),
                Expanded(
                  child: _entries.isEmpty
                      ? const EmptyState(
                          icon: Icons.local_gas_station_outlined,
                          message: 'Aucun relevé pour ce véhicule',
                          hint:
                              'Appuyez sur + pour enregistrer un plein.',
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            itemCount: _entries.length,
                            itemBuilder: (_, i) => FuelEntryCard(
                              entry: _entries[i],
                              onEdit: () => _openForm(entry: _entries[i]),
                              onDelete: () => _confirmDelete(_entries[i]),
                            ),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Ajouter un relevé',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final int count;
  final double totalSpent;

  const _SummaryBanner({required this.count, required this.totalSpent});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: colors.primaryContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Relevés', value: '$count'),
          _Stat(
              label: 'Total dépensé',
              value: AppFormatters.currency(totalSpent)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colors.onPrimaryContainer)),
        Text(label,
            style:
                TextStyle(fontSize: 12, color: colors.onPrimaryContainer)),
      ],
    );
  }
}

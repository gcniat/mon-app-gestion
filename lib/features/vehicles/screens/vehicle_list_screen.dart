import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/vehicle_repository.dart';
import '../widgets/vehicle_card.dart';
import 'vehicle_form_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final _repo = VehicleRepository();
  List<Vehicle> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vehicles = await _repo.getAll();
    if (!mounted) return;
    setState(() {
      _vehicles = vehicles;
      _loading = false;
    });
  }

  Future<void> _openForm({Vehicle? vehicle}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VehicleFormScreen(vehicle: vehicle)),
    );
    if (result == true) _load();
  }

  Future<void> _confirmDelete(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le véhicule'),
        content: Text(
            'Supprimer "${vehicle.name}" et tous ses relevés de carburant ?'),
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
      await _repo.delete(vehicle.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun véhicule.\nAppuyez sur + pour en ajouter un.',
                    textAlign: TextAlign.center,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _vehicles.length,
                    itemBuilder: (_, i) => VehicleCard(
                      vehicle: _vehicles[i],
                      onTap: () {}, // step 3 — saisie carburant
                      onEdit: () => _openForm(vehicle: _vehicles[i]),
                      onDelete: () => _confirmDelete(_vehicles[i]),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Ajouter un véhicule',
        child: const Icon(Icons.add),
      ),
    );
  }
}

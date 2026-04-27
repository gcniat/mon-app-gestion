import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/vehicle_repository.dart';
import '../../fuel/screens/fuel_records_screen.dart';
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
    final isEdit = vehicle != null;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VehicleFormScreen(vehicle: vehicle)),
    );
    if (result == true) {
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEdit ? 'Véhicule modifié' : 'Véhicule ajouté'),
        ));
      }
    }
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
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Véhicule supprimé')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _vehicles.isEmpty
              ? const EmptyState(
                  icon: Icons.directions_car_outlined,
                  message: 'Aucun véhicule enregistré',
                  hint: 'Appuyez sur + pour ajouter votre premier véhicule.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _vehicles.length,
                    itemBuilder: (_, i) => VehicleCard(
                      vehicle: _vehicles[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FuelRecordsScreen(vehicle: _vehicles[i]),
                        ),
                      ),
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

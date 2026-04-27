import 'package:flutter/material.dart';
import '../../../core/formatters.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/vehicle_repository.dart';

class VehicleFormScreen extends StatefulWidget {
  final Vehicle? vehicle;

  const VehicleFormScreen({super.key, this.vehicle});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = VehicleRepository();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _plateCtrl;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.vehicle?.name ?? '');
    _brandCtrl = TextEditingController(text: widget.vehicle?.brand ?? '');
    _modelCtrl = TextEditingController(text: widget.vehicle?.model ?? '');
    _plateCtrl = TextEditingController(text: widget.vehicle?.licensePlate ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Champ requis' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = AppFormatters.dateToStorage(DateTime.now());
    final vehicle = Vehicle(
      id: widget.vehicle?.id,
      name: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      licensePlate: _plateCtrl.text.trim().toUpperCase(),
      createdAt: widget.vehicle?.createdAt ?? now,
    );

    if (_isEditing) {
      await _repo.update(vehicle);
    } else {
      await _repo.insert(vehicle);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le véhicule' : 'Ajouter un véhicule'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Nom du véhicule *', prefixIcon: Icon(Icons.label)),
              textCapitalization: TextCapitalization.words,
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandCtrl,
              decoration: const InputDecoration(
                  labelText: 'Marque *', prefixIcon: Icon(Icons.business)),
              textCapitalization: TextCapitalization.words,
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelCtrl,
              decoration: const InputDecoration(
                  labelText: 'Modèle *',
                  prefixIcon: Icon(Icons.directions_car)),
              textCapitalization: TextCapitalization.words,
              validator: _required,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plateCtrl,
              decoration: const InputDecoration(
                  labelText: 'Plaque d\'immatriculation *',
                  prefixIcon: Icon(Icons.pin)),
              textCapitalization: TextCapitalization.characters,
              validator: _required,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.save : Icons.add),
              label: Text(_isEditing
                  ? 'Enregistrer les modifications'
                  : 'Ajouter le véhicule'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/formatters.dart';
import '../../../data/models/fuel_entry.dart';
import '../../../data/models/vehicle.dart';
import '../../../data/repositories/fuel_entry_repository.dart';

class FuelEntryFormScreen extends StatefulWidget {
  final Vehicle vehicle;
  final FuelEntry? entry;

  const FuelEntryFormScreen({super.key, required this.vehicle, this.entry});

  @override
  State<FuelEntryFormScreen> createState() => _FuelEntryFormScreenState();
}

class _FuelEntryFormScreenState extends State<FuelEntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = FuelEntryRepository();

  late DateTime _selectedDate;
  late final TextEditingController _litersCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _totalCtrl;
  late final TextEditingController _odometerCtrl;
  late final TextEditingController _notesCtrl;

  bool _totalManuallyEdited = false;
  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _selectedDate = e != null
        ? AppFormatters.storageToDate(e.date)
        : DateTime.now();
    _litersCtrl = TextEditingController(
        text: e != null ? e.liters.toStringAsFixed(2) : '');
    _priceCtrl = TextEditingController(
        text: e != null ? e.pricePerLiter.toStringAsFixed(2) : '');
    _totalCtrl = TextEditingController(
        text: e != null ? e.totalCost.toStringAsFixed(2) : '');
    _odometerCtrl = TextEditingController(
        text: e?.odometer?.toString() ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');

    _litersCtrl.addListener(_autoCalcTotal);
    _priceCtrl.addListener(_autoCalcTotal);
  }

  @override
  void dispose() {
    _litersCtrl.dispose();
    _priceCtrl.dispose();
    _totalCtrl.dispose();
    _odometerCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _autoCalcTotal() {
    if (_totalManuallyEdited) return;
    final liters = double.tryParse(_litersCtrl.text);
    final price = double.tryParse(_priceCtrl.text);
    if (liters != null && price != null) {
      _totalCtrl.text = (liters * price).toStringAsFixed(2);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String? _requiredNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Champ requis';
    if (double.tryParse(v) == null) return 'Nombre invalide';
    if (double.parse(v) <= 0) return 'Doit être supérieur à 0';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = AppFormatters.dateToStorage(DateTime.now());
    final entry = FuelEntry(
      id: widget.entry?.id,
      vehicleId: widget.vehicle.id!,
      date: AppFormatters.dateToStorage(_selectedDate),
      liters: double.parse(_litersCtrl.text),
      pricePerLiter: double.parse(_priceCtrl.text),
      totalCost: double.parse(_totalCtrl.text),
      odometer: _odometerCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_odometerCtrl.text.trim()),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: widget.entry?.createdAt ?? now,
    );

    if (_isEditing) {
      await _repo.update(entry);
    } else {
      await _repo.insert(entry);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le relevé' : 'Nouveau relevé'),
        subtitle: Text(widget.vehicle.name),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Date
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date *',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(AppFormatters.dateToDisplay(
                    AppFormatters.dateToStorage(_selectedDate))),
              ),
            ),
            const SizedBox(height: 16),

            // Litres
            TextFormField(
              controller: _litersCtrl,
              decoration: const InputDecoration(
                labelText: 'Litres *',
                prefixIcon: Icon(Icons.local_gas_station),
                suffixText: 'L',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              ],
              validator: _requiredNumber,
            ),
            const SizedBox(height: 16),

            // Prix par litre
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Prix par litre *',
                prefixIcon: Icon(Icons.attach_money),
                prefixText: '\$ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              ],
              validator: _requiredNumber,
            ),
            const SizedBox(height: 16),

            // Coût total (auto-calculé)
            TextFormField(
              controller: _totalCtrl,
              decoration: InputDecoration(
                labelText: 'Coût total *',
                prefixIcon: const Icon(Icons.receipt),
                prefixText: '\$ ',
                suffixIcon: _totalManuallyEdited
                    ? IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Recalculer automatiquement',
                        onPressed: () {
                          setState(() => _totalManuallyEdited = false);
                          _autoCalcTotal();
                        },
                      )
                    : const Tooltip(
                        message: 'Calculé automatiquement',
                        child: Icon(Icons.calculate, color: Colors.grey),
                      ),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              ],
              onChanged: (_) =>
                  setState(() => _totalManuallyEdited = true),
              validator: _requiredNumber,
            ),
            const SizedBox(height: 16),

            // Kilométrage (optionnel)
            TextFormField(
              controller: _odometerCtrl,
              decoration: const InputDecoration(
                labelText: 'Kilométrage (optionnel)',
                prefixIcon: Icon(Icons.speed),
                suffixText: 'km',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Notes (optionnel)
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                prefixIcon: Icon(Icons.notes),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.save : Icons.add),
              label: Text(_isEditing
                  ? 'Enregistrer les modifications'
                  : 'Enregistrer le relevé'),
            ),
          ],
        ),
      ),
    );
  }
}

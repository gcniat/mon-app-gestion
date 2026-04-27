import 'package:flutter/material.dart';
import '../../../core/models/app_currency.dart';
import '../../../core/services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _prefs = PreferencesService();

  @override
  Widget build(BuildContext context) {
    final current = _prefs.currency;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          const _SectionHeader('Monnaie d\'affichage'),
          ...AppCurrency.all.map(
            (c) => RadioListTile<AppCurrency>(
              value: c,
              groupValue: current,
              title: Text(c.name),
              secondary: Container(
                width: 48,
                alignment: Alignment.center,
                child: Text(
                  c.symbol,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              onChanged: (val) async {
                if (val != null) {
                  await _prefs.setCurrency(val);
                  if (!mounted) return;
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Monnaie changée : ${val.symbol} (${val.name})')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Note : le changement de monnaie est pour l\'affichage uniquement. '
              'Aucune conversion de devise n\'est effectuée.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

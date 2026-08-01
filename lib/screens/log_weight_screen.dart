import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pet.dart';
import '../providers/health_log_provider.dart';
import '../providers/pet_provider.dart';

class LogWeightScreen extends StatefulWidget {
  const LogWeightScreen({super.key});
  @override
  State<LogWeightScreen> createState() => _LogWeightScreenState();
}

class _LogWeightScreenState extends State<LogWeightScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weight = TextEditingController();
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pet = context.read<PetProvider>().pet;
    if (pet?.currentWeightKg != null) {
      _weight.text = pet!.currentWeightKg!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _weight.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save(Pet pet) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final w = double.parse(_weight.text.trim().replaceAll(',', '.'));
    await context.read<HealthLogProvider>().addWeight(
          petId: pet.id,
          kg: w,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    await context.read<PetProvider>().setCurrentWeight(w);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pet = (ModalRoute.of(context)!.settings.arguments as Pet?) ??
        context.read<PetProvider>().pet!;
    return Scaffold(
      appBar: AppBar(title: Text('Log weight · ${pet.name}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _weight,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monitor_weight_outlined),
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                if (n == null || n <= 0) return 'Enter a positive number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. before meal, after vet check…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: Text(_saving ? 'Saving…' : 'Save weight'),
              onPressed: _saving ? null : () => _save(pet),
            ),
          ],
        ),
      ),
    );
  }
}

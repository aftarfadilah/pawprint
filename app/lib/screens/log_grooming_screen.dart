import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pet.dart';
import '../providers/health_log_provider.dart';
import '../providers/pet_provider.dart';

class LogGroomingScreen extends StatefulWidget {
  const LogGroomingScreen({super.key});
  @override
  State<LogGroomingScreen> createState() => _LogGroomingScreenState();
}

class _LogGroomingScreenState extends State<LogGroomingScreen> {
  String _type = 'Bath';
  final _notes = TextEditingController();
  bool _saving = false;

  static const List<String> _types = ['Bath', 'Brush', 'Nails', 'Ears', 'Teeth', 'Other'];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save(Pet pet) async {
    setState(() => _saving = true);
    await context.read<HealthLogProvider>().addGrooming(
          petId: pet.id,
          type: _type,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pet = (ModalRoute.of(context)!.settings.arguments as Pet?) ??
        context.read<PetProvider>().pet!;
    return Scaffold(
      appBar: AppBar(title: Text('Log grooming · ${pet.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _types)
                ChoiceChip(
                  label: Text(t),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: Text(_saving ? 'Saving…' : 'Save grooming log'),
            onPressed: _saving ? null : () => _save(pet),
          ),
        ],
      ),
    );
  }
}

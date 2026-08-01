import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pet.dart';
import '../providers/health_log_provider.dart';
import '../providers/pet_provider.dart';

class LogMedicineScreen extends StatefulWidget {
  const LogMedicineScreen({super.key});
  @override
  State<LogMedicineScreen> createState() => _LogMedicineScreenState();
}

class _LogMedicineScreenState extends State<LogMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _dosage = TextEditingController();
  final _frequency = TextEditingController();
  final _notes = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    _frequency.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final init = (start ? _start : _end) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _save(Pet pet) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<HealthLogProvider>().addMedicine(
          petId: pet.id,
          name: _name.text.trim(),
          dosage: _dosage.text.trim().isEmpty ? null : _dosage.text.trim(),
          frequency: _frequency.text.trim().isEmpty ? null : _frequency.text.trim(),
          startDate: _start,
          endDate: _end,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pet = (ModalRoute.of(context)!.settings.arguments as Pet?) ??
        context.read<PetProvider>().pet!;
    return Scaffold(
      appBar: AppBar(title: Text('Log medicine · ${pet.name}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Medicine name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dosage,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g. 5mg, 0.5ml)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency (e.g. twice a day)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_start == null
                        ? 'Start date'
                        : 'Start: ${_fmt(_start!)}'),
                    onPressed: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_end == null
                        ? 'End date'
                        : 'End: ${_fmt(_end!)}'),
                    onPressed: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
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
              label: Text(_saving ? 'Saving…' : 'Save medicine log'),
              onPressed: _saving ? null : () => _save(pet),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

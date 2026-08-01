import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pet.dart';
import '../models/reminder.dart';
import '../providers/pet_provider.dart';
import '../providers/reminder_provider.dart';

class ReminderEditScreen extends StatefulWidget {
  final Reminder? reminder;
  const ReminderEditScreen({super.key, this.reminder});

  @override
  State<ReminderEditScreen> createState() => _ReminderEditScreenState();
}

class _ReminderEditScreenState extends State<ReminderEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  ReminderType _type = ReminderType.vaccine;
  DateTime _due = DateTime.now().add(const Duration(days: 7));
  int _repeatDays = 0;
  bool _saving = false;

  bool get _isNew => widget.reminder == null;

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    if (r != null) {
      _title.text = r.title;
      _notes.text = r.notes ?? '';
      _type = r.type;
      _due = r.dueDate;
      _repeatDays = r.repeatDays;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_due),
      );
      setState(() {
        _due = DateTime(
            picked.year, picked.month, picked.day, t?.hour ?? 9, t?.minute ?? 0);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final pet = context.read<PetProvider>().pet;
    if (pet == null) return;
    final prov = context.read<ReminderProvider>();
    if (_isNew) {
      await prov.add(
        petId: pet.id,
        title: _title.text,
        dueDate: _due,
        type: _type,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        repeatDays: _repeatDays,
      );
    } else {
      final updated = widget.reminder!.copyWith(
        title: _title.text,
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        type: _type,
        dueDate: _due,
        repeatDays: _repeatDays,
      );
      await prov.update(updated);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final r = widget.reminder;
    if (r == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete reminder?'),
        content: Text('“${r.title}” will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ReminderProvider>().delete(r.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New reminder' : 'Edit reminder'),
        actions: [
          if (!_isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                hintText: 'e.g. Annual vaccine, Flea treatment',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in ReminderType.values)
                  ChoiceChip(
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant),
              ),
              title: const Text('Due date & time'),
              subtitle: Text(_due.toString().substring(0, 16)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _repeatDays,
              decoration: const InputDecoration(
                labelText: 'Repeat',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('One time')),
                DropdownMenuItem(value: 7, child: Text('Every 7 days')),
                DropdownMenuItem(value: 14, child: Text('Every 14 days')),
                DropdownMenuItem(value: 30, child: Text('Every 30 days')),
                DropdownMenuItem(value: 90, child: Text('Every 90 days')),
                DropdownMenuItem(value: 180, child: Text('Every 6 months')),
                DropdownMenuItem(value: 365, child: Text('Every year')),
              ],
              onChanged: (v) => setState(() => _repeatDays = v ?? 0),
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
              label: Text(_saving ? 'Saving…' : 'Save'),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

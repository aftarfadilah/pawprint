import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/reminder.dart';
import '../providers/pet_provider.dart';
import '../providers/reminder_provider.dart';
import '../widgets/empty_state.dart';
import 'reminder_edit_screen.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetProvider>().pet;
    final scheme = Theme.of(context).colorScheme;
    if (pet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reminders')),
        body: const EmptyState(
          icon: Icons.pets,
          title: 'No pet yet',
          message: 'Add a pet to start tracking reminders.',
        ),
      );
    }

    final all = context.watch<ReminderProvider>().all;
    final overdue = all.where((r) => r.isOverdue).toList();
    final upcoming = all
        .where((r) => !r.completed && !r.isOverdue)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final completed = all.where((r) => r.completed).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New'),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const ReminderEditScreen(),
          ));
        },
      ),
      body: all.isEmpty
          ? EmptyState(
              icon: Icons.event_note_outlined,
              title: 'No reminders yet',
              message:
                  'Track vaccines, medications, grooming, and vet visits so nothing slips.',
              action: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add reminder'),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ReminderEditScreen(),
                  ));
                },
              ),
            )
          : ListView(
              children: [
                if (overdue.isNotEmpty) ...[
                  _SectionHeader(title: 'Overdue', color: scheme.error),
                  for (final r in overdue) _ReminderRow(reminder: r),
                ],
                if (upcoming.isNotEmpty) ...[
                  _SectionHeader(title: 'Upcoming'),
                  for (final r in upcoming) _ReminderRow(reminder: r),
                ],
                if (completed.isNotEmpty) ...[
                  _SectionHeader(title: 'Completed'),
                  for (final r in completed) _ReminderRow(reminder: r),
                ],
                const SizedBox(height: 80),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color? color;
  const _SectionHeader({required this.title, this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final Reminder reminder;
  const _ReminderRow({required this.reminder});

  IconData _icon(ReminderType t) {
    switch (t) {
      case ReminderType.vaccine:
        return Icons.vaccines_outlined;
      case ReminderType.medication:
        return Icons.medication_outlined;
      case ReminderType.grooming:
        return Icons.content_cut;
      case ReminderType.vet:
        return Icons.local_hospital_outlined;
      case ReminderType.other:
        return Icons.event_note_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = reminder;
    final subtitleParts = <String>[
      r.type.label,
      DateFormat('MMM d, y · h:mm a').format(r.dueDate),
      if (r.repeatDays > 0) 'repeats every ${r.repeatDays}d',
    ];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(_icon(r.type),
            color: r.completed ? scheme.outline : scheme.primary),
        title: Text(
          r.title,
          style: TextStyle(
            decoration: r.completed ? TextDecoration.lineThrough : null,
            color: r.completed ? scheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: Text(subtitleParts.join(' · ')),
        trailing: Checkbox(
          value: r.completed,
          onChanged: (_) =>
              context.read<ReminderProvider>().toggleComplete(r.id),
        ),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ReminderEditScreen(reminder: r),
          ));
        },
      ),
    );
  }
}

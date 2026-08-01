import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/health_log.dart';
import '../models/pet.dart';
import '../models/reminder.dart';
import '../providers/health_log_provider.dart';
import '../providers/pet_provider.dart';
import '../providers/reminder_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/health_log_tile.dart';
import '../widgets/pet_avatar.dart';
import 'onboarding_screen.dart';
import 'reminder_edit_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final petProv = context.watch<PetProvider>();
    final pet = petProv.pet;
    final scheme = Theme.of(context).colorScheme;

    if (pet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('PawPrint')),
        body: EmptyState(
          icon: Icons.pets,
          title: 'Welcome to PawPrint',
          message:
              'Set up your pet’s profile to start tracking health, weight, photos, and more.',
          action: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add your pet'),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const OnboardingScreen(),
              ));
            },
          ),
        ),
      );
    }

    final logs = context.watch<HealthLogProvider>().recent(limit: 5);
    final reminders =
        context.watch<ReminderProvider>().upcoming(windowDays: 14);
    final overdue = context.watch<ReminderProvider>().overdue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PawPrint'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _PetHeader(pet: pet),
          if (overdue.isNotEmpty) _OverdueCard(reminders: overdue),
          const SizedBox(height: 8),
          _QuickActionsRow(pet: pet),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Upcoming',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const ReminderEditScreen(),
                    ));
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          if (reminders.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('No upcoming reminders in the next 2 weeks.',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            )
          else
            ...reminders.take(3).map((r) => _ReminderTile(reminder: r)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Recent activity',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No activity yet. Use the Log tab to add some.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            )
          else
            ...logs.map((l) => HealthLogTile(log: l)),
        ],
      ),
    );
  }
}

class _PetHeader extends StatelessWidget {
  final Pet pet;
  const _PetHeader({required this.pet});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          PetAvatar(pet: pet, size: 72),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('${pet.species}${pet.breed == null ? '' : ' · ${pet.breed}'}',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (pet.ageLabel.isNotEmpty)
                      _Chip(icon: Icons.cake_outlined, label: pet.ageLabel),
                    if (pet.currentWeightKg != null)
                      _Chip(
                        icon: Icons.monitor_weight_outlined,
                        label: '${pet.currentWeightKg!.toStringAsFixed(1)} kg',
                      ),
                    if (pet.sex != null)
                      _Chip(icon: Icons.pets, label: pet.sex!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final Pet pet;
  const _QuickActionsRow({required this.pet});

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.monitor_weight_outlined,
        label: 'Weight',
        onTap: () => Navigator.of(context).pushNamed('/log/weight', arguments: pet),
      ),
      _QuickAction(
        icon: Icons.medication_outlined,
        label: 'Medicine',
        onTap: () => Navigator.of(context).pushNamed('/log/medicine', arguments: pet),
      ),
      _QuickAction(
        icon: Icons.photo_camera_outlined,
        label: 'Photo',
        onTap: () => Navigator.of(context).pushNamed('/log/photo', arguments: pet),
      ),
      _QuickAction(
        icon: Icons.content_cut,
        label: 'Grooming',
        onTap: () => Navigator.of(context).pushNamed('/log/grooming', arguments: pet),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final a in actions) ...[
            Expanded(child: _QuickActionButton(action: a)),
            if (a != actions.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _QuickAction({required this.icon, required this.label, required this.onTap});
}

class _QuickActionButton extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionButton({required this.action});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(action.icon, color: scheme.primary),
              const SizedBox(height: 6),
              Text(action.label,
                  style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverdueCard extends StatelessWidget {
  final List<Reminder> reminders;
  const _OverdueCard({required this.reminders});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${reminders.length} overdue reminder${reminders.length == 1 ? '' : 's'}',
              style: TextStyle(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  const _ReminderTile({required this.reminder});
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = reminder.dueDate.difference(DateTime.now()).inDays;
    final when = days == 0
        ? 'Today'
        : days == 1
            ? 'Tomorrow'
            : days < 0
                ? '${-days}d overdue'
                : 'in ${days}d';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(_iconFor(reminder.type), color: scheme.primary),
        title: Text(reminder.title),
        subtitle: Text('${reminder.type.label} · ${DateFormat('MMM d').format(reminder.dueDate)} · $when'),
        trailing: Checkbox(
          value: reminder.completed,
          onChanged: (_) => context.read<ReminderProvider>().toggleComplete(reminder.id),
        ),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ReminderEditScreen(reminder: reminder),
          ));
        },
      ),
    );
  }

  IconData _iconFor(ReminderType t) {
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
}

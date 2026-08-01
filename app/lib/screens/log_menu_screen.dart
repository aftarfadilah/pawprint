import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pet.dart';
import '../providers/pet_provider.dart';

class LogMenuScreen extends StatelessWidget {
  const LogMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pet = context.watch<PetProvider>().pet;
    if (pet == null) {
      return const Scaffold(
        body: Center(child: Text('Add a pet first.')),
      );
    }

    final entries = <_LogEntry>[
      _LogEntry(
        icon: Icons.monitor_weight_outlined,
        label: 'Log weight',
        color: Colors.teal,
        route: '/log/weight',
      ),
      _LogEntry(
        icon: Icons.medication_outlined,
        label: 'Log medicine',
        color: Colors.deepPurple,
        route: '/log/medicine',
      ),
      _LogEntry(
        icon: Icons.photo_camera_outlined,
        label: 'Log photo',
        color: Colors.indigo,
        route: '/log/photo',
      ),
      _LogEntry(
        icon: Icons.content_cut,
        label: 'Log grooming',
        color: Colors.pink,
        route: '/log/grooming',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Log')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (final e in entries)
            _LogCard(
              entry: e,
              onTap: () =>
                  Navigator.of(context).pushNamed(e.route, arguments: pet),
            ),
        ],
      ),
    );
  }
}

class _LogEntry {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  _LogEntry({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}

class _LogCard extends StatelessWidget {
  final _LogEntry entry;
  final VoidCallback onTap;
  const _LogCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: entry.color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(entry.icon, color: entry.color, size: 40),
              const SizedBox(height: 12),
              Text(
                entry.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Convenience arg type so screens can accept Pet via Navigator.
class PetArg {
  final Pet pet;
  const PetArg(this.pet);
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/health_log_provider.dart';
import 'health_log_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logCount = context.watch<HealthLogProvider>().all.length;
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          _Tile(
            icon: Icons.event_note_outlined,
            title: 'Reminders',
            subtitle: 'Vaccines, medications, vet visits',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const RemindersScreen(),
            )),
          ),
          _Tile(
            icon: Icons.history,
            title: 'Health log',
            subtitle: '$logCount entries',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const HealthLogScreen(),
            )),
          ),
          const Divider(),
          _Tile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'AI, appearance, pet profile',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const SettingsScreen(),
            )),
          ),
          _Tile(
            icon: Icons.info_outline,
            title: 'About PawPrint',
            subtitle: 'v0.1.0 · Free, no card',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'PawPrint',
              applicationVersion: '0.1.0',
              applicationLegalese:
                  'PawPrint offers general guidance only. Always consult a licensed vet for medical decisions.',
              children: [
                const SizedBox(height: 12),
                const Text(
                  'AI Pet Health Tracker. Track your pet’s health, log '
                  'photos, weight, medicine and grooming; chat with a free '
                  'OpenRouter model for guidance.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

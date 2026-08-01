import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/health_log_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/health_log_tile.dart';

class HealthLogScreen extends StatelessWidget {
  const HealthLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<HealthLogProvider>().all;
    return Scaffold(
      appBar: AppBar(title: const Text('Health log')),
      body: logs.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'No log entries yet',
              message: 'Use the Log tab to start tracking.',
            )
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (_, i) {
                final l = logs[i];
                return HealthLogTile(
                  log: l,
                  onDelete: () => context.read<HealthLogProvider>().delete(l.id),
                );
              },
            ),
    );
  }
}

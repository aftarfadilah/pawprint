import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/health_log.dart';

class HealthLogTile extends StatelessWidget {
  final HealthLog log;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  const HealthLogTile({super.key, required this.log, this.onTap, this.onDelete});

  IconData get _icon {
    switch (log.type) {
      case HealthLogType.photo:
        return Icons.photo_camera_outlined;
      case HealthLogType.weight:
        return Icons.monitor_weight_outlined;
      case HealthLogType.medicine:
        return Icons.medication_outlined;
      case HealthLogType.grooming:
        return Icons.content_cut;
      case HealthLogType.microscope:
        return Icons.biotech_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateStr = DateFormat('MMM d, h:mm a').format(log.createdAt);
    final hasImage =
        log.imageBase64 != null && log.imageBase64!.isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    log.imageBase64!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _iconFallback(scheme),
                  ),
                )
              else
                _iconFallback(scheme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    if (log.subtitle.isNotEmpty)
                      Text(log.subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(dateStr,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            )),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconFallback(ColorScheme scheme) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(_icon, color: scheme.onPrimaryContainer),
    );
  }
}

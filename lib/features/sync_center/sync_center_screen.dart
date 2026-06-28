import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/field_models.dart';
import '../../core/state/session_controller.dart';
import '../../design_system/components/section_panel.dart';
import '../../design_system/components/status_badge.dart';

class SyncCenterScreen extends ConsumerWidget {
  const SyncCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(demoRepositoryProvider).queue;
    final session = ref.watch(sessionControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionPanel(
          title: 'Sync Center',
          action: FilledButton.icon(
            onPressed: session.isOnline ? () {} : null,
            icon: const Icon(Icons.sync),
            label: const Text('Sync now'),
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.isOnline
                        ? 'Online and ready to submit queued work.'
                        : 'Offline. Queue is preserved locally.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value:
                        queue
                            .where((item) => item.status == SyncStatus.synced)
                            .length /
                        queue.length,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        for (final item in queue) _QueueRow(item: item),
      ],
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.item});

  final SyncQueueItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          minVerticalPadding: 16,
          leading: Icon(_iconFor(item.status)),
          title: Text(item.label),
          subtitle: Text(
            '${item.endpoint} • retries: ${item.retryCount}\n'
            'Updated ${DateFormat.Hm().format(item.updatedAt)}'
            '${item.error == null ? '' : ' • ${item.error}'}',
          ),
          isThreeLine: true,
          trailing: StatusBadge.sync(item.status),
        ),
      ),
    );
  }
}

IconData _iconFor(SyncStatus status) {
  return switch (status) {
    SyncStatus.pending => Icons.schedule,
    SyncStatus.syncing => Icons.sync,
    SyncStatus.synced => Icons.cloud_done_outlined,
    SyncStatus.failed => Icons.error_outline,
    SyncStatus.blocked => Icons.block,
    SyncStatus.conflict => Icons.compare_arrows,
  };
}

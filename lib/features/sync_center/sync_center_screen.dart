import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/models/field_models.dart';
import '../../core/state/app_controller.dart';
import '../../design_system/app_ui.dart';

class SyncCenterScreen extends ConsumerStatefulWidget {
  const SyncCenterScreen({super.key});

  @override
  ConsumerState<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends ConsumerState<SyncCenterScreen> {
  bool _manualSyncing = false;

  Future<void> _syncNow(AppController controller) async {
    if (_manualSyncing || controller.isSyncing) return;
    final queuedBefore = controller.outbox.length;
    final stopwatch = Stopwatch()..start();
    controller.clearError();
    setState(() => _manualSyncing = true);
    try {
      await controller.syncOutbox();
      await controller.refreshAll(silent: true);
      const minimumFeedbackTime = Duration(milliseconds: 650);
      if (stopwatch.elapsed < minimumFeedbackTime) {
        await Future<void>.delayed(minimumFeedbackTime - stopwatch.elapsed);
      }
      if (!mounted) return;
      final remaining = controller.outbox.length;
      final error = controller.errorMessage;
      final message = error != null
          ? 'Sync incomplete. $error'
          : remaining > 0
          ? 'Sync finished with $remaining record${remaining == 1 ? '' : 's'} still queued.'
          : queuedBefore > 0
          ? 'Sync complete. $queuedBefore queued record${queuedBefore == 1 ? '' : 's'} uploaded.'
          : 'Sync complete. Assignments and records are up to date.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  error == null
                      ? Icons.check_circle_outline_rounded
                      : Icons.error_outline_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
    } finally {
      stopwatch.stop();
      if (mounted) setState(() => _manualSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(appControllerProvider);
    final syncing = _manualSyncing || controller.isSyncing;
    return AppPage(
      children: [
        PageHeader(
          eyebrow: 'Offline workspace',
          title: 'Sync center',
          subtitle:
              'See what is stored on this device, retry queued records and keep assignments current.',
          actions: [
            FilledButton.icon(
              onPressed: controller.isOnline && !syncing
                  ? () => _syncNow(controller)
                  : null,
              icon: syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text(syncing ? 'Syncing...' : 'Sync now'),
            ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: syncing
              ? Padding(
                  key: const ValueKey('sync-progress'),
                  padding: const EdgeInsets.only(top: 18),
                  child: Semantics(
                    liveRegion: true,
                    label: 'Synchronizing the ICCASA field workspace',
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LinearProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          'Checking assignments and sending queued records...',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('sync-idle')),
        ),
        const SizedBox(height: 24),
        _SyncSummary(controller: controller),
        const SizedBox(height: 20),
        if (controller.errorMessage != null) ...[
          MessageBanner(
            message: controller.errorMessage!,
            warning: true,
            onDismiss: controller.clearError,
          ),
          const SizedBox(height: 18),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final queue = _QueuePanel(controller: controller);
            final drafts = _DraftPanel(controller: controller);
            if (!wide) {
              return Column(
                children: [queue, const SizedBox(height: 18), drafts],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: queue),
                const SizedBox(width: 20),
                Expanded(flex: 4, child: drafts),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SyncSummary extends StatelessWidget {
  const _SyncSummary({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: controller.isOnline
          ? AppColors.emerald.withValues(alpha: 0.1)
          : AppColors.amber.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: (controller.isOnline ? AppColors.emerald : AppColors.amber)
            .withValues(alpha: 0.4),
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final status = Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: controller.isOnline
                  ? AppColors.emerald
                  : AppColors.amber,
              child: Icon(
                controller.isOnline
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.isOnline
                        ? 'Connection available'
                        : 'Working offline',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.isOnline
                        ? 'Queued records can be sent securely to ICCASA.'
                        : 'Keep collecting. Records will remain on this device until connectivity returns.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        );
        final stats = Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _MiniStat(value: '${controller.outbox.length}', label: 'Queued'),
            _MiniStat(value: '${controller.drafts.length}', label: 'Drafts'),
            _MiniStat(
              value: controller.lastSyncedAt == null
                  ? 'Not yet'
                  : relativeTime(controller.lastSyncedAt!),
              label: 'Last sync',
            ),
          ],
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [status, const SizedBox(height: 20), stats],
          );
        }
        return Row(
          children: [
            Expanded(child: status),
            const SizedBox(width: 24),
            stats,
          ],
        );
      },
    ),
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _QueuePanel extends StatelessWidget {
  const _QueuePanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Submission queue',
          subtitle:
              '${controller.outbox.length} record${controller.outbox.length == 1 ? '' : 's'} waiting to sync',
        ),
        const SizedBox(height: 18),
        if (controller.outbox.isEmpty)
          const EmptyState(
            icon: Icons.cloud_done_outlined,
            title: 'Everything is up to date',
            message: 'There are no records waiting to sync from this device.',
          )
        else
          ...controller.outbox.map(
            (item) => _QueueItem(item: item, controller: controller),
          ),
      ],
    ),
  );
}

class _QueueItem extends StatelessWidget {
  const _QueueItem({required this.item, required this.controller});

  final OutboxItem item;
  final AppController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  (item.lastError == null
                          ? AppColors.amber
                          : Theme.of(context).colorScheme.error)
                      .withValues(alpha: 0.12),
              child: Icon(
                item.lastError == null
                    ? Icons.schedule_send_outlined
                    : Icons.error_outline_rounded,
                color: item.lastError == null
                    ? AppColors.amber
                    : Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.formName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.lastError ??
                        'Queued ${relativeTime(item.createdAt).toLowerCase()}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Queue item actions',
              onSelected: (value) async {
                if (value == 'retry') await controller.syncOutbox();
                if (value == 'discard' && context.mounted) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Discard queued record?'),
                      content: const Text(
                        'This permanently removes the unsent record from this device.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Discard'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await controller.discardOutboxItem(item.id);
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'retry',
                  child: ListTile(
                    leading: Icon(Icons.refresh_rounded),
                    title: Text('Retry sync'),
                  ),
                ),
                PopupMenuItem(
                  value: 'discard',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline_rounded),
                    title: Text('Discard'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _DraftPanel extends StatelessWidget {
  const _DraftPanel({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Local drafts',
          subtitle: '${controller.drafts.length} saved on this device',
        ),
        const SizedBox(height: 18),
        if (controller.drafts.isEmpty)
          const EmptyState(
            icon: Icons.edit_note_rounded,
            title: 'No open drafts',
            message: 'Forms you start and save will appear here.',
          )
        else
          ...controller.drafts.map(
            (draft) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                title: Text(
                  draft.formName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Saved ${relativeTime(draft.updatedAt).toLowerCase()}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    context.go('/collect/${draft.formId}?draft=${draft.id}'),
              ),
            ),
          ),
      ],
    ),
  );
}

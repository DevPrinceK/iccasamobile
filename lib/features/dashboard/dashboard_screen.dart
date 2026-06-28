import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/session_controller.dart';
import '../../design_system/components/section_panel.dart';
import '../../design_system/components/status_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(demoRepositoryProvider);
    final session = ref.watch(sessionControllerProvider);
    final assignments = repo.assignments;
    final queue = repo.queue;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _Header(agentName: session.agentName, isOnline: session.isOnline),
        const SizedBox(height: 24),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _MetricCard(
              'Assigned today',
              assignments.length.toString(),
              Icons.assignment_outlined,
            ),
            _MetricCard('In progress', '1', Icons.timelapse),
            _MetricCard('Pending sync', '2', Icons.cloud_upload_outlined),
            _MetricCard('Failed items', '1', Icons.error_outline),
          ],
        ).animate().fadeIn().slideY(begin: .05),
        const SizedBox(height: 28),
        SectionPanel(
          title: 'Continue Work',
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(Icons.edit_document, size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignments.first.personName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(assignments.first.task),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: assignments.first.progress,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  StatusBadge.assignment(assignments.first.status),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 920;
            final alerts = _AlertsPanel();
            final sync = _SyncPanel(
              failed: queue.where((item) => item.error != null).length,
              pending: queue.length,
            );
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: alerts),
                      const SizedBox(width: 18),
                      Expanded(child: sync),
                    ],
                  )
                : Column(children: [alerts, const SizedBox(height: 18), sync]);
          },
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.agentName, required this.isOnline});

  final String agentName;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good evening, $agentName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'Your field queue is saved locally and ready offline.',
              ),
            ],
          ),
        ),
        StatusBadge.text(isOnline ? 'Online' : 'Offline'),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 18),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertsPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(demoRepositoryProvider).alerts;

    return SectionPanel(
      title: 'Alerts',
      child: Column(
        children: [
          for (final alert in alerts)
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(alert.title),
                subtitle: Text(alert.body),
              ),
            ),
        ],
      ),
    );
  }
}

class _SyncPanel extends StatelessWidget {
  const _SyncPanel({required this.failed, required this.pending});

  final int failed;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Sync Health',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$pending queue items',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '$failed needs attention before the next supervisor handoff.',
              ),
              const SizedBox(height: 16),
              const LinearProgressIndicator(value: .68),
            ],
          ),
        ),
      ),
    );
  }
}
